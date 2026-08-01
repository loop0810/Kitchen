import 'kitchen_import_domain_import_task_entity.dart';
import 'kitchen_import_domain_import_task_repository.dart';
import 'kitchen_import_domain_recipe_draft_entity.dart';

abstract interface class OcrAdapter {
  Future<String> recognize(ImportMediaReference media);
}

abstract interface class PublicContentExtractor {
  Future<String> extract(Uri url);
}

abstract interface class RecipeStructuringAdapter {
  Future<RecipeDraftEntity?> structure({
    required String idempotencyRequestId,
    required String text,
  });
}

abstract interface class RecipeStructurer {
  RecipeDraftEntity structure({
    required String text,
    required SourceSnapshot source,
  });
}

class ImportPipeline {
  factory ImportPipeline({
    required ImportTaskRepository repository,
    required RecipeStructurer localStructurer,
    PublicContentExtractor? publicContentExtractor,
    OcrAdapter? ocrAdapter,
    RecipeStructuringAdapter? cloudStructuringAdapter,
  }) {
    return ImportPipeline._(
      repository,
      localStructurer,
      publicContentExtractor,
      ocrAdapter,
      cloudStructuringAdapter,
    );
  }

  ImportPipeline._(
    this._repository,
    this._localStructurer,
    this._publicContentExtractor,
    this._ocrAdapter,
    this._cloudStructuringAdapter,
  );

  final ImportTaskRepository _repository;
  final RecipeStructurer _localStructurer;
  final PublicContentExtractor? _publicContentExtractor;
  final OcrAdapter? _ocrAdapter;
  final RecipeStructuringAdapter? _cloudStructuringAdapter;

  Future<void> process(String taskId) async {
    final task = await _repository.getTask(taskId);
    if (task == null || task.status == ImportTaskStatus.cancelled) return;
    try {
      var text = task.originalText;
      if (task.media.isNotEmpty) {
        final adapter = _ocrAdapter;
        if (adapter == null) {
          throw const ImportPipelineException(
            'ocrUnavailable',
            '当前设备的离线文字识别尚不可用，可稍后重试或手动整理。',
          );
        }
        await _repository.updateStatus(
          taskId,
          ImportTaskStatus.recognizingImages,
        );
        final pages = <String>[];
        final orderedMedia =
            task.media.where((item) => !item.ignored).toList(growable: false)
              ..sort((left, right) => left.position.compareTo(right.position));
        if (orderedMedia.isEmpty) {
          throw const ImportPipelineException(
            'imageUnreadable',
            '没有可识别的图片，请重新选择图片或手动创建菜谱。',
          );
        }
        for (final media in orderedMedia) {
          if (await _isCancelled(taskId)) return;
          if (media.ocrCompleted) {
            pages.add(media.ocrText ?? '');
            continue;
          }
          final pageText = await adapter.recognize(media);
          await _repository.saveMediaOcr(
            taskId: taskId,
            mediaId: media.id,
            text: pageText,
          );
          pages.add(pageText);
        }
        if (await _isCancelled(taskId)) return;
        final ocrText = pages.join('\n\n');
        if (ocrText.trim().isEmpty) {
          throw const ImportPipelineException(
            'imageUnreadable',
            '没有识别到清晰文字，请更换图片或手动创建菜谱。',
          );
        }
        await _repository.saveOcrText(taskId, ocrText);
        text = [
          task.originalText.trim(),
          ocrText.trim(),
        ].where((part) => part.isNotEmpty).join('\n\n');
      } else if (task.detectedPublicUrl != null &&
          _publicContentExtractor != null) {
        await _repository.updateStatus(taskId, ImportTaskStatus.extracting);
        final extracted = await _publicContentExtractor.extract(
          task.detectedPublicUrl!,
        );
        if (await _isCancelled(taskId)) return;
        if (extracted.trim().isNotEmpty) {
          // 纯链接本身不是可结构化正文，也不能占据菜名候选的第一行；URL 已经
          // 单独保存在 SourceSnapshot 中。分享文案包含额外说明时仍保留原文。
          final isOnlyUrl = RegExp(
            r'^\s*https?://\S+\s*$',
            caseSensitive: false,
          ).hasMatch(text);
          final textWithoutUrl = isOnlyUrl
              ? ''
              : text.replaceAll(task.detectedPublicUrl!.toString(), '').trim();
          text = textWithoutUrl.isEmpty
              ? extracted
              : '$textWithoutUrl\n\n$extracted';
        }
      }
      await _repository.updateStatus(taskId, ImportTaskStatus.structuring);
      final source = SourceSnapshot(
        originalText: task.originalText,
        publicUrl: task.detectedPublicUrl,
      );
      final cloudDraft = await _cloudStructuringAdapter?.structure(
        idempotencyRequestId: taskId,
        text: text,
      );
      final draft =
          cloudDraft ?? _localStructurer.structure(text: text, source: source);
      if (await _isCancelled(taskId)) return;
      await _repository.saveDraft(taskId, draft);
    } on ImportPipelineException catch (error) {
      await _failIfPresent(taskId, error.code, error.message);
    } catch (_) {
      await _failIfPresent(
        taskId,
        'processingFailed',
        '整理过程中遇到问题，原始内容已保留，可以重试。',
      );
    }
  }

  Future<void> retry(String taskId) async {
    await _repository.retry(taskId);
    await process(taskId);
  }

  /// 保存用户校对后的 OCR 文字，并仅重新执行结构化阶段。
  ///
  /// 原始图片及逐页 OCR 仍单独保留，所以校对不会破坏后续重新识别的能力。
  Future<void> restructureFromOcrText(
    String taskId,
    String correctedText,
  ) async {
    final task = await _repository.getTask(taskId);
    if (task == null || task.status == ImportTaskStatus.cancelled) return;
    final normalized = correctedText.trim();
    if (normalized.isEmpty) {
      throw const ImportPipelineException(
        'emptyOcrText',
        '识别文字不能为空，可返回后重新选择图片。',
      );
    }
    await _repository.saveOcrText(taskId, normalized);
    await _repository.updateStatus(taskId, ImportTaskStatus.structuring);
    final source = SourceSnapshot(
      originalText: task.originalText,
      publicUrl: task.detectedPublicUrl,
    );
    final draft = _localStructurer.structure(
      text: [
        task.originalText.trim(),
        normalized,
      ].where((part) => part.isNotEmpty).join('\n\n'),
      source: source,
    );
    if (await _isCancelled(taskId)) return;
    await _repository.saveDraft(taskId, draft);
  }

  Future<void> resumePending() async {
    final tasks = await _repository.watchTasks().first;
    for (final task in tasks.where(
      (task) => {
        ImportTaskStatus.queued,
        ImportTaskStatus.extracting,
        ImportTaskStatus.recognizingImages,
        ImportTaskStatus.structuring,
      }.contains(task.status),
    )) {
      await process(task.id);
    }
  }

  Future<bool> _isCancelled(String taskId) async {
    final current = await _repository.getTask(taskId);
    return current == null || current.status == ImportTaskStatus.cancelled;
  }

  Future<void> _failIfPresent(
    String taskId,
    String code,
    String message,
  ) async {
    try {
      await _repository.fail(taskId: taskId, code: code, message: message);
    } on StateError {
      // 用户可在 OCR、提取或结构化期间删除任务；此时没有状态需要回写。
    }
  }
}

class ImportPipelineException implements Exception {
  const ImportPipelineException(this.code, this.message);

  /// 稳定错误分类。
  final String code;

  /// 面向用户的下一步说明。
  final String message;
}
