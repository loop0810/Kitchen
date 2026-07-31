import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:objective_c/objective_c.dart';

void main() {
  test('Objective-C Foundation 类可以从 Native Asset 解析', () {
    if (!Platform.isMacOS) return;
    final array = NSArray.of(const <ObjCObject>[]);
    expect(array.asDart(), isEmpty);
  });
}
