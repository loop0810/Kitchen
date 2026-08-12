import '../entities/kitchen_import_domain_ocr_document_entity.dart';

class OcrLayoutAnalysis {
  const OcrLayoutAnalysis({
    required this.normalizedText,
    required this.visibleLines,
    required this.removedChromeLineIds,
    required this.removedDuplicateLineIds,
    required this.possibleMultipleRecipes,
  });

  /// 根据坐标恢复行列关系后的文本，供本地结构化器消费。
  final String normalizedText;

  /// 参与结构化的 OCR 文字行，供字段证据回溯。
  final List<({int pageIndex, OcrLineEntity line})> visibleLines;

  /// 被判定为跨页固定框架的文字行 ID。
  final Set<String> removedChromeLineIds;

  /// 与前面页面重复、被去重的正文行 ID；用于诊断和来源追踪。
  final Set<String> removedDuplicateLineIds;

  /// 同一页是否重复出现完整分区，提示可能包含多道菜或重复拼图。
  final bool possibleMultipleRecipes;
}

class OcrLayoutAnalyzerService {
  const OcrLayoutAnalyzerService();

  static final _singlePageChrome = RegExp(
    r'^(?:\d{1,2}:\d{2}.*(?:[345]G|Wi-?Fi|%|％)|(?=.*关注)(?=.*收藏)(?=.*评论)(?=.*分享).+|(?:相关推荐|更多推荐|猜你喜欢).*(?:说点什么|查看更多).*)$',
    caseSensitive: false,
  );

  OcrLayoutAnalysis analyze(OcrDocumentEntity document) {
    final repeatedEdgeKeys = _repeatedEdgeKeys(document);
    final removed = <String>{};
    final removedDuplicates = <String>{};
    final seenContentKeys = <String>{};
    final visible = <({int pageIndex, OcrLineEntity line})>[];
    final pageTexts = <String>[];
    var possibleMultipleRecipes = false;

    for (final page in document.pages) {
      final pageContentKeys = <String>{};
      final lines = page.lines
          .where((line) {
            final text = line.text.trim();
            if (text.isEmpty || _isLikelyNoise(line)) return false;
            final key = _edgeKey(line);
            final isChrome = key != null && repeatedEdgeKeys.contains(key);
            if (isChrome) removed.add(line.id);
            if (isChrome) return false;

            // 多图截图常有首尾重叠页或同一张图被重复选择。只对跨页的、
            // 有足够正文长度的精确重复行去重；分区标题保留，避免破坏版面结构。
            final contentKey = _contentKey(text);
            if (contentKey != null && seenContentKeys.contains(contentKey)) {
              removedDuplicates.add(line.id);
              return false;
            }
            if (contentKey != null) pageContentKeys.add(contentKey);
            return true;
          })
          .toList(growable: false);
      seenContentKeys.addAll(pageContentKeys);
      for (final line in lines) {
        visible.add((pageIndex: page.pageIndex, line: line));
      }
      final ingredientHeadingCount = lines
          .where((line) => _headingKind(line.text) == _SectionKind.ingredient)
          .length;
      final stepHeadingCount = lines
          .where((line) => _headingKind(line.text) == _SectionKind.step)
          .length;
      if (ingredientHeadingCount >= 2 && stepHeadingCount >= 2) {
        possibleMultipleRecipes = true;
      }
      pageTexts.add(_pageText(lines));
    }

    return OcrLayoutAnalysis(
      normalizedText: pageTexts
          .where((text) => text.trim().isNotEmpty)
          .join('\n\n'),
      visibleLines: visible,
      removedChromeLineIds: removed,
      removedDuplicateLineIds: removedDuplicates,
      possibleMultipleRecipes: possibleMultipleRecipes,
    );
  }

  String? _contentKey(String value) {
    if (_headingKind(value) != null) return null;
    final normalized = value
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[“”「」『』‘’。，、：:；;！!？?（）()【】\[\]{}]'), '')
        .toLowerCase();
    if (normalized.length < 4 ||
        RegExp(r'^\d+$').hasMatch(normalized) ||
        !_hasLetterOrNumber(normalized)) {
      return null;
    }
    return normalized;
  }

