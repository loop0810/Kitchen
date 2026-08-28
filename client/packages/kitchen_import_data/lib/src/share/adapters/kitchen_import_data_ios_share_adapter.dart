import 'dart:io';

import 'package:flutter/services.dart';

/// iOS 分享扩展暂存的一次分享载荷。
final class IosSharedImportPayload {
  IosSharedImportPayload({
    required this.version,
    required this.id,
    required this.status,
    required this.mimeType,
    required this.title,
    required this.subject,
    required this.text,
    required this.localPaths,
    required this.createdAt,
  });

  /// 原生清单版本，用于未来兼容字段迁移。
  final int version;

  /// 一次系统分享的稳定 ID，也是 App Group 暂存目录名。
  final String id;

  /// 暂存状态；只有 ready 状态可以交给主 App 创建导入任务。
  final String status;

  /// 分享方声明的 UTI 或 MIME 类型；未提供时为空字符串。
  final String mimeType;

  /// 分享方提供的来源标题；未提供时为空字符串。
  final String title;

  /// 分享方提供的主题；未提供时为空字符串。
  final String subject;

  /// 分享方提供的原始文字；纯图片分享时允许为空字符串。
  final String text;

  /// 已复制到 App Group 暂存区的媒体路径，保持分享顺序。
  final List<String> localPaths;

  /// 原生层完成暂存的时间。
  final DateTime createdAt;

  factory IosSharedImportPayload.fromMap(Map<Object?, Object?> map) {
    final version = map['version'];
    final id = map['id'];
    final createdAt = map['createdAtEpochMilliseconds'];
    if (version is! int || id is! String || id.trim().isEmpty) {
      throw const FormatException('iOS 分享清单缺少版本或稳定 ID。');
    }
    if (createdAt is! int) {
      throw const FormatException('iOS 分享清单缺少创建时间。');
    }

    final rawFiles = map['files'];
    final paths = <String>[];
    if (rawFiles is List) {
      for (final rawFile in rawFiles) {
        final path = rawFile is String
            ? rawFile
            : rawFile is Map
            ? rawFile['path']
            : null;
        if (path is String && path.trim().isNotEmpty) {
          paths.add(path);
        }
      }
    }

    return IosSharedImportPayload(
      version: version,
      id: id,
      status: map['status'] as String? ?? 'ready',
      mimeType: map['mimeType'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      text: map['text'] as String? ?? '',
      localPaths: List.unmodifiable(paths),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }

  /// 分享扩展生成的路径必须位于 App Group 暂存目录内，避免主 App 误读任意路径。
  bool hasSafePaths(String stagingRoot) {
    try {
      final root = _canonicalize(stagingRoot);
      return localPaths.every((path) {
        final candidate = _canonicalize(path);
        return candidate.startsWith('$root${Platform.pathSeparator}') &&
            File(candidate).existsSync();
      });
    } on FileSystemException {
      return false;
    }
  }

  String get combinedText {
    // 标题、主题和正文在原生边界合并成一次任务的 originalText；URL 仍会被
    // Repository 单独检测并保存，方便网页提取和草稿来源回溯。
    return <String>[
      title.trim(),
      subject.trim(),
      text.trim(),
    ].where((part) => part.isNotEmpty).toSet().join('\n');
  }

  static String _canonicalize(String path) =>
      File(path).resolveSymbolicLinksSync();
}

/// 主 App 读取和确认 iOS Share Extension 暂存清单的原生适配器。
final class IosShareAdapter {
  IosShareAdapter([
    this._channel = const MethodChannel('kitchen_notes/import_share_ios'),
  ]);

  final MethodChannel _channel;

  void setOnShareAvailable(Future<void> Function()? callback) {
    if (!Platform.isIOS) return;
    if (callback == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shareAvailable') await callback();
    });
  }

  Future<List<IosSharedImportPayload>> listPendingShares() async {
    if (!Platform.isIOS) return const [];
    final values =
        await _channel.invokeListMethod<Object?>('listPendingShares') ??
        const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(IosSharedImportPayload.fromMap)
        .where((payload) => payload.status == 'ready')
        .toList(growable: false);
  }

  Future<void> acknowledge(String id) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('acknowledgeShare', {'id': id});
  }

  Future<void> purgeExpiredFailedShares() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('purgeExpiredFailedShares');
  }
}
