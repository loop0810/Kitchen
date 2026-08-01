import 'kitchen_recipe_domain_recipe_query.dart';

/// 菜谱库排序偏好的持久化契约。
abstract interface class RecipeSortPreferenceRepository {
  /// 读取上次选择；首次使用时返回最近更新。
  Future<RecipeSortOrder> getSortOrder();

  /// 保存排序选择供下次启动恢复。
  Future<void> setSortOrder(RecipeSortOrder order);
}

class GetRecipeSortPreferenceUseCase {
  const GetRecipeSortPreferenceUseCase(this._repository);
  final RecipeSortPreferenceRepository _repository;
  Future<RecipeSortOrder> call() => _repository.getSortOrder();
}

class SetRecipeSortPreferenceUseCase {
  const SetRecipeSortPreferenceUseCase(this._repository);
  final RecipeSortPreferenceRepository _repository;
  Future<void> call(RecipeSortOrder order) => _repository.setSortOrder(order);
}
