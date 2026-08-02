import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:lpinyin/lpinyin.dart';

/// 使用完整拼音实现中文优先的菜谱阅读顺序。
class PinyinRecipeReadingOrderPolicy implements RecipeReadingOrderPolicy {
  const PinyinRecipeReadingOrderPolicy();

  @override
  int compare(
    RecipeJournalSummaryEntity left,
    RecipeJournalSummaryEntity right,
  ) {
    final leftKey = _keyFor(left.recipe.title);
    final rightKey = _keyFor(right.recipe.title);
    final byGroup = leftKey.group.compareTo(rightKey.group);
    if (byGroup != 0) return byGroup;
    final byReading = leftKey.reading.compareTo(rightKey.reading);
    if (byReading != 0) return byReading;
    final byTitle = leftKey.normalized.compareTo(rightKey.normalized);
    if (byTitle != 0) return byTitle;
    return left.recipe.id.compareTo(right.recipe.id);
  }

  @override
  String groupLabelFor(String title) => _keyFor(title).groupLabel;

  _ReadingKey _keyFor(String title) {
    final normalized = title.trim().toLowerCase();
    final runes = normalized.runes.toList(growable: false);
    final firstIndex = runes.indexWhere(_isMeaningfulRune);
    if (firstIndex < 0) {
      return _ReadingKey(2, normalized, normalized, '#');
    }
    final first = runes[firstIndex];
    final meaningfulText = String.fromCharCodes(runes.skip(firstIndex));
    if (_isChinese(first)) {
      final reading = PinyinHelper.getPinyinE(
        meaningfulText,
        separator: '',
      ).toLowerCase();
      return _ReadingKey(0, reading, normalized, _letterGroup(reading));
    }
    if (_isAsciiLetter(first)) {
      return _ReadingKey(
        1,
        meaningfulText,
        normalized,
        String.fromCharCode(first).toUpperCase(),
      );
    }
    return _ReadingKey(2, meaningfulText, normalized, '#');
  }

  bool _isMeaningfulRune(int rune) =>
      _isChinese(rune) || _isAsciiLetter(rune) || _isAsciiDigit(rune);

  bool _isChinese(int rune) =>
      (rune >= 0x3400 && rune <= 0x4DBF) ||
      (rune >= 0x4E00 && rune <= 0x9FFF) ||
      (rune >= 0xF900 && rune <= 0xFAFF);

  bool _isAsciiLetter(int rune) =>
      (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);

  bool _isAsciiDigit(int rune) => rune >= 0x30 && rune <= 0x39;

  String _letterGroup(String value) {
    if (value.isEmpty) return '#';
    final rune = value.runes.first;
    return _isAsciiLetter(rune) ? String.fromCharCode(rune).toUpperCase() : '#';
  }
}

class _ReadingKey {
  const _ReadingKey(this.group, this.reading, this.normalized, this.groupLabel);

  final int group;
  final String reading;
  final String normalized;
  final String groupLabel;
}
