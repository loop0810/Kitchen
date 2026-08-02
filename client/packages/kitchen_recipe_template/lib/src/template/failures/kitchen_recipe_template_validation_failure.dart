enum TemplateValidationFailureCode {
  missingId,
  invalidVersion,
  invalidAspectRatio,
  invalidDesignWidth,
  invalidMinimumAppVersion,
  invalidRect,
  invalidTextStyle,
  invalidMaxLines,
  duplicateSlot,
  missingRequiredSlot,
}

class TemplateValidationFailure {
  const TemplateValidationFailure({required this.code, required this.message});

  /// 供程序判断错误类型的稳定错误码。
  final TemplateValidationFailureCode code;

  /// 面向模板开发者展示的中文错误说明。
  final String message;
}
