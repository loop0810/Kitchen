import 'dart:convert';

import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import '../database/kitchen_import_data_app_database.dart';

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
      draft: row.draftJson == null ? null : decodeDraft(row.draftJson!),
      errorCode: row.errorCode,
      errorMessage: row.errorMessage,
      finalRecipeId: row.finalRecipeId,
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
              'position': item.position,
              'rotationQuarterTurns': item.rotationQuarterTurns,
              'ignored': item.ignored,
              'ocrText': item.ocrText,
              'ocrPage': item.ocrPage == null
                  ? null
                  : encodeOcrPage(item.ocrPage!),
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
            position: map['position'] as int,
            rotationQuarterTurns: map['rotationQuarterTurns'] as int? ?? 0,
            ignored: map['ignored'] as bool? ?? false,
            ocrText: map['ocrText'] as String?,
            ocrPage: map['ocrPage'] == null
                ? null
                : decodeOcrPage(map['ocrPage'] as Map<String, dynamic>),
            ocrCompleted: map['ocrCompleted'] as bool? ?? false,
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
              'boundingBox': {
                'left': line.boundingBox.left,
                'top': line.boundingBox.top,
                'right': line.boundingBox.right,
                'bottom': line.boundingBox.bottom,
              },
            },
          )
          .toList(growable: false),
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
    );
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
      );
    }

    final source = map['sourceSnapshot'] as Map<String, dynamic>;
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
