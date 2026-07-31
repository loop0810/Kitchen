import 'package:flutter/material.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_editor_recipe_form_widget.dart';

class CreateRecipePage extends StatelessWidget {
  const CreateRecipePage({super.key, this.initialInput, this.onCreated});

  final CreateRecipeInput? initialInput;
  final Future<void> Function(String recipeId)? onCreated;

  @override
  Widget build(BuildContext context) {
    return RecipeEditorFormWidget(
      initialInput: initialInput,
      onCreated: onCreated,
    );
  }
}
