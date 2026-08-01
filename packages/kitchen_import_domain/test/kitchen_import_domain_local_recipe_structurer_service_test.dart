import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  test('下厨房多页截图过滤重复框架并配对双列用料和跨页步骤', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '''23:53
<
百吃不厌的酸辣柠檬鸡爪-做法
「家庭版0失败」
下厨房评分
7.4
77人做过
好极了
挺好
一般
爱做菜的TT
关注
有没有跟我一样爱啃鸡爪子的小姐妹？怎么都感
觉吃不够～玩手机啃 看电视啃 聊天啃 吃饭啃。根
本停不下来
用料
鸡爪
柠檬
料酒
白砂糖
姜片
换算
2斤
1个
1勺
10克
3片
2.0万
58
交作业
说点什么..

23:53
49
<
爱做菜的TT
关注
•••
用料
鸡爪
柠檬
料酒
白砂糖
姜片
小葱
大蒜
小米辣
青尖椒
洋葱
生抽
老抽
耗油
陈醋
换算
2斤
1个
1勺
10克
3片
1根
10瓣
10个（根据自己喜好放）
4根
半个
2勺
半勺
适量
1勺
步骤1
烹饪模式
2.0万
• 58
交作业
说点什么…

23:53
三
<
爱做菜的TT
关注
••
步骤1
烹饪模式
鸡爪剪掉指甲剁块，锅里下鸡爪放葱姜料酒，大火
煮开撇去浮沫煮10分钟，冷水洗凉备用。
步骤2
2.0万
58
交作业
说点什么..

23:53 @…
三：
<
爱做菜的TT
关注
•••
准备好配料，全部切碎 如图所示。（柠檬片记得
去籽不然会苦）
步骤了
配料放保鲜盒加生抽 老抽 耗油 白砂糖 陈醋，把
鸡爪放下去搅拌均匀。
步骤4
2.0万
•
58
交作业
说点什么..

23:53
爱做菜的TT
关注
••.
配料放保鲜盒加生抽 老抽 耗油 白砂糖 陈醋，把
鸡爪放下去搅拌均匀。
步骤4
放冰箱冷藏入味四个小时以上，就可以食用了。
小贴士
做法超级简单
爱吃鸡爪的集美们赶紧动手做起来吧！期待你们的
作业
菜谱更新于2021-06-20，浏览31.9万次
力2.0万
•58
半公团庄上
交作业
说点什么…''',
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.title.value, '百吃不厌的酸辣柠檬鸡爪-做法');
    expect(draft.ingredients.value, [
      '鸡爪 2斤',
      '柠檬 1个',
      '料酒 1勺',
      '白砂糖 10克',
      '姜片 3片',
      '小葱 1根',
      '大蒜 10瓣',
      '小米辣 10个（根据自己喜好放）',
      '青尖椒 4根',
      '洋葱 半个',
      '生抽 2勺',
      '老抽 半勺',
      '耗油 适量',
      '陈醋 1勺',
    ]);
    expect(draft.steps.value, [
      '鸡爪剪掉指甲剁块，锅里下鸡爪放葱姜料酒，大火煮开撇去浮沫煮10分钟，冷水洗凉备用。',
      '准备好配料，全部切碎 如图所示。（柠檬片记得去籽不然会苦）',
      '配料放保鲜盒加生抽 老抽 耗油 白砂糖 陈醋，把鸡爪放下去搅拌均匀。',
      '放冰箱冷藏入味四个小时以上，就可以食用了。',
    ]);
  });

  test('吐司截图从后置话题文案提取菜名并跳过平台噪声', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '''#
高筋面粉200g
低筋面粉50g
盐3g
奶粉10g
蜂蜜50g
一个鸡蛋
牛奶135g
黄油20g
耐高糖酵母3g
蜂蜜DuangDuang吐司
赶紧去做吧
239
64
红书
小红书号502225''',
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.title.value, '蜂蜜DuangDuang吐司');
    expect(draft.ingredients.value, contains('鸡蛋 1个'));
    expect(draft.ingredients.value, isNot(contains('赶紧去做吧')));
  });

  test('全角话题标题优先于图片开头的食材行', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '''高筋面粉250g
牛奶130g
黄油20g
盐3g
白砂糖15g
耐高糖酵母3g
＃ 炼乳棉花吐司
赶紧去做起来
391
小红书''',
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.title.value, '炼乳棉花吐司');
    expect(draft.ingredients.value.first, '高筋面粉 250g');
  });

  test('没有食材分区时含用量的做法句不会误判为食材', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '''剁椒牛肉
牛肉切片加生抽、料酒、淀粉各1勺
少许盐和黑胡椒粉1勺食用油抓匀腌15分钟
油热下锅炒至变色盛出
放蒜末炒香 加剁椒酱翻炒再倒入牛肉
加适量生抽、蚝油和白糖翻炒均匀
撒上葱花出锅
小红书
小红书号：6163401578''',
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.title.value, '剁椒牛肉');
    expect(draft.ingredients.value, isEmpty);
    expect(draft.steps.value, hasLength(6));
    expect(draft.steps.value.first, startsWith('牛肉切片'));
    expect(draft.steps.value.last, '撒上葱花出锅');
  });

  test('无序拼图从中间提取菜名并分离调料与动作说明', () {
    final draft = const LocalRecipeStructurerService().structure(
      text: '''蒜末辣椒粉白芝麻淋热油
1勺蚝油
牛肉炒熟
1勺生抽
1勺料酒
2勺淀粉
香菜拌牛肉
1勺老抽
2勺生抽
1勺糖
香菜和牛肉
小红书
小红书号：6163401578''',
      source: const SourceSnapshot(originalText: ''),
    );

    expect(draft.title.value, '香菜拌牛肉');
    expect(draft.ingredients.value, [
      '蚝油 1勺',
      '生抽 1勺',
      '料酒 1勺',
      '淀粉 2勺',
      '老抽 1勺',
      '生抽 2勺',
      '糖 1勺',
    ]);
    expect(draft.steps.value, ['蒜末辣椒粉白芝麻淋热油', '牛肉炒熟']);
  });

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
