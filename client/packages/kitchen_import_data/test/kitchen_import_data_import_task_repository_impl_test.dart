import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/src/import_task/database/kitchen_import_data_app_database.dart';
import 'package:kitchen_import_data/src/import_task/mappers/kitchen_import_data_import_task_mapper.dart';
import 'package:kitchen_import_data/src/import_task/repositories/kitchen_import_data_import_task_repository_impl.dart';
import 'package:kitchen_import_data/src/content/adapters/kitchen_import_data_public_content_extractor.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late ImportAppDatabase database;
  late ImportTaskRepositoryImpl repository;

  setUp(() {
    database = ImportAppDatabase.forTesting(NativeDatabase.memory());
    repository = ImportTaskRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('原文先持久化并自动识别公开 HTTPS 链接', () async {
    final taskId = await repository.createTextTask(
      '分享文案 https://example.com/recipe 更多内容',
    );
    final task = await repository.getTask(taskId);

    expect(task!.status, ImportTaskStatus.queued);
    expect(task.originalText, contains('分享文案'));
    expect(task.detectedPublicUrl, Uri.parse('https://example.com/recipe'));
  });

  test('HTTP 分享链接只在本地升级为 HTTPS 后进入提取流程', () async {
    final taskId = await repository.createSharedTask(
      originalText: '分享 http://xhslink.cn/o/example',
      controlledLocalPaths: const [],
    );
    final task = await repository.getTask(taskId);

    expect(task!.inputKind, ImportInputKind.sharedText);
    expect(task.originalText, contains('http://xhslink.cn'));
    expect(task.detectedPublicUrl, Uri.parse('https://xhslink.cn/o/example'));
  });

  test('草稿和任务状态可以恢复', () async {
    final taskId = await repository.createTextTask('番茄炒蛋');
    final draft = const LocalRecipeStructurerService().structure(
      text: '番茄炒蛋',
      source: const SourceSnapshot(originalText: '番茄炒蛋'),
    );
    await repository.saveDraft(taskId, draft);

    final restored = await repository.getTask(taskId);
    expect(restored!.status, ImportTaskStatus.awaitingReview);
    expect(restored.draft!.title.value, '番茄炒蛋');
  });

  test('带坐标 OCR 页面随任务持久化并可恢复', () async {
    final taskId = await repository.createImageTask(['controlled.jpg']);
    const page = OcrPageEntity(
      pageIndex: 0,
      pixelWidth: 1000,
      pixelHeight: 2000,
      lines: [
        OcrLineEntity(
          id: 'line-0',
          text: '番茄炒蛋',
          confidence: 0.96,
          boundingBox: OcrRectValueObject(
            left: 0.1,
            top: 0.2,
            right: 0.8,
            bottom: 0.3,
          ),
        ),
      ],
    );

    await repository.saveMediaOcr(
      taskId: taskId,
      mediaId: (await repository.getTask(taskId))!.media.single.id,
      page: page,
    );

    final restored = await repository.getTask(taskId);
    expect(restored!.media.single.ocrText, '番茄炒蛋');
    expect(restored.media.single.ocrPage!.lines.single.id, 'line-0');
    expect(restored.media.single.ocrPage!.lines.single.confidence, 0.96);
  });

  test('旧媒体 JSON 缺少修订和状态时安全恢复', () {
    final media = ImportTaskMapper.decodeMedia(
      '[{"id":"old","localPath":"old.jpg","position":0,"ocrText":"菜名","ocrCompleted":true}]',
    ).single;

    expect(media.originalLocalPath, 'old.jpg');
    expect(media.contentRevision, 0);
    expect(media.ocrStatus, ImportMediaOcrStatus.succeeded);
    expect(media.ocrErrorCode, isNull);
  });

  test('重排复用成功页，旋转只使目标页失效并递增 generation', () async {
    final taskId = await repository.createImageTask(['1.jpg', '2.jpg']);
    final before = (await repository.getTask(taskId))!;
    await repository.saveMediaOcr(
      taskId: taskId,
      mediaId: before.media.first.id,
      page: OcrPageEntity.fromPlainText(pageIndex: 0, text: '第一页'),
    );

    await repository.reorderMedia(
      taskId,
      before.media.reversed.map((item) => item.id).toList(),
    );
    final reordered = (await repository.getTask(taskId))!;
    expect(reordered.processingGeneration, 1);
    expect(reordered.media.last.ocrStatus, ImportMediaOcrStatus.succeeded);
    expect(reordered.media.last.ocrText, '第一页');

    final target = reordered.media.first;
    await repository.rotateMedia(taskId, target.id);
    final rotated = (await repository.getTask(taskId))!;
    final rotatedTarget = rotated.media.singleWhere(
      (item) => item.id == target.id,
    );
    expect(rotated.processingGeneration, 2);
    expect(rotatedTarget.contentRevision, 1);
    expect(rotatedTarget.rotationQuarterTurns, 1);
    expect(rotatedTarget.ocrStatus, ImportMediaOcrStatus.pending);
  });

  test('过期 generation 不得回写分页 OCR', () async {
    final taskId = await repository.createImageTask(['1.jpg']);
    final initial = (await repository.getTask(taskId))!;
    final mediaId = initial.media.single.id;
    await repository.rotateMedia(taskId, mediaId);

    await repository.saveMediaOcr(
      taskId: taskId,
      mediaId: mediaId,
      page: OcrPageEntity.fromPlainText(pageIndex: 0, text: '过期结果'),
      expectedGeneration: initial.processingGeneration,
    );

    final restored = (await repository.getTask(taskId))!;
    expect(restored.media.single.ocrText, isNull);
    expect(restored.media.single.ocrStatus, ImportMediaOcrStatus.pending);
  });

  test('用户校对正文与补充说明独立持久化', () async {
    final taskId = await repository.createImageTask(['1.jpg']);
    await repository.saveOcrText(taskId, '机器文字');
    await repository.saveCorrectedOcrText(taskId, '用户校对文字');
    await repository.saveSupplementalText(taskId, '少盐');

    final restored = (await repository.getTask(taskId))!;
    expect(restored.ocrText, '机器文字');
    expect(restored.correctedOcrText, '用户校对文字');
    expect(restored.supplementalText, '少盐');
    expect(restored.processingGeneration, 2);
  });

  test('忽略与恢复持久化且不丢失已成功分页', () async {
    final taskId = await repository.createImageTask(['1.jpg']);
    final mediaId = (await repository.getTask(taskId))!.media.single.id;
    await repository.saveMediaOcr(
      taskId: taskId,
      mediaId: mediaId,
      page: OcrPageEntity.fromPlainText(pageIndex: 0, text: '可复用文字'),
    );

    await repository.setMediaIgnored(taskId, mediaId, true);
    expect((await repository.getTask(taskId))!.media.single.ignored, isTrue);
    await repository.setMediaIgnored(taskId, mediaId, false);
    final restored = (await repository.getTask(taskId))!.media.single;
    expect(restored.ignored, isFalse);
    expect(restored.ocrStatus, ImportMediaOcrStatus.succeeded);
    expect(restored.ocrText, '可复用文字');
  });

  test('OCR 进行中旋转或重排后丢弃旧快照结果', () async {
    final rotateTaskId = await repository.createImageTask(['1.jpg']);
    final rotateAdapter = _SuspendedTestOcrAdapter();
    final rotatePipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
      ocrAdapter: rotateAdapter,
    );
    final rotating = rotatePipeline.process(rotateTaskId);
    await rotateAdapter.started.future;
    final rotateMediaId = (await repository.getTask(
      rotateTaskId,
    ))!.media.single.id;
    await repository.rotateMedia(rotateTaskId, rotateMediaId);
    rotateAdapter.result.complete(
      OcrPageEntity.fromPlainText(pageIndex: 0, text: '过期旋转结果'),
    );
    await rotating;
    final rotated = (await repository.getTask(rotateTaskId))!;
    expect(rotated.status, ImportTaskStatus.queued);
    expect(rotated.ocrText, isNull);

    final reorderTaskId = await repository.createImageTask(['1.jpg', '2.jpg']);
    final reorderAdapter = _SuspendedTestOcrAdapter();
    final reorderPipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
      ocrAdapter: reorderAdapter,
    );
    final reordering = reorderPipeline.process(reorderTaskId);
    await reorderAdapter.started.future;
    final reorderTask = (await repository.getTask(reorderTaskId))!;
    await repository.reorderMedia(
      reorderTaskId,
      reorderTask.media.reversed.map((item) => item.id).toList(),
    );
    reorderAdapter.result.complete(
      OcrPageEntity.fromPlainText(pageIndex: 0, text: '过期重排结果'),
    );
    await reordering;
    final reordered = (await repository.getTask(reorderTaskId))!;
    expect(reordered.status, ImportTaskStatus.queued);
    expect(reordered.ocrText, isNull);
  });

  test('单页失败可重试，成功页可复用，启动恢复会继续队列任务', () async {
    final taskId = await repository.createImageTask(['1.jpg']);
    final adapter = _FailOnceTestOcrAdapter();
    final pipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
      ocrAdapter: adapter,
    );
    await pipeline.process(taskId);
    var task = (await repository.getTask(taskId))!;
    expect(task.media.single.ocrStatus, ImportMediaOcrStatus.failed);

    await repository.retryMediaOcr(taskId, task.media.single.id);
    await pipeline.resumePending();
    task = (await repository.getTask(taskId))!;
    expect(task.status, ImportTaskStatus.awaitingReview);
    expect(task.media.single.ocrStatus, ImportMediaOcrStatus.succeeded);
    expect(adapter.calls, 2);

    await repository.retry(taskId);
    await pipeline.process(taskId);
    expect(adapter.calls, 2);
  });

  test('v1 数据库迁移后恢复旧任务并补齐新字段', () async {
    await database.close();
    final directory = await Directory.systemTemp.createTemp(
      'kitchen_import_migration_',
    );
    final file = File('${directory.path}/v1.sqlite');
    addTearDown(() => directory.delete(recursive: true));
    final legacy = sqlite.sqlite3.open(file.path);
    legacy.execute('''
CREATE TABLE import_tasks (
  id TEXT NOT NULL PRIMARY KEY,
  input_kind TEXT NOT NULL,
  status TEXT NOT NULL,
  original_text TEXT NOT NULL DEFAULT '',
  detected_public_url TEXT,
  media_json TEXT NOT NULL DEFAULT '[]',
  ocr_text TEXT,
  draft_json TEXT,
  error_code TEXT,
  error_message TEXT,
  final_recipe_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''');
    legacy.execute(
      "INSERT INTO import_tasks (id, input_kind, status, original_text, created_at, updated_at) VALUES ('legacy', 'pastedText', 'queued', '旧菜谱', 1767225600, 1767225600)",
    );
    legacy.execute('PRAGMA user_version = 1');
    legacy.close();

    final migratedDatabase = ImportAppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migratedDatabase.close);
    final migratedRepository = ImportTaskRepositoryImpl(migratedDatabase);
    final restored = await migratedRepository.getTask('legacy');

    expect(restored!.originalText, '旧菜谱');
    expect(restored.correctedOcrText, isNull);
    expect(restored.supplementalText, isEmpty);
    expect(restored.processingGeneration, 0);
  });

  test('删除任务清理受控图片且不触碰目录外文件', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kitchen_import_media_',
    );
    final controlledRoot = Directory('${directory.path}/import_media');
    final taskDirectory = Directory('${controlledRoot.path}/task')
      ..createSync(recursive: true);
    final controlled = File('${taskDirectory.path}/001.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final external = File('${directory.path}/external.jpg')
      ..writeAsBytesSync([4, 5, 6]);
    addTearDown(() => directory.delete(recursive: true));
    final guardedRepository = ImportTaskRepositoryImpl(
      database,
      mediaDirectoryProvider: () async => controlledRoot,
    );
    final taskId = await guardedRepository.createImageTask([
      controlled.path,
      external.path,
    ]);

    await guardedRepository.delete(taskId);

    expect(await guardedRepository.getTask(taskId), isNull);
    expect(await controlled.exists(), isFalse);
    expect(await external.exists(), isTrue);
  });

  test('裁剪提交保留原图，非受控替换失败时不改写引用', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kitchen_import_revision_',
    );
    final controlledRoot = Directory('${directory.path}/import_media')
      ..createSync(recursive: true);
    final original = File('${controlledRoot.path}/original.jpg')
      ..writeAsBytesSync([1]);
    final cropped = File('${controlledRoot.path}/cropped.jpg')
      ..writeAsBytesSync([2]);
    final external = File('${directory.path}/external.jpg')
      ..writeAsBytesSync([3]);
    addTearDown(() => directory.delete(recursive: true));
    final guardedRepository = ImportTaskRepositoryImpl(
      database,
      mediaDirectoryProvider: () async => controlledRoot,
    );
    final taskId = await guardedRepository.createImageTask([original.path]);
    final mediaId = (await guardedRepository.getTask(taskId))!.media.single.id;

    await guardedRepository.submitCroppedMedia(
      taskId: taskId,
      mediaId: mediaId,
      controlledLocalPath: cropped.path,
    );
    final revised = (await guardedRepository.getTask(taskId))!.media.single;
    expect(revised.originalLocalPath, original.path);
    expect(revised.localPath, cropped.path);
    expect(revised.contentRevision, 1);

    await expectLater(
      guardedRepository.replaceMedia(
        taskId: taskId,
        mediaId: mediaId,
        controlledLocalPath: external.path,
      ),
      throwsArgumentError,
    );
    expect(
      (await guardedRepository.getTask(taskId))!.media.single.localPath,
      cropped.path,
    );

    await guardedRepository.delete(taskId);
    expect(await original.exists(), isFalse);
    expect(await cropped.exists(), isFalse);
    expect(await external.exists(), isTrue);
  });

  test('公开网页优先解析 Recipe JSON-LD', () {
    const html = '''
<html><head><script type="application/ld+json">
{"@context":"https://schema.org","@type":"Recipe","name":"葱油拌面",
"recipeIngredient":["面条 100 克","小葱 2 根"],
"recipeInstructions":[{"@type":"HowToStep","text":"煮熟面条"},{"@type":"HowToStep","text":"拌入葱油"}]}
</script></head><body>无关导航</body></html>
''';
    final text = const SafePublicContentExtractor().extractRecipeTextFromHtml(
      html,
    );

    expect(text, contains('葱油拌面'));
    expect(text, contains('面条 100 克'));
    expect(text, contains('1. 煮熟面条'));
    expect(text, isNot(contains('无关导航')));
  });

  test('Recipe JSON-LD 会规范前置用量并展开从零开始的连续步骤', () {
    const html = '''
<script type="application/ld+json">
{"@type":"Recipe","name":"自制周黑鸭",
"recipeIngredient":["2斤鸭掌","10片姜","60克生抽","2罐啤酒"],
"recipeInstructions":[{"@type":"HowToStep","text":"0.鸭掌洗干净，冷水下锅,1.加入料酒和姜片,2.小火煮45分钟,3.大火收汁"}]}
</script>
''';
    final text = const SafePublicContentExtractor().extractRecipeTextFromHtml(
      html,
    );
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: SourceSnapshot(originalText: text),
    );

    expect(draft.ingredients.value, ['鸭掌 2斤', '姜 10片', '生抽 60克', '啤酒 2罐']);
    expect(draft.steps.value, ['鸭掌洗干净，冷水下锅', '加入料酒和姜片', '小火煮45分钟', '大火收汁']);
  });

  test('公开文章可以从通用 Article JSON-LD 提取标题和正文', () {
    const html = '''
<html><head><script type="application/ld+json">
{"@context":"https://schema.org","@type":"Article",
"headline":"宝宝版照烧鸡腿","description":"食材：鸡腿1个\\n流程：1、煎至两面金黄"}
</script></head><body>需要客户端脚本才能展示</body></html>
''';
    final text = const SafePublicContentExtractor().extractRecipeTextFromHtml(
      html,
    );

    expect(text, contains('宝宝版照烧鸡腿'));
    expect(text, contains('鸡腿1个'));
    expect(text, contains('煎至两面金黄'));
    expect(text, isNot(contains('需要客户端脚本')));
  });

  test('Article 元数据压平换行后仍可恢复食材与步骤分区', () {
    const html = '''
<script type="application/ld+json">
{"@type":"Article","headline":"宝宝版照烧鸡腿",
"description":"食材： 鸡腿1个 葱姜蒜适量 水煮西兰花 流程： 1、鸡腿剔骨 2、煎至两面金黄"}
</script>
''';
    final text = const SafePublicContentExtractor().extractRecipeTextFromHtml(
      html,
    );
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: SourceSnapshot(originalText: text),
    );

    expect(draft.ingredients.value, ['鸡腿 1个', '葱 适量', '姜 适量', '蒜 适量', '水煮西兰花']);
    expect(draft.steps.value, ['鸡腿剔骨', '煎至两面金黄']);
  });

  test('缺少 JSON-LD 时从 Open Graph 恢复混合格式菜谱', () {
    const html = '''
<html><head>
<meta property="og:title" content="宝宝照烧鸡腿饭 - 示例站点">
<meta property="og:description" content="🍳 食材 &amp; 做法 鸡腿｜鸡蛋｜西兰花 1️⃣鸡腿洗净 2️⃣煎至两面金黄 ⚠️ Tips 一岁以上食用">
</head></html>
''';
    final text = const SafePublicContentExtractor().extractRecipeTextFromHtml(
      html,
    );
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.title.value, '宝宝照烧鸡腿饭');
    expect(draft.ingredients.value, ['鸡腿', '鸡蛋', '西兰花']);
    expect(draft.steps.value, ['鸡腿洗净', '煎至两面金黄']);
  });
}

class _SuspendedTestOcrAdapter implements OcrAdapter {
  final started = Completer<void>();
  final result = Completer<OcrPageEntity>();

  @override
  Future<OcrPageEntity> recognize(ImportMediaReference media) {
    if (!started.isCompleted) started.complete();
    return result.future;
  }
}

class _FailOnceTestOcrAdapter implements OcrAdapter {
  var calls = 0;

  @override
  Future<OcrPageEntity> recognize(ImportMediaReference media) async {
    calls += 1;
    if (calls == 1) throw StateError('first failure');
    return OcrPageEntity.fromPlainText(
      pageIndex: media.position,
      text: '番茄炒蛋\n食材\n番茄 2个\n步骤\n番茄切块',
    );
  }
}
