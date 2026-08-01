import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  test('合并 OCR 拆成两行的食材用量并忽略独立步骤编号', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '''番茄炒蛋
食材
番茄
2个
鸡蛋
3个
步骤
1
番茄切块
2
鸡蛋打散后炒熟''',
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.ingredients.value, ['番茄 2个', '鸡蛋 3个']);
    expect(draft.steps.value, ['番茄切块', '鸡蛋打散后炒熟']);
  });

  test('标准文章解析出菜名、食材和步骤并保留来源', () {
    const text = '''
番茄炒蛋
食材：
番茄 2 个
鸡蛋 3 个
步骤：
1. 番茄切块，鸡蛋打散
2. 炒熟鸡蛋后加入番茄
''';
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: text),
    );

    expect(draft.title.value, '番茄炒蛋');
    expect(draft.ingredients.value, ['番茄 2 个', '鸡蛋 3 个']);
    expect(draft.steps.value, ['番茄切块，鸡蛋打散', '炒熟鸡蛋后加入番茄']);
    expect(draft.sourceSnapshot.originalText, text);
  });

  test('混乱文本缺少可靠结构时保持空字段并提示确认', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '盐 适量\n随便炒一炒',
      source: const SourceSnapshot(originalText: '盐 适量\n随便炒一炒'),
    );

    expect(draft.title.value, isEmpty);
    expect(draft.title.needsConfirmation, isTrue);
    expect(draft.steps.value, isEmpty);
    expect(draft.steps.needsConfirmation, isTrue);
  });

  test('微信文案中的流程分区不会继续写入食材', () {
    const text = '''
12m+辅食｜宝宝版照烧鸡腿，巨下饭，味道绝了
食材：
鸡腿1个
葱姜蒜适量
水煮西兰花
流程：
1、将鸡腿剔骨，洗干净，里面肉厚的地方划几刀，然后用叉子插几下，这样更入味
2、鸡腿用葱姜蒜，宝宝酱油少量，一点松鲜鲜调味，抓拌均匀，盖上保鲜膜，腌制30分钟
3、把腌制好的鸡腿平铺到锅中，不需要刷油，小火煎至两面金黄，倒入酱汁（酱汁：清水，少量蜂蜜，少量宝宝酱油）
4、酱汁倒入锅中要快没过鸡腿的程度，汤汁太少鸡腿炖不烂糊
5、盖上盖子，小火焖煮，中途记得翻面，出锅前5分钟最好是鸡皮面朝下的，这样出来颜色更好一些，焖煮至酱汁浓稠即可出锅
''';
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: text),
    );

    expect(draft.title.value, '12m+辅食｜宝宝版照烧鸡腿，巨下饭，味道绝了');
    expect(draft.ingredients.value, ['鸡腿 1个', '葱 适量', '姜 适量', '蒜 适量', '水煮西兰花']);
    expect(draft.steps.value, hasLength(5));
    expect(draft.steps.value.first, startsWith('将鸡腿剔骨'));
    expect(draft.steps.value.last, startsWith('盖上盖子'));
  });

  test('Unicode 行分隔符不会破坏微信文案分区', () {
    const text =
        '\uFEFF照烧鸡腿\u2028食材：\u2029鸡腿1个\u2028'
        '流程：\u20291、煎至两面金黄';
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: text),
    );

    expect(draft.title.value, '照烧鸡腿');
    expect(draft.ingredients.value, ['鸡腿 1个']);
    expect(draft.steps.value, ['煎至两面金黄']);
  });

  test('混合食材标题、竖线清单和 emoji 编号可以正确分区', () {
    const text = '''
宝宝照烧鸡腿饭
🍳 食材 & 做法
鸡腿去骨｜鸡蛋｜西兰花｜胡萝卜｜姜葱
酱汁：温热水加冰糖、酱油备用
1️⃣鸡腿肉洗净后用叉子戳一戳
2️⃣煎至两面金黄后倒入酱汁
⚠️ Tips
适合一岁以上宝宝
''';
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: text),
    );

    expect(draft.title.value, '宝宝照烧鸡腿饭');
    expect(draft.ingredients.value, [
      '鸡腿去骨',
      '鸡蛋',
      '西兰花',
      '胡萝卜',
      '姜',
      '葱',
      '酱汁：温热水加冰糖、酱油备用',
    ]);
    expect(draft.steps.value, ['鸡腿肉洗净后用叉子戳一戳', '煎至两面金黄后倒入酱汁']);
  });

  test('扁平网页描述会拆开组合香料、粘连用量和后续酱汁', () {
    const text = '''
照烧鸡腿
食材：
鸡腿1个
葱姜蒜适量
姜葱 酱汁：温热水加冰糖、酱油备用
步骤：
1. 煎熟鸡腿
''';
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: text),
    );

    expect(draft.ingredients.value, [
      '鸡腿 1个',
      '葱 适量',
      '姜 适量',
      '蒜 适量',
      '姜',
      '葱',
      '酱汁：温热水加冰糖、酱油备用',
    ]);
  });

  test('前置用量会转换为编辑器约定的食材名称加用量', () {
    const text = '''
自制周黑鸭
食材：
2斤鸭掌
10片姜
25克红辣椒
2块桂皮
步骤：
1. 焯水
''';
    final draft = const LocalRecipeStructurerService().structure(
      text: text,
      source: const SourceSnapshot(originalText: text),
    );

    expect(draft.ingredients.value, ['鸭掌 2斤', '姜 10片', '红辣椒 25克', '桂皮 2块']);
  });
}
