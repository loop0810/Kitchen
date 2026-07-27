import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';

void main() {
  test('搜索位置正确编码中文 query', () {
    final location = AppRouteNames.searchLocation('番茄 鸡蛋');

    expect(Uri.parse(location).path, '/search');
    expect(Uri.parse(location).queryParameters['q'], '番茄 鸡蛋');
  });

  test('详情位置正确编码 ID 参数', () {
    final location = AppRouteNames.recipeDetailLocation('recipe/中文');

    expect(location, '/recipes/recipe%2F%E4%B8%AD%E6%96%87');
  });
}
