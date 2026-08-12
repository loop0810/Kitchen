import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image;
import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:path/path.dart' as p;

/// 使用纯 Dart 像素处理实现的离线 OCR 输入准备器。
class LocalOcrInputPreparerAdapter implements OcrInputPreparer {
  const LocalOcrInputPreparerAdapter({this.decoder});

  /// 测试可注入的像素解码边界；生产环境为空时从本地文件解码。
  final Future<image.Image?> Function(String path)? decoder;

  static const _orientationProfile = 'orientation-normalization';
  static const _enhancementProfile = 'conservative-text-enhancement';
  static const _profileVersion = '1';
  static const _maxLongEdge = 3200;
  static const _targetShortEdge = 1600;

  @override
  Future<OcrInputPreparation> prepare(ImportMediaReference media) async {
    final fallback = OcrInputCandidate(
      localPath: media.localPath,
      source: OcrInputSource.original,
      profileIdentifier: 'none',
      profileVersion: _profileVersion,
      sourceContentRevision: media.contentRevision,
      pixelWidth: 0,
      pixelHeight: 0,
      rotationQuarterTurns: media.rotationQuarterTurns,
    );
    image.Image? decoded;
    try {
      decoded = decoder == null
          ? image.decodeImage(await File(media.localPath).readAsBytes())
          : await decoder!(media.localPath);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return OcrInputPreparation(
        original: fallback,
        imageQuality: const ImageQualityReport(
          level: ImageQualityLevel.unknown,
          issues: [ImageQualityIssueCode.metadataLimited],
          recommendedAction: ImageQualityRecommendedAction.replace,
          profileVersion: _profileVersion,
          detail: '图片像素无法读取，已回退原图识别。',
        ),
      );
    }

    final exifNeedsBake =
        decoded.exif.imageIfd.hasOrientation &&
        decoded.exif.imageIfd.orientation != 1;
    var normalized = image.bakeOrientation(decoded);
    final turns = media.rotationQuarterTurns % 4;
    if (turns != 0) {
      normalized = image.copyRotate(normalized, angle: turns * 90);
    }
    final report = _diagnose(normalized);

    var original = OcrInputCandidate(
      localPath: media.localPath,
      source: OcrInputSource.original,
      profileIdentifier: 'none',
      profileVersion: _profileVersion,
      sourceContentRevision: media.contentRevision,
      pixelWidth: normalized.width,
      pixelHeight: normalized.height,
      rotationQuarterTurns: media.rotationQuarterTurns,
    );
    if (exifNeedsBake || turns != 0) {
      final normalizedPath = _derivedPath(
        media,
        'orientation-$_profileVersion',
      );
      if (await _writeJpeg(normalizedPath, normalized)) {
        original = OcrInputCandidate(
          localPath: normalizedPath,
          source: OcrInputSource.orientationNormalized,
          profileIdentifier: _orientationProfile,
          profileVersion: _profileVersion,
          sourceContentRevision: media.contentRevision,
          pixelWidth: normalized.width,
          pixelHeight: normalized.height,
          isDerived: true,
        );
      }
    }

    OcrInputCandidate? enhanced;
    if (_shouldEnhance(report)) {
      final enhancedImage = _enhance(normalized);
      final enhancedPath = _derivedPath(media, 'enhanced-$_profileVersion');
      if (await _writeJpeg(enhancedPath, enhancedImage)) {
        enhanced = OcrInputCandidate(
          localPath: enhancedPath,
          source: OcrInputSource.enhanced,
          profileIdentifier: _enhancementProfile,
          profileVersion: _profileVersion,
          sourceContentRevision: media.contentRevision,
          pixelWidth: enhancedImage.width,
          pixelHeight: enhancedImage.height,
          isDerived: true,
        );
      }
    }
    return OcrInputPreparation(
      original: original,
      enhanced: enhanced,
      imageQuality: report,
    );
  }

