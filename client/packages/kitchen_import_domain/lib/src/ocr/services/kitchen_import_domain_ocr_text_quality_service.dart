import '../entities/kitchen_import_domain_ocr_document_entity.dart';
import '../entities/kitchen_import_domain_ocr_quality_entity.dart';

class OcrTextQualityService {
  const OcrTextQualityService();

  static const profileVersion = '1';

  OcrTextQualityReport assessPage(OcrPageEntity page) {
    final issues = <OcrTextQualityIssueCode>{};
    final evidence = <OcrTextQualityEvidence>[];
    final effectiveLines = page.lines
        .where((line) => _effectiveCharacterCount(line.text) >= 2)
        .toList(growable: false);
    if (effectiveLines.isEmpty) {
      issues.add(OcrTextQualityIssueCode.noEffectiveText);
      evidence.add(
        OcrTextQualityEvidence(
          pageIndex: page.pageIndex,
          issue: OcrTextQualityIssueCode.noEffectiveText,
          message: '这一页没有识别到可用正文。',
        ),
      );
    }
    for (final line in page.lines) {
      if (RegExp(r'[�□\uE000-\uF8FF]').hasMatch(line.text)) {
        issues.add(OcrTextQualityIssueCode.garbledText);
        evidence.add(
          OcrTextQualityEvidence(
            pageIndex: page.pageIndex,
            lineId: line.id,
            issue: OcrTextQualityIssueCode.garbledText,
            message: '这一行包含无法可靠识别的字符，请对照原图校对。',
          ),
        );
      }
      final confidence = line.confidence;
      if (confidence != null &&
          confidence < 0.45 &&
          _looksImportant(line.text)) {
        issues.add(OcrTextQualityIssueCode.lowConfidenceKeyText);
        evidence.add(
          OcrTextQualityEvidence(
            pageIndex: page.pageIndex,
            lineId: line.id,
            issue: OcrTextQualityIssueCode.lowConfidenceKeyText,
            message: '菜名、食材或步骤关键行可能识别不准。',
          ),
        );
      }
    }
    final isolated = page.lines
        .where(
          (line) =>
              line.text.trim().length <= 1 &&
              _effectiveCharacterCount(line.text) == 0,
        )
        .length;
    if (isolated >= 2 && isolated * 3 >= page.lines.length) {
      issues.add(OcrTextQualityIssueCode.excessNoise);
      evidence.add(
        OcrTextQualityEvidence(
          pageIndex: page.pageIndex,
          issue: OcrTextQualityIssueCode.excessNoise,
          message: '这一页混入较多零散界面或装饰字符。',
        ),
      );
    }
    if (page.lines.any((line) => line.confidence == null)) {
      issues.add(OcrTextQualityIssueCode.metadataLimited);
    }
    final level = issues.contains(OcrTextQualityIssueCode.noEffectiveText)
        ? OcrTextQualityLevel.insufficient
        : issues.any(
            (issue) => issue != OcrTextQualityIssueCode.metadataLimited,
          )
        ? OcrTextQualityLevel.needsAttention
        : OcrTextQualityLevel.usable;
    return OcrTextQualityReport(
      level: level,
      issues: issues.toList(growable: false),
      evidence: evidence.take(8).toList(growable: false),
      profileVersion: profileVersion,
    );
  }

  OcrTextQualityReport assessDocument(OcrDocumentEntity document) {
    if (document.pages.isEmpty) {
      return const OcrTextQualityReport(
        level: OcrTextQualityLevel.insufficient,
        issues: [OcrTextQualityIssueCode.noEffectiveText],
        profileVersion: profileVersion,
      );
    }
    final reports = document.pages.map(assessPage).toList(growable: false);
    final issues = reports.expand((report) => report.issues).toSet();
    final evidence = reports
        .expand((report) => report.evidence)
        .take(16)
        .toList(growable: false);
    final level =
        reports.every(
          (report) => report.level == OcrTextQualityLevel.insufficient,
        )
        ? OcrTextQualityLevel.insufficient
        : reports.any(
            (report) =>
                report.level == OcrTextQualityLevel.needsAttention ||
                report.level == OcrTextQualityLevel.insufficient,
          )
        ? OcrTextQualityLevel.needsAttention
        : OcrTextQualityLevel.usable;
    return OcrTextQualityReport(
      level: level,
      issues: issues.toList(growable: false),
      evidence: evidence,
      profileVersion: profileVersion,
    );
  }

  int _effectiveCharacterCount(String value) {
    return RegExp(r'[\p{L}\p{N}]', unicode: true).allMatches(value).length;
  }

  bool _looksImportant(String value) {
    return RegExp(
      r'(?:食材|用料|材料|配料|步骤|步驟|做法|流程|克|毫升|适量|適量|菜名|标题|標題|\d)',
    ).hasMatch(value);
  }
}
