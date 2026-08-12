import '../entities/kitchen_import_domain_ocr_document_entity.dart';
import '../entities/kitchen_import_domain_ocr_quality_entity.dart';

class OcrCorrectionSuggestionService {
  const OcrCorrectionSuggestionService();

  List<OcrCorrectionSuggestion> generate(OcrDocumentEntity document) {
    final suggestions = <OcrCorrectionSuggestion>[];
    for (final page in document.pages) {
      for (final line in page.lines) {
        final numberMatch = RegExp(
          r'(?<=\d)[Oo](?=\s*(?:克|g|毫升|ml|分钟|分鐘))',
          caseSensitive: false,
        ).firstMatch(line.text);
        if (numberMatch != null) {
          suggestions.add(
            _suggestion(
              page: page,
              line: line,
              original: line.text.substring(numberMatch.start, numberMatch.end),
              replacement: '0',
              reason: OcrCorrectionReason.number,
              index: suggestions.length,
            ),
          );
        }
        final unitMatch = RegExp(r'(?<=\d)(?:毫开|公厅)').firstMatch(line.text);
        if (unitMatch != null) {
          final original = line.text.substring(unitMatch.start, unitMatch.end);
          suggestions.add(
            _suggestion(
              page: page,
              line: line,
              original: original,
              replacement: original == '毫开' ? '毫升' : '公斤',
              reason: OcrCorrectionReason.amountUnit,
              index: suggestions.length,
            ),
          );
        }
        const recipeTerms = {'食村': '食材', '步聚': '步骤', '配科': '配料'};
        for (final entry in recipeTerms.entries) {
          if (!line.text.contains(entry.key)) continue;
          suggestions.add(
            _suggestion(
              page: page,
              line: line,
              original: entry.key,
              replacement: entry.value,
              reason: OcrCorrectionReason.recipeTerm,
              index: suggestions.length,
            ),
          );
        }
        const glyphTerms = {'馬鈴著': '馬鈴薯', '马铃著': '马铃薯', '雞旦': '雞蛋', '鸡旦': '鸡蛋'};
        for (final entry in glyphTerms.entries) {
          if (!line.text.contains(entry.key)) continue;
          suggestions.add(
            _suggestion(
              page: page,
              line: line,
              original: entry.key,
              replacement: entry.value,
              reason: OcrCorrectionReason.suspectedGlyphError,
              index: suggestions.length,
            ),
          );
        }
      }
    }
    return suggestions;
  }

  OcrCorrectionSuggestion _suggestion({
    required OcrPageEntity page,
    required OcrLineEntity line,
    required String original,
    required String replacement,
    required OcrCorrectionReason reason,
    required int index,
  }) {
    return OcrCorrectionSuggestion(
      id: 'p${page.pageIndex}-${line.id}-$index',
      originalText: original,
      replacementText: replacement,
      reason: reason,
      pageIndex: page.pageIndex,
      lineId: line.id,
    );
  }
}