  @override
  Future<void> release(OcrInputPreparation preparation) async {
    for (final candidate in [preparation.original, preparation.enhanced]) {
      if (candidate == null || !candidate.isDerived) continue;
      try {
        final file = File(candidate.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // 清理失败不影响任务；启动期孤立文件回收会再次处理。
      }
    }
  }

  ImageQualityReport _diagnose(image.Image input) {
    final statistics = _sampleStatistics(input);
    final issues = <ImageQualityIssueCode>[];
    // 大面积白底会让全图标准差偏低；用实际亮度跨度确认低对比，避免把正常的
    // 小字号黑字和留白较多的横版截图误送进耗时增强。
    if (statistics.luminanceRange < 120) {
      issues.add(ImageQualityIssueCode.lowContrast);
    }
    if (statistics.edgeMean < 7.5 && statistics.contrastDeviation >= 27) {
      issues.add(ImageQualityIssueCode.blurred);
    }
    if (math.min(input.width, input.height) < 720) {
      issues.add(ImageQualityIssueCode.textMayBeTooSmall);
    }
    if (issues.isEmpty) {
      return const ImageQualityReport(
        level: ImageQualityLevel.acceptable,
        profileVersion: _profileVersion,
      );
    }
    final action =
        issues.contains(ImageQualityIssueCode.blurred) ||
            issues.contains(ImageQualityIssueCode.textMayBeTooSmall)
        ? ImageQualityRecommendedAction.replace
        : ImageQualityRecommendedAction.manualReview;
    return ImageQualityReport(
      level: ImageQualityLevel.needsAttention,
      issues: issues,
      recommendedAction: action,
      profileVersion: _profileVersion,
      detail: '图片清晰度、文字像素或对比度可能影响识别。',
    );
  }

  _PixelStatistics _sampleStatistics(image.Image input) {
    final step = math.max(1, math.max(input.width, input.height) ~/ 256);
    var count = 0;
    var sum = 0.0;
    var squareSum = 0.0;
    var edgeSum = 0.0;
    var minimum = 255.0;
    var maximum = 0.0;
    for (var y = step; y < input.height - step; y += step) {
      for (var x = step; x < input.width - step; x += step) {
        final center = _luminance(input.getPixel(x, y));
        final neighbors =
            _luminance(input.getPixel(x - step, y)) +
            _luminance(input.getPixel(x + step, y)) +
            _luminance(input.getPixel(x, y - step)) +
            _luminance(input.getPixel(x, y + step));
        sum += center;
        squareSum += center * center;
        edgeSum += (center * 4 - neighbors).abs();
        minimum = math.min(minimum, center);
        maximum = math.max(maximum, center);
        count += 1;
      }
    }
    if (count == 0) return const _PixelStatistics(0, 0, 0);
    final mean = sum / count;
    final variance = math.max(0, squareSum / count - mean * mean);
    return _PixelStatistics(
      math.sqrt(variance),
      edgeSum / count,
      maximum - minimum,
    );
  }

  double _luminance(image.Pixel pixel) {
    return pixel.r * 0.2126 + pixel.g * 0.7152 + pixel.b * 0.0722;
  }

  bool _shouldEnhance(ImageQualityReport report) {
    return report.issues.any(
      (issue) =>
          issue == ImageQualityIssueCode.lowContrast ||
          issue == ImageQualityIssueCode.blurred ||
          issue == ImageQualityIssueCode.textMayBeTooSmall,
    );
  }

  image.Image _enhance(image.Image normalized) {
    final longEdge = math.max(normalized.width, normalized.height);
    final shortEdge = math.min(normalized.width, normalized.height);
    var scale = 1.0;
    if (shortEdge < _targetShortEdge) {
      scale = _targetShortEdge / shortEdge;
    }
    if (longEdge * scale > _maxLongEdge) {
      scale = _maxLongEdge / longEdge;
    }
    var output = image.adjustColor(
      image.Image.from(normalized),
      saturation: 0,
      contrast: 1.16,
    );
    output = image.convolution(
      output,
      filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
      amount: 0.35,
    );
    return scale == 1
        ? output
        : image.copyResize(
            output,
            width: (normalized.width * scale).round(),
            height: (normalized.height * scale).round(),
            interpolation: image.Interpolation.linear,
          );
  }

  String _derivedPath(ImportMediaReference media, String profile) {
    return p.join(
      p.dirname(media.localPath),
      '.ocr-${media.id}-r${media.contentRevision}-$profile.jpg',
    );
  }

  Future<bool> _writeJpeg(String path, image.Image value) async {
    try {
      final temporary = File('$path.tmp');
      await temporary.writeAsBytes(image.encodeJpg(value, quality: 92));
      await temporary.rename(path);
      return true;
    } catch (_) {
      try {
        final temporary = File('$path.tmp');
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {}
      return false;
    }
  }
}

class _PixelStatistics {
  const _PixelStatistics(
    this.contrastDeviation,
    this.edgeMean,
    this.luminanceRange,
  );

  final double contrastDeviation;
  final double edgeMean;
  final double luminanceRange;
}
