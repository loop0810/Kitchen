import 'kitchen_recipe_template_definition.dart';
import 'kitchen_recipe_template_validator_service.dart';

class TemplateCatalog {
  TemplateCatalog({
    required Iterable<TemplateDefinition> definitions,
    this.validator = const TemplateValidatorService(),
  }) : _definitions = {
         for (final definition in definitions)
           _key(definition.id, definition.version): definition,
       } {
    for (final definition in definitions) {
      final failures = validator(definition);
      if (failures.isNotEmpty) {
        throw ArgumentError.value(
          definition.id,
          'definitions',
          failures.map((failure) => failure.message).join(' '),
        );
      }
    }
  }

  final TemplateValidatorService validator;
  final Map<String, TemplateDefinition> _definitions;

  TemplateDefinition? find({required String id, required int version}) {
    return _definitions[_key(id, version)];
  }

  static String _key(String id, int version) => '$id@$version';
}
