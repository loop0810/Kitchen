import '../../import_task/entities/kitchen_import_domain_import_task_entity.dart';
import '../../import_task/repositories/kitchen_import_domain_import_task_repository.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_document_entity.dart';
import '../../recipe_draft/entities/kitchen_import_domain_recipe_draft_entity.dart';
import '../../recipe_draft/services/kitchen_import_domain_recipe_draft_merge_service.dart';

abstract interface class OcrAdapter {
  Future<OcrPageEntity> recognize(ImportMediaReference media);
}

abstract interface class PublicContentExtractor {
  Future<String> extract(Uri url);
}

abstract interface class RecipeStructurer {
  RecipeDraftEntity structure({
    required String text,
    required SourceSnapshot source,
    OcrDocumentEntity? ocrDocument,
  });
}

class ImportPipeline {
  /// 负责把一个导入任务处理成“等待用户确认”的菜谱草稿。
  ///
  /// 任务本身已经保存在 [repository] 中，所以这里接收的不是临时文本或图片，
  /// 而是任务 ID。处理到哪一步、产生了什么中间结果，都会及时写回任务。
  factory ImportPipeline({
    required ImportTaskRepository repository,
    required RecipeStructurer localStructurer,
    PublicContentExtractor? publicContentExtractor,
    OcrAdapter? ocrAdapter,
  }) {
    return ImportPipeline._(
      repository,
      localStructurer,
      publicContentExtractor,
      ocrAdapter,
    );
  }

  ImportPipeline._(
    this._repository,
    this._localStructurer,
    this._publicContentExtractor,
    this._ocrAdapter,
  );

  final ImportTaskRepository _repository;
  final RecipeStructurer _localStructurer;
  final PublicContentExtractor? _publicContentExtractor;
  final OcrAdapter? _ocrAdapter;
  final RecipeDraftMergeService _draftMergeService =
      const RecipeDraftMergeService();

  Future<void> process(String taskId) async {
    final task = await _repository.getTask(taskId);
    if (task == null || task.status == ImportTaskStatus.cancelled) return;

    // 记录本次处理开始时的版本。处理期间如果用户修改了图片，任务版本会增加；
    // 后面的保存操作带着旧版本，就不会把旧结果写回新任务。
    final generation = task.processingGeneration;
    try {
      // text 是最后交给结构化器的文字。文字可能来自粘贴内容、分享文案、网页
      // 正文或 OCR；先准备好它，再统一执行下面的“生成草稿”步骤。
      var text = task.originalText;
      OcrDocumentEntity? ocrDocument;
      if (task.media.isNotEmpty) {
        // 有图片时，先逐张识别。每张图片的结果单独保存，后续重试时可以复用
        // 已识别成功的图片，不必整批重新开始。
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
          expectedGeneration: generation,
        );
        final pages = <OcrPageEntity>[];
        // ignored 图片不参与识别；其余图片按用户在导入箱中看到的顺序处理。
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
          if (media.ocrCompleted && media.ocrPage != null) {
            pages.add(media.ocrPage!);
            continue;
          }
          try {
            // 先标记“识别中”，这样用户能看到当前进度，也能区分尚未处理和失败。
            await _repository.markMediaOcrProcessing(
              taskId: taskId,
              mediaId: media.id,
              expectedGeneration: generation,
            );
            final page = await adapter.recognize(media);
            // 保存完整 OCR 页面，而不只是文字。页面中的坐标和置信度还会用于
            // 判断版面、过滤噪声，以及在草稿中显示字段来源。
            await _repository.saveMediaOcr(
              taskId: taskId,
              mediaId: media.id,
              page: page,
              expectedGeneration: generation,
            );
            pages.add(page);
          } catch (_) {
            // 一张图片失败不影响其他图片。详情页可以让用户只替换、旋转或重试
            // 这一张，而不需要重新导入整组截图。
            await _repository.saveMediaOcrFailure(
              taskId: taskId,
              mediaId: media.id,
              code: 'pageUnreadable',
              message: '这张图片未识别成功，可替换、旋转、裁剪或单独重试。',
              expectedGeneration: generation,
            );
          }
        }
        if (await _isCancelled(taskId)) return;
        ocrDocument = OcrDocumentEntity(pages: pages);
        final ocrText = ocrDocument.plainText;
        if (ocrDocument.isEmpty) {
          throw const ImportPipelineException(
            'imageUnreadable',
            '没有识别到清晰文字，请更换图片或手动创建菜谱。',
          );
        }
        await _repository.saveOcrText(
          taskId,
          ocrText,
          expectedGeneration: generation,
        );
        // 用户校对过的 OCR 优先使用；没有校对内容时才使用本次机器识别结果。
        // 原始分享文案和用户补充说明也一起保留，避免图片任务丢掉上下文。
        text = [
          task.originalText.trim(),
          (task.correctedOcrText ?? ocrText).trim(),
          task.supplementalText.trim(),
        ].where((part) => part.isNotEmpty).join('\n\n');
      } else if (task.detectedPublicUrl != null &&
          _publicContentExtractor != null) {
        // 没有图片但检测到链接时，尝试读取公开网页。网页正文只是对原文的补充，
        // 不会替换原始分享内容；读取失败时，用户仍可直接整理原文。
        await _repository.updateStatus(
          taskId,
          ImportTaskStatus.extracting,
          expectedGeneration: generation,
        );
        final extracted = await _publicContentExtractor.extract(
          task.detectedPublicUrl!,
        );
        if (await _isCancelled(taskId)) return;
        if (extracted.trim().isNotEmpty) {
          // 如果原文只有 URL，就用网页正文作为主要文字；如果原文还有分享文案，
          // 则把网页正文接在文案后面。URL 本身不参与菜名识别，但会保存为来源。
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
      await _repository.updateStatus(
        taskId,
        ImportTaskStatus.structuring,
        expectedGeneration: generation,
      );
      // 到这里，图片、文案和网页链接都已经转换成统一的文字输入。结构化器根据
      // 文字和 OCR 页面生成草稿；如果任务已有草稿，只更新仍由系统负责的字段。
      final source = SourceSnapshot(
        originalText: task.originalText,
        publicUrl: task.detectedPublicUrl,
      );
      final candidate = _localStructurer.structure(
        text: text,
        source: source,
        ocrDocument: ocrDocument,
      );
      final draft = task.draft == null
          ? candidate
          : _draftMergeService.merge(
              // 用户已经编辑或确认的字段不能被这次自动整理覆盖。
              current: task.draft!,
              candidate: candidate,
            );
      if (await _isCancelled(taskId)) return;
      await _repository.saveDraft(
        // 保存后任务状态会变成 awaitingReview，审核页会通过 Stream 读到这份草稿。
        taskId,
        draft,
        expectedGeneration: generation,
      );
    } on ImportPipelineException catch (error) {
      await _failIfPresent(
        taskId,
        error.code,
        error.message,
        expectedGeneration: generation,
      );
    } catch (_) {
      await _failIfPresent(
        taskId,
        'processingFailed',
        '整理过程中遇到问题，原始内容已保留，可以重试。',
        expectedGeneration: generation,
      );
    }
  }

