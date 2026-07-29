class TemplateAppVersionValueObject
    implements Comparable<TemplateAppVersionValueObject> {
  const TemplateAppVersionValueObject({
    required this.major,
    required this.minor,
    required this.patch,
  });

  /// 不兼容变更对应的主版本号。
  final int major;

  /// 向后兼容功能变更对应的次版本号。
  final int minor;

  /// 向后兼容修复对应的补丁版本号。
  final int patch;

  static TemplateAppVersionValueObject? tryParse(String value) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(value.trim());
    if (match == null) return null;
    return TemplateAppVersionValueObject(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(TemplateAppVersionValueObject other) {
    final majorComparison = major.compareTo(other.major);
    if (majorComparison != 0) return majorComparison;
    final minorComparison = minor.compareTo(other.minor);
    if (minorComparison != 0) return minorComparison;
    return patch.compareTo(other.patch);
  }
}
