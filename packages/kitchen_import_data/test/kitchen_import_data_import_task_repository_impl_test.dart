import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/src/kitchen_import_data_app_database.dart';
import 'package:kitchen_import_data/src/kitchen_import_data_import_task_repository_impl.dart';
import 'package:kitchen_import_data/src/kitchen_import_data_public_content_extractor.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

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