  Future<void> retry(String taskId) async {
    // 重试复用同一个任务，因此原文、图片和已经成功的 OCR 结果都还在。
    await _repository.retry(taskId);
    await process(taskId);
  }

  /// 保存用户校对后的 OCR 文字，并从这段文字重新生成草稿。
  ///
  /// 这里只重新执行结构化，不重新读取图片；原始图片和机器 OCR 结果仍会保留。
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
    await _repository.saveCorrectedOcrText(taskId, normalized);
    final current = await _repository.getTask(taskId);
    if (current == null) return;
    final generation = current.processingGeneration;
    await _repository.updateStatus(
      taskId,
      ImportTaskStatus.structuring,
      expectedGeneration: generation,
    );
    final source = SourceSnapshot(
      originalText: task.originalText,
      publicUrl: task.detectedPublicUrl,
    );
    // 校对后的文字与原始分享文案、用户补充说明合并后重新整理。这里没有传入
    // ocrDocument，因为用户已经明确修改了 OCR 文本，应以修改后的文字为准。
    final draft = _localStructurer.structure(
      text: [
        task.originalText.trim(),
        normalized,
        current.supplementalText.trim(),
      ].where((part) => part.isNotEmpty).join('\n\n'),
      source: source,
      ocrDocument: null,
    );
    if (await _isCancelled(taskId)) return;
    final merged = current.draft == null
        ? draft
        : _draftMergeService.merge(current: current.draft!, candidate: draft);
    await _repository.saveDraft(taskId, merged, expectedGeneration: generation);
  }

  Future<void> resumePending() async {
    // App 重启后只继续处理尚未完成的任务。已经生成草稿或已经失败的任务，
    // 必须等待用户进入审核或点击重试，避免启动时偷偷改变用户看到的内容。
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
    // 长时间 OCR 或网页读取期间，用户可能已经删除任务；每个阶段结束后都检查一次。
    final current = await _repository.getTask(taskId);
    return current == null || current.status == ImportTaskStatus.cancelled;
  }

  Future<void> _failIfPresent(
    String taskId,
    String code,
    String message, {
    int? expectedGeneration,
  }) async {
    try {
      await _repository.fail(
        taskId: taskId,
        code: code,
        message: message,
        expectedGeneration: expectedGeneration,
      );
    } on StateError {
      // 任务可能在处理期间被删除，此时不再有任务可以保存失败状态。
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
