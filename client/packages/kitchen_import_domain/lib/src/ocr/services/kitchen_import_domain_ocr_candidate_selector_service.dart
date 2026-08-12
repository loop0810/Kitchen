import '../entities/kitchen_import_domain_ocr_document_entity.dart';

class OcrCandidateSelectorService {
  const OcrCandidateSelectorService();

  /// 只有增强候选取得明确优势且没有新增孤立噪声时才选择增强结果。
  bool shouldSelectEnhanced({
    required OcrPageEntity original,
    required OcrPageEntity enhanced,
  }) {
    final originalScore = _score(original);
    final enhancedScore = _score(enhanced);
    final originalNoise = _isolatedNoiseCount(original);
    final enhancedNoise = _isolatedNoiseCount(enhanced);
    return enhancedScore >= originalScore + 6 &&
        enhancedNoise <= originalNoise + 1;
  }

  double _score(OcrPageEntity page) {
    final effectiveCharacters = page.lines.fold<int>(
      0,
      (sum, line) =>
          sum +
          RegExp(r'[\p{L}\p{N}]', unicode: true).allMatches(line.text).length,
    );
    final confidences = page.lines
        .map((line) => line.confidence)
        .whereType<double>()
        .toList(growable: false);
    final confidenceScore = confidences.isEmpty
        ? 0
        : confidences.reduce((left, right) => left + right) /
              confidences.length *
              30;
    final recipeCoverage = page.lines
        .where(
          (line) => RegExp(
            r'(?:食材|用料|材料|配料|步骤|步驟|做法|流程|克|毫升|適量|适量)',
          ).hasMatch(line.text),
        )
        .length;
    final replacementCharacters = page.lines.fold<int>(
      0,
      (sum, line) => sum + RegExp(r'[�□]').allMatches(line.text).length,
    );
    return effectiveCharacters +
        page.lines.length * 4 +
        confidenceScore +
        recipeCoverage * 12 -
        replacementCharacters * 20 -
        _isolatedNoiseCount(page) * 5;
  }

  int _isolatedNoiseCount(OcrPageEntity page) {
    return page.lines.where((line) {
      final text = line.text.trim();
      return text.length <= 1 &&
          !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text);
    }).length;
  }
}
