import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

class ImportDependencies {
  const ImportDependencies({
    required this.repository,
    required this.pipeline,
    required this.persistPickedImages,
  });

  final ImportTaskRepository repository;
  final ImportPipeline pipeline;
  final Future<List<String>> Function(List<String> sourcePaths)
  persistPickedImages;
}

final importDependenciesProvider = Provider<ImportDependencies>((ref) {
  throw StateError('ImportDependencies must be provided by the app.');
});

final importTasksProvider = StreamProvider<List<ImportTaskEntity>>((ref) {
  return ref.watch(importDependenciesProvider).repository.watchTasks();
});

final importTaskProvider = StreamProvider.autoDispose
    .family<ImportTaskEntity?, String>((ref, taskId) {
      return ref
          .watch(importDependenciesProvider)
          .repository
          .watchTasks()
          .map((tasks) => tasks.where((task) => task.id == taskId).firstOrNull);
    });
