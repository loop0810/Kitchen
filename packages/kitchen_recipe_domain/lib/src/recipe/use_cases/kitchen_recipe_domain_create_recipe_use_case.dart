import '../inputs/kitchen_recipe_domain_create_recipe_input.dart';
import '../services/kitchen_recipe_domain_create_recipe_validation_service.dart';
import '../repositories/kitchen_recipe_domain_recipe_repository.dart';

class CreateRecipeUseCase {
  const CreateRecipeUseCase(
    this._repository, {
    this.validationService = const CreateRecipeValidationService(),
  });

  final RecipeRepository _repository;
  final CreateRecipeValidationService validationService;

  Future<String> call(CreateRecipeInput input) {
    // UseCase 是业务入口：先执行与 UI 无关的领域校验，通过后才允许持久化。
    // 因为校验也在这里执行，未来的导入流程或其他页面不会绕过同一套规则。
    final failure = validationService(input);
    if (failure != null) throw failure;
    return _repository.createRecipe(input);
  }
}