  bool _isLikelyNoise(OcrLineEntity line) {
    final text = line.text.trim();
    if (text.isEmpty || !_hasLetterOrNumber(text)) return true;
    // 单页无法依赖跨页重复判断，只有同时带网络/电量特征、完整社交动作组或
    // 明确推荐交互词的行才视为界面框架，避免按具体内容平台做模板匹配。
    if (_singlePageChrome.hasMatch(text.replaceAll(RegExp(r'\s+'), ''))) {
      return true;
    }
    if (line.confidence != null &&
        line.confidence! <= 0.45 &&
        (text.length <= 3 || RegExp(r'^[A-Za-z]{1,8}$').hasMatch(text))) {
      return true;
    }
    return false;
  }

  bool _hasLetterOrNumber(String value) =>
      RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(value);

  String _pageText(List<OcrLineEntity> lines) {
    if (lines.isEmpty) return '';
    final twoColumn = _twoColumnSectionText(lines);
    if (twoColumn != null) return twoColumn;

    final headings =
        lines
            .where((line) => _headingKind(line.text) != null)
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.boundingBox.top.compareTo(right.boundingBox.top),
          );
    if (headings.isEmpty) return _rows(lines).join('\n');

    final result = <String>[];
    final firstHeadingTop = headings.first.boundingBox.top;
    result.addAll(
      _rows(
        lines
            .where((line) => line.boundingBox.bottom <= firstHeadingTop)
            .toList(growable: false),
      ),
    );
    for (final (index, heading) in headings.indexed) {
      final kind = _headingKind(heading.text)!;
      if (kind == _SectionKind.tip) {
        result.add(heading.text.trim());
        break;
      }
      final nextTop = index + 1 < headings.length
          ? headings[index + 1].boundingBox.top
          : 1.0;
      final region = lines
          .where(
            (line) =>
                !identical(line, heading) &&
                line.boundingBox.centerY > heading.boundingBox.bottom &&
                line.boundingBox.centerY < nextTop &&
                _headingKind(line.text) == null,
          )
          .toList(growable: false);
      switch (kind) {
        case _SectionKind.ingredient:
          result
            ..add('食材')
            ..addAll(_ingredientRegionTexts(region));
        case _SectionKind.step:
          result
            ..add('步骤')
            ..addAll(_stepRegionTexts(region));
        case _SectionKind.tip:
          break;
      }
    }
    return result.where((text) => text.trim().isNotEmpty).join('\n');
  }

  String? _twoColumnSectionText(List<OcrLineEntity> lines) {
    final ingredientHeadings = lines
        .where((line) => _headingKind(line.text) == _SectionKind.ingredient)
        .toList(growable: false);
    final stepHeadings = lines
        .where((line) => _headingKind(line.text) == _SectionKind.step)
        .toList(growable: false);
    for (final ingredientHeading in ingredientHeadings) {
      for (final stepHeading in stepHeadings) {
        if (!_sameRow(ingredientHeading.boundingBox, stepHeading.boundingBox)) {
          continue;
        }
        final leftHeading =
            ingredientHeading.boundingBox.centerX <
                stepHeading.boundingBox.centerX
            ? ingredientHeading
            : stepHeading;
        // 只有“左食材、右步骤”才按双栏重排；反向布局保留普通坐标顺序，
        // 避免在没有可靠语义边界时自行交换用户内容。
        if (!identical(leftHeading, ingredientHeading)) continue;
        final boundary =
            (ingredientHeading.boundingBox.right +
                stepHeading.boundingBox.left) /
            2;
        final headingBottom =
            ingredientHeading.boundingBox.bottom >
                stepHeading.boundingBox.bottom
            ? ingredientHeading.boundingBox.bottom
            : stepHeading.boundingBox.bottom;
        final preface = lines
            .where((line) => line.boundingBox.bottom <= headingBottom)
            .where(
              (line) =>
                  !identical(line, ingredientHeading) &&
                  !identical(line, stepHeading),
            )
            .toList(growable: false);
        final after =
            lines
                .where((line) => line.boundingBox.top > headingBottom)
                .toList(growable: false)
              ..sort(
                (left, right) =>
                    left.boundingBox.top.compareTo(right.boundingBox.top),
              );
        final left = <OcrLineEntity>[];
        final right = <OcrLineEntity>[];
        OcrLineEntity? footer;
        var hasLeftContent = false;
        var hasRightContent = false;
        for (final line in after) {
          final kind = _headingKind(line.text);
          final spansBothColumns =
              line.boundingBox.left < boundary - 0.12 &&
              line.boundingBox.right > boundary + 0.12;
          if (kind == _SectionKind.tip ||
              (spansBothColumns && hasLeftContent && hasRightContent)) {
            footer = line;
            break;
          }
          if (line.boundingBox.centerX < boundary) {
            left.add(line);
            hasLeftContent = true;
          } else {
            right.add(line);
            hasRightContent = true;
          }
        }
        return [
          ..._rows(preface),
          '食材',
          ..._ingredientRegionTexts(left),
          '步骤',
          ..._stepRegionTexts(right),
          if (footer != null && _headingKind(footer.text) == _SectionKind.tip)
            footer.text.trim(),
        ].where((text) => text.trim().isNotEmpty).join('\n');
      }
    }
    return null;
  }

  List<String> _ingredientRegionTexts(List<OcrLineEntity> lines) {
    final amounts = lines
        .where((line) => _amountOnly.hasMatch(_normalizedAmount(line.text)))
        .toList(growable: false);
    final names = lines
        .where((line) => !_amountOnly.hasMatch(_normalizedAmount(line.text)))
        .toList(growable: false);
    final usedNames = <String>{};
    final usedAmounts = <String>{};
    final paired = <({double top, double left, String text})>[];
    for (final amount in amounts) {
      OcrLineEntity? best;
      var bestScore = double.infinity;
      for (final name in names) {
        if (usedNames.contains(name.id)) continue;
        final sameRow = _sameRow(name.boundingBox, amount.boundingBox);
        final verticalGap = amount.boundingBox.top - name.boundingBox.bottom;
        final alignedCard =
            verticalGap >= -0.01 &&
            verticalGap <= 0.12 &&
            (name.boundingBox.centerX - amount.boundingBox.centerX).abs() <=
                0.12;
        if (!sameRow && !alignedCard) continue;
        final score = sameRow
            ? (name.boundingBox.centerY - amount.boundingBox.centerY).abs()
            : verticalGap * 2 +
                  (name.boundingBox.centerX - amount.boundingBox.centerX).abs();
        if (score < bestScore) {
          best = name;
          bestScore = score;
        }
      }
      if (best == null) continue;
      usedNames.add(best.id);
      usedAmounts.add(amount.id);
      paired.add((
        top: best.boundingBox.top,
        left: best.boundingBox.left,
        text: '${best.text.trim()}  ${_normalizedAmount(amount.text)}',
      ));
    }
    final remaining = lines
        .where(
          (line) =>
              !usedNames.contains(line.id) && !usedAmounts.contains(line.id),
        )
        .map(
          (line) => (
            top: line.boundingBox.top,
            left: line.boundingBox.left,
            text: line.text.trim(),
          ),
        );
    final values = [...paired, ...remaining]
      ..sort((left, right) {
        final vertical = left.top.compareTo(right.top);
        return vertical != 0 ? vertical : left.left.compareTo(right.left);
      });
    return values.map((value) => value.text).toList(growable: false);
  }

  List<String> _stepRegionTexts(List<OcrLineEntity> lines) {
    final rawContent = lines
        .where((line) => _headingKind(line.text) == null)
        .where((line) => !_isLikelyChrome(line.text))
        .where(
          (line) =>
              !(line.confidence != null &&
                  line.confidence! <= 0.35 &&
                  RegExp(r'^[A-Za-z]{1,8}$').hasMatch(line.text.trim())),
        )
        .toList(growable: false);
    final content = rawContent.toList(growable: false);
    if (content.length < 3) return _rows(content);

    final panelContent = content
        .where((line) => !_standaloneNumber.hasMatch(line.text.trim()))
        .toList(growable: false);
    final clusterSeed = lines
        .where((line) => _headingKind(line.text) == null)
        .where((line) => !_standaloneNumber.hasMatch(line.text.trim()))
        .toList(growable: false);

    final clusters = <List<OcrLineEntity>>[];
    for (final line
        in (clusterSeed.toList(growable: false)..sort(
          (left, right) =>
              left.boundingBox.centerX.compareTo(right.boundingBox.centerX),
        ))) {
      final matching = clusters.cast<List<OcrLineEntity>?>().firstWhere((
        cluster,
      ) {
        final center =
            cluster!
                .map((item) => item.boundingBox.centerX)
                .reduce((left, right) => left + right) /
            cluster.length;
        return (center - line.boundingBox.centerX).abs() <= 0.16;
      }, orElse: () => null);
      if (matching == null) {
        clusters.add([line]);
      } else {
        matching.add(line);
      }
    }
    final narrowPanels = clusterSeed.every(
      (line) => line.boundingBox.right - line.boundingBox.left <= 0.42,
    );
    if (clusters.length < 3 || !narrowPanels) return _rows(content);
    clusters.sort(
      (left, right) => left.first.boundingBox.centerX.compareTo(
        right.first.boundingBox.centerX,
      ),
    );

    final bands = <List<OcrLineEntity>>[];
    for (final line
        in (panelContent.toList(growable: false)..sort(
          (left, right) =>
              left.boundingBox.top.compareTo(right.boundingBox.top),
        ))) {
      if (bands.isEmpty) {
        bands.add([line]);
        continue;
      }
      final current = bands.last;
      final bottom = current
          .map((item) => item.boundingBox.bottom)
          .reduce((left, right) => left > right ? left : right);
      if (line.boundingBox.top - bottom > 0.055) {
        bands.add([line]);
      } else {
        current.add(line);
      }
    }

    final result = <String>[];
    var sequence = 1;
    for (final band in bands) {
      for (final cluster in clusters) {
        final ids = cluster.map((line) => line.id).toSet();
        final panelLines =
            band.where((line) => ids.contains(line.id)).toList(growable: false)
              ..sort((left, right) {
                final vertical = left.boundingBox.top.compareTo(
                  right.boundingBox.top,
                );
                return vertical != 0
                    ? vertical
                    : left.boundingBox.left.compareTo(right.boundingBox.left);
              });
        if (panelLines.isEmpty) continue;
        result.add(
          '$sequence ${panelLines.map((line) => line.text.trim()).join()}',
        );
        sequence++;
      }
    }
    return result;
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

  static final _standaloneNumber = RegExp(
    r'^(?:[1-9]|1\d|20|[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳])$',
  );

  _SectionKind? _headingKind(String value) {
    var normalized = value
        .replaceAll(RegExp(r'[\s\uFE0F]+'), '')
        .replaceAll(RegExp(r'[【】\[\]🍳⚠️🔍]'), '');
    final noisyPrefix = RegExp(
      r'^.{1,2}((?:制作步骤|做法步骤|烹饪步骤|操作步骤|小贴士|注意事项)(?:[:：].*)?)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (noisyPrefix != null) normalized = noisyPrefix.group(1)!;
    if (RegExp(
      r'^(?:(?:食材|用料|材料|配料)(?:清单|准备)?|准备食材)(?:（[^）]*份）|\([^)]*份\))?[:：]?$',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return _SectionKind.ingredient;
    }
    if (RegExp(
      r'^(?:步骤|流程|做法|制作方法|制作步骤|做法步骤|烹饪步骤|操作步骤)(?:\d+|[一二三四五六七八九十了])?[:：]?$',
    ).hasMatch(normalized)) {
      return _SectionKind.step;
    }
    if (RegExp(
      r'^(?:tips?|小贴士|注意事项)[:：]?.*$',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return _SectionKind.tip;
    }
    return null;
  }

  String _normalizedAmount(String value) {
    return value.trim().replaceAllMapped(
      RegExp(r'(?<=\d)\s+(?=\d)'),
      (_) => '',
    );
  }

  bool _isLikelyChrome(String value) {
    final normalized = value.trim();
    return RegExp(
          r'^(?:[\d.]+\s*)?(?:KB|MB|GB)/s.*$',
          caseSensitive: false,
        ).hasMatch(normalized) ||
        RegExp(r'^[Q©C钟]\s*\d+\s*分钟$').hasMatch(normalized);
  }

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

enum _SectionKind { ingredient, step, tip }
