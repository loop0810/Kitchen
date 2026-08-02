import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class ProfileDependencies {
  const ProfileDependencies({required this.personalRecipeConfigRepository});

  final PersonalRecipeConfigRepository personalRecipeConfigRepository;
}

final profileDependenciesProvider = Provider<ProfileDependencies>((ref) {
  throw StateError('请在应用组合根注入 ProfileDependencies。');
});

final personalRecipeConfigProvider = StreamProvider<PersonalRecipeConfigEntity>(
  (ref) {
    return ref
        .watch(profileDependenciesProvider)
        .personalRecipeConfigRepository
        .watchCached();
  },
);
