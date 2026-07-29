import 'kitchen_recipe_template_app_version_value_object.dart';
import 'kitchen_recipe_template_definition.dart';
import 'kitchen_recipe_template_slot.dart';
import 'kitchen_recipe_template_validation_failure.dart';

class TemplateValidatorService {
  const TemplateValidatorService();

  List<TemplateValidationFailure> call(TemplateDefinition definition) {
    // 不在首个错误处返回：模板导入工具可以一次展示所有问题，减少反复修改。
    final failures = <TemplateValidationFailure>[];
    if (definition.id.trim().isEmpty) {
      failures.add(
        const TemplateValidationFailure(
          code: TemplateValidationFailureCode.missingId,
          message: '模板 ID 不能为空。',
        ),
      );
    }
    if (definition.version <= 0) {
      failures.add(
        const TemplateValidationFailure(
          code: TemplateValidationFailureCode.invalidVersion,
          message: '模板版本必须大于 0。',
        ),
      );
    }
    if (!definition.aspectRatio.isFinite || definition.aspectRatio <= 0) {
      failures.add(
        const TemplateValidationFailure(
          code: TemplateValidationFailureCode.invalidAspectRatio,
          message: '模板比例必须为有效正数。',
        ),
      );
    }
    if (!definition.designWidth.isFinite || definition.designWidth <= 0) {
      failures.add(
        const TemplateValidationFailure(
          code: TemplateValidationFailureCode.invalidDesignWidth,
          message: '模板设计宽度必须为有效正数。',
        ),
      );
    }
    if (TemplateAppVersionValueObject.tryParse(definition.minimumAppVersion) ==
        null) {
      failures.add(
        const TemplateValidationFailure(
          code: TemplateValidationFailureCode.invalidMinimumAppVersion,
          message: '最低 App 版本必须使用 major.minor.patch 格式。',
        ),
      );
    }

    final slotKinds = <TemplateSlotKind>{};
    for (final slot in definition.slots) {
      if (!slot.rect.isNormalized) {
        failures.add(
          TemplateValidationFailure(
            code: TemplateValidationFailureCode.invalidRect,
            message: '${slot.kind.name} 槽位坐标必须位于标准化画布内。',
          ),
        );
      }
      if (slot.maxLines <= 0) {
        failures.add(
          TemplateValidationFailure(
            code: TemplateValidationFailureCode.invalidMaxLines,
            message: '${slot.kind.name} 槽位最大行数必须大于 0。',
          ),
        );
      }
      if (slot.textStyle.fontSize <= 0 ||
          slot.textStyle.fontWeight < 100 ||
          slot.textStyle.fontWeight > 900) {
        failures.add(
          TemplateValidationFailure(
            code: TemplateValidationFailureCode.invalidTextStyle,
            message: '${slot.kind.name} 槽位文字样式无效。',
          ),
        );
      }
      if (!slotKinds.add(slot.kind)) {
        // 同类槽位重复会让渲染器无法判断哪个是权威内容位置。
        failures.add(
          TemplateValidationFailure(
            code: TemplateValidationFailureCode.duplicateSlot,
            message: '${slot.kind.name} 槽位不能重复。',
          ),
        );
      }
    }
    for (final decoration in definition.decorationLayers) {
      if (!decoration.rect.isNormalized) {
        failures.add(
          const TemplateValidationFailure(
            code: TemplateValidationFailureCode.invalidRect,
            message: '装饰层坐标必须位于标准化画布内。',
          ),
        );
      }
    }

    const requiredKinds = {
      TemplateSlotKind.recipeTitle,
      TemplateSlotKind.primaryIngredients,
      TemplateSlotKind.detailAction,
    };
    // 标题、主要食材和详情入口构成手账摘要的最小可用信息。
    for (final requiredKind in requiredKinds.difference(slotKinds)) {
      failures.add(
        TemplateValidationFailure(
          code: TemplateValidationFailureCode.missingRequiredSlot,
          message: '缺少 ${requiredKind.name} 必需槽位。',
        ),
      );
    }
    return List.unmodifiable(failures);
  }
}
