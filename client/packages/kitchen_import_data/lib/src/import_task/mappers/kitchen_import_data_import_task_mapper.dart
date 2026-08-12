import 'dart:convert';

import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import '../database/kitchen_import_data_app_database.dart';

/// 在 Drift 行、版本化 JSON 和 Import Domain 实体之间转换。
///
/// 媒体及草稿使用 JSON 是为了让一个可恢复任务原子保存完整快照；解码逻辑必须
/// 为旧字段提供默认值，生成的 Drift `*.g.dart` 不承载这些兼容规则。
abstract final class ImportTaskMapper {
  static ImportTaskEntity toDomain(ImportTask row) {
    return ImportTaskEntity(
      id: row.id,
      inputKind: ImportInputKind.values.byName(row.inputKind),
      status: ImportTaskStatus.values.byName(row.status),
      originalText: row.originalText,
      detectedPublicUrl: row.detectedPublicUrl == null
          ? null
          : Uri.tryParse(row.detectedPublicUrl!),
      media: decodeMedia(row.mediaJson),
      ocrText: row.ocrText,
      correctedOcrText: row.correctedOcrText,
      supplementalText: row.supplementalText,
      processingGeneration: row.processingGeneration,
      draft: row.draftJson == null ? null : decodeDraft(row.draftJson!),
      errorCode: row.errorCode,
      errorMessage: row.errorMessage,
      finalRecipeId: row.finalRecipeId,
      ocrQuality: decodeOcrQuality(row.ocrQualityJson),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static String encodeMedia(List<ImportMediaReference> media) {
    return jsonEncode(
      media
          .map(
            (item) => {
              'id': item.id,
              'localPath': item.localPath,
              'originalLocalPath': item.originalLocalPath,
              'contentRevision': item.contentRevision,
              'position': item.position,
              'rotationQuarterTurns': item.rotationQuarterTurns,
              'ignored': item.ignored,
              'ocrText': item.ocrText,
              'ocrPage': item.ocrPage == null
                  ? null
                  : encodeOcrPage(item.ocrPage!),
              'ocrStatus': item.ocrStatus.name,
              'ocrErrorCode': item.ocrErrorCode,
              'ocrErrorMessage': item.ocrErrorMessage,
              'imageQuality': encodeImageQuality(item.imageQuality),
              'selectedCandidate': item.selectedCandidate.name,
              // 保留旧字段一个版本，方便已发布客户端回读新任务。
              'ocrCompleted': item.ocrCompleted,
            },
          )
          .toList(growable: false),
    );
  }

  static List<ImportMediaReference> decodeMedia(String value) {
    final items = jsonDecode(value) as List<dynamic>;
    return items
        .map((item) {
          final map = item as Map<String, dynamic>;
          return ImportMediaReference(
            id: map['id'] as String,
            localPath: map['localPath'] as String,
            originalLocalPath:
                map['originalLocalPath'] as String? ??
                map['localPath'] as String,
            contentRevision: map['contentRevision'] as int? ?? 0,
            position: map['position'] as int,
            rotationQuarterTurns: map['rotationQuarterTurns'] as int? ?? 0,
            ignored: map['ignored'] as bool? ?? false,
            ocrText: map['ocrText'] as String?,
            ocrPage: map['ocrPage'] == null
                ? null
                : decodeOcrPage(map['ocrPage'] as Map<String, dynamic>),
            ocrStatus: map['ocrStatus'] == null
                ? null
                : ImportMediaOcrStatus.values.byName(
                    map['ocrStatus'] as String,
                  ),
            ocrCompleted: map['ocrCompleted'] as bool? ?? false,
            ocrErrorCode: map['ocrErrorCode'] as String?,
            ocrErrorMessage: map['ocrErrorMessage'] as String?,
            imageQuality: map['imageQuality'] == null
                ? const ImageQualityReport()
                : decodeImageQuality(
                    map['imageQuality'] as Map<String, dynamic>,
                  ),
            selectedCandidate: _enumByName(
              OcrCandidateSelection.values,
              map['selectedCandidate'] as String?,
              OcrCandidateSelection.unknown,
            ),
          );
        })
        .toList(growable: false);
  }

  static Map<String, dynamic> encodeOcrPage(OcrPageEntity page) {
    return {
      'pageIndex': page.pageIndex,
      'pixelWidth': page.pixelWidth,
      'pixelHeight': page.pixelHeight,
      'lines': page.lines
          .map(
            (line) => {
              'id': line.id,
              'text': line.text,
              'confidence': line.confidence,
              'angleDegrees': line.angleDegrees,
              'recognizedLanguage': line.recognizedLanguage,
              'boundingBox': {
                'left': line.boundingBox.left,
                'top': line.boundingBox.top,
                'right': line.boundingBox.right,
                'bottom': line.boundingBox.bottom,
              },
            },
          )
          .toList(growable: false),
      'platformMetadata': {
        'engineIdentifier': page.platformMetadata.engineIdentifier,
        'engineVersion': page.platformMetadata.engineVersion,
        'modelBundled': page.platformMetadata.modelBundled,
      },
      'preprocessMetadata': {
        'source': page.preprocessMetadata.source.name,
        'profileIdentifier': page.preprocessMetadata.profileIdentifier,
        'profileVersion': page.preprocessMetadata.profileVersion,
        'sourceContentRevision': page.preprocessMetadata.sourceContentRevision,
      },
      'textQuality': encodeTextQuality(page.textQuality),
    };
  }

  static OcrPageEntity decodeOcrPage(Map<String, dynamic> map) {
    final lines = (map['lines'] as List<dynamic>)
        .map((value) {
          final line = value as Map<String, dynamic>;
          final box = line['boundingBox'] as Map<String, dynamic>;
          return OcrLineEntity(
            id: line['id'] as String,
            text: line['text'] as String,
            confidence: (line['confidence'] as num?)?.toDouble(),
            angleDegrees: (line['angleDegrees'] as num?)?.toDouble(),
            recognizedLanguage: line['recognizedLanguage'] as String?,
            boundingBox: OcrRectValueObject(
              left: (box['left'] as num).toDouble(),
              top: (box['top'] as num).toDouble(),
              right: (box['right'] as num).toDouble(),
              bottom: (box['bottom'] as num).toDouble(),
            ),
          );
        })
        .toList(growable: false);
    return OcrPageEntity(
      pageIndex: map['pageIndex'] as int,
      pixelWidth: map['pixelWidth'] as int? ?? 0,
      pixelHeight: map['pixelHeight'] as int? ?? 0,
      lines: lines,
      platformMetadata: _decodePlatformMetadata(
        map['platformMetadata'] as Map<String, dynamic>?,
      ),
      preprocessMetadata: _decodePreprocessMetadata(
        map['preprocessMetadata'] as Map<String, dynamic>?,
      ),
      textQuality: map['textQuality'] == null
          ? const OcrTextQualityReport()
          : decodeTextQuality(map['textQuality'] as Map<String, dynamic>),
    );
  }

  static Map<String, dynamic> encodeImageQuality(ImageQualityReport report) {
    return {
      'level': report.level.name,
      'issues': report.issues.map((issue) => issue.name).toList(),
      'recommendedAction': report.recommendedAction.name,
      'profileVersion': report.profileVersion,
      'detail': report.detail,
    };
  }

  static ImageQualityReport decodeImageQuality(Map<String, dynamic> map) {
    return ImageQualityReport(
      level: _enumByName(
        ImageQualityLevel.values,
        map['level'] as String?,
        ImageQualityLevel.unknown,
      ),
      issues: (map['issues'] as List<dynamic>? ?? const [])
          .map(
            (value) => _enumByName(
              ImageQualityIssueCode.values,
              value as String?,
              ImageQualityIssueCode.metadataLimited,
            ),
          )
          .toList(growable: false),
      recommendedAction: _enumByName(
        ImageQualityRecommendedAction.values,
        map['recommendedAction'] as String?,
        ImageQualityRecommendedAction.continueRecognition,
      ),
      profileVersion: map['profileVersion'] as String? ?? 'unknown',
      detail: map['detail'] as String?,
    );
  }

  static Map<String, dynamic> encodeTextQuality(OcrTextQualityReport report) {
    return {
      'level': report.level.name,
      'issues': report.issues.map((issue) => issue.name).toList(),
      'evidence': report.evidence
          .map(
            (item) => {
              'pageIndex': item.pageIndex,
              'issue': item.issue.name,
              'lineId': item.lineId,
              'message': item.message,
            },
          )
          .toList(growable: false),
      'profileVersion': report.profileVersion,
    };
  }

  static OcrTextQualityReport decodeTextQuality(Map<String, dynamic> map) {
    return OcrTextQualityReport(
      level: _enumByName(
        OcrTextQualityLevel.values,
        map['level'] as String?,
        OcrTextQualityLevel.unknown,
      ),
      issues: (map['issues'] as List<dynamic>? ?? const [])
          .map(
            (value) => _enumByName(
              OcrTextQualityIssueCode.values,
              value as String?,
              OcrTextQualityIssueCode.metadataLimited,
            ),
          )
          .toList(growable: false),
      evidence: (map['evidence'] as List<dynamic>? ?? const [])
          .map((value) {
            final evidence = value as Map<String, dynamic>;
            return OcrTextQualityEvidence(
              pageIndex: evidence['pageIndex'] as int? ?? 0,
              issue: _enumByName(
                OcrTextQualityIssueCode.values,
                evidence['issue'] as String?,
                OcrTextQualityIssueCode.metadataLimited,
              ),
              lineId: evidence['lineId'] as String?,
              message: evidence['message'] as String? ?? '',
            );
          })
          .toList(growable: false),
      profileVersion: map['profileVersion'] as String? ?? 'unknown',
    );
  }

  static String encodeOcrQuality(ImportOcrQualityState state) {
    return jsonEncode({
      'textQuality': encodeTextQuality(state.textQuality),
      'suggestions': state.suggestions
          .map(
            (item) => {
              'id': item.id,
              'originalText': item.originalText,
              'replacementText': item.replacementText,
              'reason': item.reason.name,
              'pageIndex': item.pageIndex,
              'lineId': item.lineId,
              'status': item.status.name,
            },
          )
          .toList(growable: false),
      'revisions': state.revisions
          .map(
            (item) => {
              'id': item.id,
              'beforeText': item.beforeText,
              'afterText': item.afterText,
              'kind': item.kind.name,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    });
  }

  static ImportOcrQualityState decodeOcrQuality(String value) {
    final map = jsonDecode(value) as Map<String, dynamic>;
    return ImportOcrQualityState(
      textQuality: map['textQuality'] == null
          ? const OcrTextQualityReport()
          : decodeTextQuality(map['textQuality'] as Map<String, dynamic>),
      suggestions: (map['suggestions'] as List<dynamic>? ?? const [])
          .map((value) {
            final item = value as Map<String, dynamic>;
            return OcrCorrectionSuggestion(
              id: item['id'] as String,
              originalText: item['originalText'] as String,
              replacementText: item['replacementText'] as String,
              reason: _enumByName(
                OcrCorrectionReason.values,
                item['reason'] as String?,
                OcrCorrectionReason.suspectedGlyphError,
              ),
              pageIndex: item['pageIndex'] as int? ?? 0,
              lineId: item['lineId'] as String?,
              status: _enumByName(
                OcrCorrectionSuggestionStatus.values,
                item['status'] as String?,
                OcrCorrectionSuggestionStatus.pending,
              ),
            );
          })
          .toList(growable: false),
      revisions: (map['revisions'] as List<dynamic>? ?? const [])
          .map((value) {
            final item = value as Map<String, dynamic>;
            return OcrCorrectionRevision(
              id: item['id'] as String,
              beforeText: item['beforeText'] as String,
              afterText: item['afterText'] as String,
              kind: _enumByName(
                OcrCorrectionRevisionKind.values,
                item['kind'] as String?,
                OcrCorrectionRevisionKind.manual,
              ),
              createdAt: DateTime.parse(item['createdAt'] as String),
            );
          })
          .toList(growable: false),
    );
  }

  static OcrPlatformMetadata _decodePlatformMetadata(
    Map<String, dynamic>? map,
  ) {
    if (map == null) return const OcrPlatformMetadata();
    return OcrPlatformMetadata(
      engineIdentifier: map['engineIdentifier'] as String? ?? 'unknown',
      engineVersion: map['engineVersion'] as String?,
      modelBundled: map['modelBundled'] as bool?,
    );
  }

  static OcrPreprocessMetadata _decodePreprocessMetadata(
    Map<String, dynamic>? map,
  ) {
    if (map == null) return const OcrPreprocessMetadata();
    return OcrPreprocessMetadata(
      source: _enumByName(
        OcrInputSource.values,
        map['source'] as String?,
        OcrInputSource.unknown,
      ),
      profileIdentifier: map['profileIdentifier'] as String? ?? 'unknown',
      profileVersion: map['profileVersion'] as String? ?? 'unknown',
      sourceContentRevision: map['sourceContentRevision'] as int? ?? 0,
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static String encodeDraft(RecipeDraftEntity draft) {
    Map<String, dynamic> field<T>(DraftFieldValue<T> value) => {
      'value': value.value,
      'origin': value.origin.name,
      'needsConfirmation': value.needsConfirmation,
      'confidence': value.confidence.name,
      'evidence': value.evidence
          .map(
            (item) => {
              'pageIndex': item.pageIndex,
              'lineId': item.lineId,
              'excerpt': item.excerpt,
            },
          )
          .toList(growable: false),
      'conflictCandidate': value.conflictCandidate,
    };
    return jsonEncode({
      'schemaVersion': draft.schemaVersion,
      'quality': draft.quality.name,
      'warnings': draft.warnings,
      'title': field(draft.title),
      'summary': field(draft.summary),
      'category': field(draft.category),
      'servings': field(draft.servings),
      'prepMinutes': field(draft.prepMinutes),
      'cookMinutes': field(draft.cookMinutes),
      'difficulty': field(draft.difficulty),
      'tags': field(draft.tags),
      'ingredients': field(draft.ingredients),
      'preparations': field(draft.preparations),
      'steps': field(draft.steps),
      'sourceSnapshot': {
        'originalText': draft.sourceSnapshot.originalText,
        'publicUrl': draft.sourceSnapshot.publicUrl?.toString(),
        'sourceTitle': draft.sourceSnapshot.sourceTitle,
      },
    });
  }

  static RecipeDraftEntity decodeDraft(String value) {
    final map = jsonDecode(value) as Map<String, dynamic>;
    DraftFieldValue<T> field<T>(String key, T Function(Object?) decode) {
      final data = map[key] as Map<String, dynamic>;
      return DraftFieldValue<T>(
        value: decode(data['value']),
        origin: DraftFieldOrigin.values.byName(data['origin'] as String),
        needsConfirmation: data['needsConfirmation'] as bool? ?? false,
        confidence: DraftConfidenceLevel.values.byName(
          data['confidence'] as String? ?? DraftConfidenceLevel.medium.name,
        ),
        evidence: (data['evidence'] as List<dynamic>? ?? const [])
            .map((value) {
              final evidence = value as Map<String, dynamic>;
              return DraftFieldEvidence(
                pageIndex: evidence['pageIndex'] as int,
                lineId: evidence['lineId'] as String,
                excerpt: evidence['excerpt'] as String,
              );
            })
            .toList(growable: false),
        conflictCandidate: data['conflictCandidate'] == null
            ? null
            : decode(data['conflictCandidate']),
      );
    }

    final source = map['sourceSnapshot'] as Map<String, dynamic>;
    // schemaVersion 1 没有 preparations 等后续字段。迁移在读取边界补默认值，
    // 不修改原始 JSON，下一次用户保存草稿时自然写成当前版本。
    return RecipeDraftEntity(
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      quality: RecipeDraftQuality.values.byName(
        map['quality'] as String? ?? RecipeDraftQuality.partial.name,
      ),
      warnings: (map['warnings'] as List<dynamic>? ?? const []).cast<String>(),
      title: field('title', (value) => value as String),
      summary: field('summary', (value) => value as String),
      category: field('category', (value) => value as String),
      servings: field('servings', (value) => value as int?),
      prepMinutes: field('prepMinutes', (value) => value as int?),
      cookMinutes: field('cookMinutes', (value) => value as int?),
      difficulty: field('difficulty', (value) => value as String),
      tags: field('tags', (value) => (value as List<dynamic>).cast<String>()),
      ingredients: field(
        'ingredients',
        (value) => (value as List<dynamic>).cast<String>(),
      ),
      preparations: map['preparations'] == null
          ? const DraftFieldValue<List<String>>(
              value: [],
              origin: DraftFieldOrigin.inferred,
              needsConfirmation: true,
              confidence: DraftConfidenceLevel.low,
            )
          : field(
              'preparations',
              (value) => (value as List<dynamic>).cast<String>(),
            ),
      steps: field('steps', (value) => (value as List<dynamic>).cast<String>()),
      sourceSnapshot: SourceSnapshot(
        originalText: source['originalText'] as String,
        publicUrl: source['publicUrl'] == null
            ? null
            : Uri.parse(source['publicUrl'] as String),
        sourceTitle: source['sourceTitle'] as String?,
      ),
    );
  }
}
