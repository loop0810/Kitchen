import 'kitchen_import_domain_ocr_document_entity.dart';

class OcrLayoutAnalysis {
  const OcrLayoutAnalysis({
    required this.normalizedText,
    required this.visibleLines,
    required this.removedChromeLineIds,
  });

  /// 根据坐标恢复行列关系后的文本，供本地结构化器消费。
  final String normalizedText;

  /// 参与结构化的 OCR 文字行，供字段证据回溯。
  final List<({int pageIndex, OcrLineEntity line})> visibleLines;

  /// 被判定为跨页固定框架的文字行 ID。
  final Set<String> removedChromeLineIds;
}

class OcrLayoutAnalyzerService {
  const OcrLayoutAnalyzerService();

  OcrLayoutAnalysis analyze(OcrDocumentEntity document) {
    final repeatedEdgeKeys = _repeatedEdgeKeys(document);
    final removed = <String>{};
    final visible = <({int pageIndex, OcrLineEntity line})>[];
    final pageTexts = <String>[];

    for (final page in document.pages) {
      final lines = page.lines
          .where((line) {
            final key = _edgeKey(line);
            final isChrome = key != null && repeatedEdgeKeys.contains(key);
            if (isChrome) removed.add(line.id);
            return !isChrome && line.text.trim().isNotEmpty;
          })
          .toList(growable: false);
      for (final line in lines) {
        visible.add((pageIndex: page.pageIndex, line: line));
      }
      pageTexts.add(_rows(lines).join('\n'));
    }

    return OcrLayoutAnalysis(
      normalizedText: pageTexts
          .where((text) => text.trim().isNotEmpty)
          .join('\n\n'),
      visibleLines: visible,
      removedChromeLineIds: removed,
    );
  }

  Set<String> _repeatedEdgeKeys(OcrDocumentEntity document) {
    final pagesByKey = <String, Set<int>>{};
    for (final page in document.pages) {
      for (final line in page.lines) {
        final key = _edgeKey(line);
        if (key != null) {
          pagesByKey.putIfAbsent(key, () => <int>{}).add(page.pageIndex);
        }
      }
    }
    return pagesByKey.entries
        .where((entry) => entry.value.length >= 2)
        .map((entry) => entry.key)
        .toSet();
  }

  String? _edgeKey(OcrLineEntity line) {
    final box = line.boundingBox;
    // 只在真正贴近图片边缘的位置做跨页重复过滤，避免把每页重复出现的菜名、
    // 食材分区标题等业务文字误删。
    final zone = box.centerY <= 0.08
        ? 'top'
        : box.centerY >= 0.92
        ? 'bottom'
        : null;
    if (zone == null) return null;
    final normalized = line.text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (normalized.isEmpty) return null;
    return '$zone:$normalized';
  }

  List<String> _rows(List<OcrLineEntity> lines) {
    final ordered = lines.toList(growable: false)
      ..sort((left, right) {
        final vertical = left.boundingBox.centerY.compareTo(
          right.boundingBox.centerY,
        );
        return vertical != 0
            ? vertical
            : left.boundingBox.left.compareTo(right.boundingBox.left);
      });
    final rows = <List<OcrLineEntity>>[];
    for (final line in ordered) {
      final matching = rows.cast<List<OcrLineEntity>?>().firstWhere(
        (row) =>
            row!.any((item) => _sameRow(item.boundingBox, line.boundingBox)),
        orElse: () => null,
      );
      if (matching == null) {
        rows.add([line]);
      } else {
        matching.add(line);
      }
    }
    return rows
        .expand(_rowTexts)
        .where((row) => row.isNotEmpty)
        .toList(growable: false);
  }

  Iterable<String> _rowTexts(List<OcrLineEntity> row) sync* {
    row.sort(
      (left, right) => left.boundingBox.left.compareTo(right.boundingBox.left),
    );
    final texts = row
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    final section = texts.where(
      (text) => RegExp(r'^(?:食材|用料|材料|配料)$').hasMatch(text),
    );
    if (section.isNotEmpty) {
      yield section.first;
      return;
    }
    if (texts.length == 2) {
      final leftAmount = _amountOnly.hasMatch(texts.first);
      final rightAmount = _amountOnly.hasMatch(texts.last);
      if (leftAmount != rightAmount) {
        yield texts.join('  ');
        return;
      }
    }
    // 拼接图中不同面板经常恰好处于同一纵坐标。除明确的名称-用量配对外，
    // 保持为独立逻辑行，避免把两个面板的内容合成一条错误语句。
    yield* texts;
  }

  static final _amountOnly = RegExp(
    r'^(?:(?:\d+(?:\.\d+)?|[一二两三四五六七八九十半]+)\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张)|适量|少许)(?:[（(].*[）)])?$',
    caseSensitive: false,
  );

  bool _sameRow(OcrRectValueObject left, OcrRectValueObject right) {
    final overlap =
        (left.bottom < right.bottom ? left.bottom : right.bottom) -
        (left.top > right.top ? left.top : right.top);
    final minimumHeight = left.height < right.height
        ? left.height
        : right.height;
    return overlap > 0 && overlap / minimumHeight >= 0.45;
  }
}
