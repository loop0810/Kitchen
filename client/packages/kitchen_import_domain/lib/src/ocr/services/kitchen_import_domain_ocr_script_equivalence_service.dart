/// 只为结构化规则生成繁简等价键，不得用于展示或回写用户文字。
class OcrScriptEquivalenceService {
  const OcrScriptEquivalenceService();

  static const _traditionalToSimplified = {
    '驟': '骤',
    '製': '制',
    '備': '备',
    '準': '准',
    '飪': '饪',
    '貼': '贴',
    '註': '注',
    '換': '换',
    '標': '标',
    '題': '题',
  };

  String key(String value) {
    return value.split('').map((character) {
      return _traditionalToSimplified[character] ?? character;
    }).join();
  }
}
