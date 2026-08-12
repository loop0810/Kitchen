import '../../import_task/entities/kitchen_import_domain_import_task_entity.dart';
import '../../import_task/repositories/kitchen_import_domain_import_task_repository.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_document_entity.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_quality_entity.dart';
import '../../ocr/services/kitchen_import_domain_ocr_candidate_selector_service.dart';
import '../../ocr/services/kitchen_import_domain_ocr_correction_suggestion_service.dart';
import '../../ocr/services/kitchen_import_domain_ocr_input_preparer_service.dart';
import '../../ocr/services/kitchen_import_domain_ocr_text_quality_service.dart';
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
  /// 导入流程的编排器：把“输入材料”逐步变成可审核的菜谱草稿。
  ///
  /// 这里故意只依赖接口（Repository、OCR、网页提取和本地结构化器），
  /// 因此流程本身不知道图片来自相册、系统分享还是哪个平台，也不会直接
  /// 访问数据库或网络。学习这段代码时，可以把它看成一个状态机的执行器：
  /// `queued -> extracting/recognizingImages -> structuring -> draft`。
  factory ImportPipeline({
    required ImportTaskRepository repository,
    required RecipeStructurer localStructurer,
    PublicContentExtractor? publicContentExtractor,
    OcrAdapter? ocrAdapter,
    OcrInputPreparer? ocrInputPreparer,
  }) {
    return ImportPipeline._(
      repository,
      localStructurer,
      publicContentExtractor,
      ocrAdapter,
      ocrInputPreparer,
    );
  }

  ImportPipeline._(
    this._repository,
    this._localStructurer,
    this._publicContentExtractor,
    this._ocrAdapter,
    this._ocrInputPreparer,
  );

  final ImportTaskRepository _repository;
  final RecipeStructurer _localStructurer;
  final PublicContentExtractor? _publicContentExtractor;
  final OcrAdapter? _ocrAdapter;
  final OcrInputPreparer? _ocrInputPreparer;
  final OcrCandidateSelectorService _candidateSelector =
      const OcrCandidateSelectorService();
  final OcrTextQualityService _textQualityService =
      const OcrTextQualityService();
  final OcrCorrectionSuggestionService _suggestionService =
      const OcrCorrectionSuggestionService();
  final RecipeDraftMergeService _draftMergeService =
      const RecipeDraftMergeService();

  /// 从已持久化的任务继续处理，直到产生审核草稿或可恢复错误。
  ///
  /// 调用方不能把尚未落库的临时输入直接传进来；[taskId] 是状态机恢复、
  /// 幂等保存和异步代次检查共同使用的稳定身份。
  Future<void> process(String taskId) async {
    final task = await _repository.getTask(taskId);
    if (task == null || task.status == ImportTaskStatus.cancelled) return;
    // generation 是一次处理快照的版本号。用户在后台处理期间修改图片、排序
    // 或删除任务时会递增它；后续写回必须带上旧版本，Repository 才能拒绝过期结果。
    final generation = task.processingGeneration;
    try {
      var text = task.originalText;
      OcrDocumentEntity? ocrDocument;
      if (task.media.isNotEmpty) {
        // 图片导入按页增量处理：已成功的页直接复用，失败页单独记录，
        // 这样一张坏图不会让整批图片失去可恢复性。
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
            await _repository.markMediaOcrProcessing(
              taskId: taskId,
              mediaId: media.id,
              expectedGeneration: generation,
            );
            OcrInputPreparation? preparation;
            OcrPageEntity page;
            var imageQuality = const ImageQualityReport();
            var selectedCandidate = OcrCandidateSelection.original;
            try {
              preparation = await _ocrInputPreparer?.prepare(media);
              if (!await _isCurrent(taskId, generation)) return;
              if (preparation == null) {
                page = _withTextQuality(await adapter.recognize(media));
              } else {
                imageQuality = preparation.imageQuality;
                final originalPage = await _recognizeCandidate(
                  taskId: taskId,
                  generation: generation,
                  adapter: adapter,
                  sourceMedia: media,
                  candidate: preparation.original,
                );
                var selectedPage = originalPage;
                var selectedInput = preparation.original;
                final enhancedInput = preparation.enhanced;
                if (enhancedInput != null &&
                    await _isCurrent(taskId, generation)) {
                  try {
                    final enhancedPage = await _recognizeCandidate(
                      taskId: taskId,
                      generation: generation,
                      adapter: adapter,
                      sourceMedia: media,
                      candidate: enhancedInput,
                    );
                    if (_candidateSelector.shouldSelectEnhanced(
                      original: originalPage,
                      enhanced: enhancedPage,
                    )) {
                      selectedPage = enhancedPage;
                      selectedInput = enhancedInput;
                      selectedCandidate = OcrCandidateSelection.enhanced;
                    }
                  } catch (_) {
                    // 增强候选是可选优化，失败时继续使用原图结果。
                  }
                }
                page = _withTextQuality(
                  selectedPage,
                  preprocessMetadata: selectedInput.metadata,
                );
              }
              if (!await _isCurrent(taskId, generation)) return;
              if (preparation != null) {
                await _repository.saveMediaOcrQuality(
                  taskId: taskId,
                  mediaId: media.id,
                  imageQuality: imageQuality,
                  selectedCandidate: selectedCandidate,
                  expectedGeneration: generation,
                );
              }
            } finally {
              if (preparation != null) {
                await _ocrInputPreparer?.release(preparation);
              }
            }
            if (!await _isCurrent(taskId, generation)) return;
            await _repository.saveMediaOcr(
              taskId: taskId,
              mediaId: media.id,
              page: page,
              expectedGeneration: generation,
            );
            pages.add(page);
          } catch (_) {
            if (!await _isCurrent(taskId, generation)) return;
            // 单页失败不丢弃已成功页；页面级错误会驱动
            // 替换、旋转、裁剪或仅重试该页的恢复操作。
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
        final existingSuggestionStatus = {
          for (final suggestion in task.ocrQuality.suggestions)
            suggestion.id: suggestion.status,
        };
        final suggestions = _suggestionService
            .generate(ocrDocument)
            .map(
              (suggestion) => OcrCorrectionSuggestion(
                id: suggestion.id,
                originalText: suggestion.originalText,
                replacementText: suggestion.replacementText,
                reason: suggestion.reason,
                pageIndex: suggestion.pageIndex,
                lineId: suggestion.lineId,
                status:
                    existingSuggestionStatus[suggestion.id] ??
                    suggestion.status,
              ),
            )
            .toList(growable: false);
        if (!await _isCurrent(taskId, generation)) return;
        await _repository.saveOcrQuality(
          taskId,
          ImportOcrQualityState(
            textQuality: _textQualityService.assessDocument(ocrDocument),
            suggestions: suggestions,
            revisions: task.ocrQuality.revisions,
          ),
          expectedGeneration: generation,
        );
        text = [
          task.originalText.trim(),
          (task.correctedOcrText ?? ocrText).trim(),
          task.supplementalText.trim(),
        ].where((part) => part.isNotEmpty).join('\n\n');
      } else if (task.detectedPublicUrl != null &&
          _publicContentExtractor != null) {
        // 网页提取只在输入中检测到公开链接时触发；提取失败会保留原始分享文字，
        // 让用户仍能手动整理，而不是把导入任务变成不可用的黑盒失败。
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
      await _repository.updateStatus(
        taskId,
        ImportTaskStatus.structuring,
        expectedGeneration: generation,
      );
      // 结构化阶段统一消费文字和 OCR 证据，输出领域草稿；已有草稿要经过合并，
      // 以保护用户已经编辑或确认的字段不被新的自动结果覆盖。
      final source = SourceSnapshot(
        originalText: task.originalText,
        publicUrl: task.detectedPublicUrl,
      );
      // AI 属于未来由用户主动选择的付费增强能力；默认导入流程只执行本地
      // OCR、布局分析和保守结构化，不会静默上传内容或触发付费能力。
      final candidate = _localStructurer.structure(
        text: text,
        source: source,
        ocrDocument: ocrDocument,
      );
      final draft = task.draft == null
          ? candidate
          : _draftMergeService.merge(
              current: task.draft!,
              candidate: candidate,
            );
      if (await _isCancelled(taskId)) return;
      await _repository.saveDraft(
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

  /// 复位失败状态后复用同一任务重新处理，不重新保存或复制原始材料。
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
    // 应用冷启动时只恢复中间态。awaitingReview、failed 和 saved 都需要明确的
    // 用户动作，不能因为重启而自动覆盖草稿或反复重试失败输入。
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

  Future<bool> _isCurrent(String taskId, int generation) async {
    final current = await _repository.getTask(taskId);
    return current != null &&
        current.status != ImportTaskStatus.cancelled &&
        current.processingGeneration == generation;
  }

  Future<OcrPageEntity> _recognizeCandidate({
    required String taskId,
    required int generation,
    required OcrAdapter adapter,
    required ImportMediaReference sourceMedia,
    required OcrInputCandidate candidate,
  }) async {
    if (!await _isCurrent(taskId, generation)) {
      throw const ImportPipelineException('staleGeneration', '图片已更新。');
    }
    return adapter.recognize(candidate.asMedia(sourceMedia));
  }

  OcrPageEntity _withTextQuality(
    OcrPageEntity page, {
    OcrPreprocessMetadata? preprocessMetadata,
  }) {
    final undecorated = OcrPageEntity(
      pageIndex: page.pageIndex,
      pixelWidth: page.pixelWidth,
      pixelHeight: page.pixelHeight,
      lines: page.lines,
      platformMetadata: page.platformMetadata,
      preprocessMetadata: preprocessMetadata ?? page.preprocessMetadata,
    );
    return OcrPageEntity(
      pageIndex: undecorated.pageIndex,
      pixelWidth: undecorated.pixelWidth,
      pixelHeight: undecorated.pixelHeight,
      lines: undecorated.lines,
      platformMetadata: undecorated.platformMetadata,
      preprocessMetadata: undecorated.preprocessMetadata,
      textQuality: _textQualityService.assessPage(undecorated),
    );
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
