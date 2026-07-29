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

  final TemplateValidationFailureCode code;
  final String message;
}
