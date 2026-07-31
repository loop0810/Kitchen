class RecipeSourceSnapshot {
  const RecipeSourceSnapshot({
    required this.originalText,
    this.publicUrl,
    this.sourceTitle,
  });

  /// 用户导入时保存的原始文字；手动创建时为空字符串。
  final String originalText;

  /// 原始公开 HTTPS 地址；没有链接或手动创建时为空。
  final Uri? publicUrl;

  /// 来源页面标题；未提取成功时为空。
  final String? sourceTitle;
}
