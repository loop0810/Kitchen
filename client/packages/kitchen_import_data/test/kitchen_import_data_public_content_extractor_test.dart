import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/src/content/adapters/kitchen_import_data_public_content_extractor.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  const extractor = SafePublicContentExtractor();

  group('Recipe 结构化数据', () {
    test('优先使用 Recipe JSON-LD 并补充食材与步骤小标题', () {
      final text = extractor.extractRecipeTextFromHtml('''
<html><head>
<script type="application/ld+json">
{"@type":"Recipe","name":"番茄炒蛋","description":"家常快手菜",
 "recipeIngredient":["番茄 2 个","鸡蛋 3 个",42],
 "recipeInstructions":[{"@type":"HowToStep","text":"打散鸡蛋"},{"text":"翻炒番茄"}]}
</script>
</head><body><main>正文不应覆盖结构化数据</main></body></html>
''');

      expect(text, '''
番茄炒蛋
家常快手菜
食材：
番茄 2 个
鸡蛋 3 个
步骤：
1. 打散鸡蛋
2. 翻炒番茄''');
    });

    test('展开 HowToSection 时忽略分区名称只保留子步骤', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">
{"@type":["Recipe"],"name":"红烧肉",
 "recipeInstructions":[{"@type":"HowToSection","name":"准备",
   "itemListElement":[{"text":"切块"},{"name":"焯水"}]}]}
</script>
''');

      expect(text, '红烧肉\n步骤：\n1. 切块\n2. 焯水');
    });

    test('把压缩在单个字符串中的编号步骤拆成多行且不带原始编号', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">
{"@type":"Recipe","name":"炒青菜","recipeInstructions":"0.洗菜,1.热锅,2.翻炒出锅"}
</script>
''');

      expect(text, '炒青菜\n步骤：\n1. 洗菜\n2. 热锅\n3. 翻炒出锅');
    });

    test('无编号的步骤字符串保持原样作为单个步骤', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">
{"@type":"Recipe","name":"凉拌黄瓜","recipeInstructions":"拍碎后拌入调料"}
</script>
''');

      expect(text, '凉拌黄瓜\n步骤：\n1. 拍碎后拌入调料');
    });

    test('在嵌套 @graph 中找到 Recipe 节点', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">
{"@graph":[{"@type":"WebPage"},{"@type":"Recipe","name":"蛋炒饭"}]}
</script>
''');

      expect(text, '蛋炒饭');
    });

    test('跳过无法解析的 JSON-LD 继续读取后续脚本', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">{ 非法 JSON </script>
<script type='application/ld+json'>{"@type":"Recipe","name":"蒸蛋"}</script>
''');

      expect(text, '蒸蛋');
    });
  });

  group('Article 结构化数据与 OpenGraph', () {
    test('Article JSON-LD 去掉标题站点后缀并按食材步骤换行', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">
{"@type":"Article","headline":"照烧鸡腿 - 美食站",
 "description":"食材：鸡腿 2 只 生抽 15ml 步骤：腌制,1、煎制,2、收汁"}
</script>
''');

      expect(text, '''
照烧鸡腿
食材：
鸡腿 2 只
生抽 15ml
步骤：
腌制
1、煎制
2、收汁''');
    });

    test('没有 Article 结构化数据时使用 OpenGraph 元数据并拆分食材与步骤', () {
      final text = extractor.extractRecipeTextFromHtml('''
<meta property="og:title" content="蒜香排骨 &amp; 家常做法">
<meta name="og:description" content="🍳食材&amp;做法：排骨 500g 蒜 3瓣 1️⃣腌制 2️⃣蒸制 tips：少许糖提鲜">
''');

      expect(text, '''
蒜香排骨 & 家常做法
食材：
排骨 500g
蒜 3瓣
1. 腌制
2. 蒸制
注意事项：
少许糖提鲜''');
    });

    test('OpenGraph 缺少描述时不作为提取结果', () {
      final text = extractor.extractRecipeTextFromHtml(
        '<html><head><meta property="og:title" content="只有标题">'
        '<meta property="og:image" content="https://example.com/a.jpg">'
        '<title>页面标题</title></head>'
        '<body><main>正文</main></body></html>',
      );

      expect(text, '页面标题\n正文');
    });

    test('Article 只有标题时仍返回标题，不再回退到其他提取策略', () {
      final text = extractor.extractRecipeTextFromHtml('''
<script type="application/ld+json">
{"@type":"Article","headline":"蒜香排骨","description":"   "}
</script>
<meta property="og:description" content="排骨 500g">
''');

      expect(text, '蒜香排骨');
    });

    test('描述中的竖线分隔和酱汁小节各自换行', () {
      final text = extractor.extractRecipeTextFromHtml(
        '<meta property="og:description" '
        'content="口水鸡｜家常版 主料：鸡腿 酱汁：辣椒油 花椒粉">',
      );

      expect(text, '口水鸡\n家常版 主料：鸡腿\n酱汁：辣椒油 花椒粉');
    });
  });

  group('纯 HTML 回退', () {
    test('回退时保留标题并去除脚本、样式和标签', () {
      final text = extractor.extractRecipeTextFromHtml('''
<html><head><title>糖醋里脊</title></head>
<body>
<script>console.log('忽略脚本');</script>
<style>.a{color:red}</style>
<article><h1>糖醋里脊</h1><p>里脊 300g</p><p>&quot;糖醋汁&quot; &lt;比例&gt; 1:1</p></article>
<footer>页脚不在 article 内</footer>
</body></html>
''');

      expect(text, '''
糖醋里脊
糖醋里脊
里脊 300g
"糖醋汁" <比例> 1:1''');
    });

    test('没有标题和 article 时对整页去标签', () {
      final text = extractor.extractRecipeTextFromHtml(
        '<div><p>清炒时蔬</p><p>盐 适量</p></div>',
      );

      expect(text, '清炒时蔬\n盐 适量');
    });

    test('回退结果最多保留 500 行', () {
      final html = List.generate(600, (index) => '<p>第 $index 行</p>').join();

      expect(
        extractor.extractRecipeTextFromHtml(html).split('\n'),
        hasLength(500),
      );
    });
  });

  group('公开 HTTPS 校验', () {
    test('拒绝非 HTTPS 链接', () async {
      await expectLater(
        extractor.extract(Uri.parse('http://example.com/recipe')),
        throwsA(
          isA<ImportPipelineException>().having(
            (failure) => failure.code,
            'code',
            'unsupportedUrl',
          ),
        ),
      );
    });

    test('拒绝没有主机名的链接', () async {
      await expectLater(
        extractor.extract(Uri.parse('https:///recipe')),
        throwsA(
          isA<ImportPipelineException>().having(
            (failure) => failure.code,
            'code',
            'unsupportedUrl',
          ),
        ),
      );
    });

    test('拒绝指向本机的链接', () async {
      await expectLater(
        extractor.extract(Uri.parse('https://127.0.0.1/recipe')),
        throwsA(
          isA<ImportPipelineException>().having(
            (failure) => failure.code,
            'code',
            'unsafeUrl',
          ),
        ),
      );
    });

    test('拒绝指向私有网段的链接', () async {
      for (final host in const ['10.0.0.1', '172.16.0.1', '192.168.1.1']) {
        await expectLater(
          extractor.extract(Uri.parse('https://$host/recipe')),
          throwsA(
            isA<ImportPipelineException>().having(
              (failure) => failure.code,
              'code',
              'unsafeUrl',
            ),
          ),
          reason: host,
        );
      }
    });

    test('拒绝指向 IPv6 唯一本地地址的链接', () async {
      await expectLater(
        extractor.extract(Uri.parse('https://[fd00::1]/recipe')),
        throwsA(
          isA<ImportPipelineException>().having(
            (failure) => failure.code,
            'code',
            'unsafeUrl',
          ),
        ),
      );
    });
  });
}
