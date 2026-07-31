import Foundation
import ObjectiveC.runtime
import UIKit

/// 修复 Flutter iOS 剪贴板通道无法编码孤立 UTF-16 代理项时的原生崩溃。
///
/// Flutter 3.44.0 的 `FlutterPlatformPlugin` 会把 `UIPasteboard.string` 直接交给
/// JSON codec。部分跨设备或富文本剪贴板可能返回包含孤立代理项的 `NSString`，
/// 该字符串无法转换为 UTF-8，最终会由 Foundation 断言终止进程。
enum KitchenNotesClipboardCompatibility {
  private static var isClipboardChannelInstalled = false
  private static var isTextInputInstalled = false

  static var isInstalled: Bool {
    isClipboardChannelInstalled && isTextInputInstalled
  }

  static func install() {
    installClipboardChannelSanitizer()
    installTextInputSanitizer()
  }

  private static func installClipboardChannelSanitizer() {
    guard !isClipboardChannelInstalled else {
      return
    }

    let originalSelector = NSSelectorFromString("getClipboardData:")
    let replacementSelector = #selector(
      KitchenNotesClipboardCompatibilityTarget.kitchenNotesGetClipboardData(_:)
    )
    guard
      let pluginClass = NSClassFromString("FlutterPlatformPlugin"),
      let originalMethod = class_getInstanceMethod(pluginClass, originalSelector),
      let replacementMethod = class_getInstanceMethod(
        KitchenNotesClipboardCompatibilityTarget.self,
        replacementSelector
      )
    else {
      // Flutter 升级后内部类型或方法可能变化；找不到目标时保留引擎默认行为。
      return
    }

    method_setImplementation(originalMethod, method_getImplementation(replacementMethod))
    isClipboardChannelInstalled = true
  }

  private static func installTextInputSanitizer() {
    guard !isTextInputInstalled else {
      return
    }

    let originalSelector = NSSelectorFromString("insertText:")
    let replacementSelector = #selector(
      KitchenNotesClipboardCompatibilityTarget.kitchenNotesInsertText(_:)
    )
    guard
      let textInputClass = NSClassFromString("FlutterTextInputView"),
      let originalMethod = class_getInstanceMethod(textInputClass, originalSelector),
      let replacementMethod = class_getInstanceMethod(
        KitchenNotesClipboardCompatibilityTarget.self,
        replacementSelector
      ),
      class_addMethod(
        textInputClass,
        replacementSelector,
        method_getImplementation(replacementMethod),
        method_getTypeEncoding(replacementMethod)
      ),
      let addedMethod = class_getInstanceMethod(textInputClass, replacementSelector)
    else {
      return
    }

    // iOS 26 的系统粘贴直接调用 FlutterTextInputView.insertText:，不会经过
    // Clipboard.getData。交换实现后，所有进入 Flutter 编辑状态的文本都会先校验。
    method_exchangeImplementations(originalMethod, addedMethod)
    isTextInputInstalled = true
  }

  static func clipboardData(format: NSString?) -> NSDictionary? {
    if let format, format != "text/plain" {
      return nil
    }
    guard let text = UIPasteboard.general.string else {
      return nil
    }
    return ["text": sanitize(text as NSString)]
  }

  /// 将孤立的 UTF-16 高、低代理项替换为 U+FFFD，同时保留合法代理项对。
  static func sanitize(_ text: NSString) -> String {
    let length = text.length
    guard length > 0 else {
      return ""
    }

    var source = [unichar](repeating: 0, count: length)
    text.getCharacters(&source, range: NSRange(location: 0, length: length))

    var sanitized = [unichar]()
    sanitized.reserveCapacity(length)
    var index = 0
    while index < source.count {
      let unit = source[index]
      if (0xD800...0xDBFF).contains(unit) {
        if index + 1 < source.count, (0xDC00...0xDFFF).contains(source[index + 1]) {
          sanitized.append(unit)
          sanitized.append(source[index + 1])
          index += 2
          continue
        }
        sanitized.append(0xFFFD)
      } else if (0xDC00...0xDFFF).contains(unit) {
        sanitized.append(0xFFFD)
      } else {
        sanitized.append(unit)
      }
      index += 1
    }

    return sanitized.withUnsafeBufferPointer { buffer in
      NSString(characters: buffer.baseAddress!, length: buffer.count) as String
    }
  }
}

@objc private final class KitchenNotesClipboardCompatibilityTarget: NSObject {
  @objc func kitchenNotesGetClipboardData(_ format: NSString?) -> NSDictionary? {
    KitchenNotesClipboardCompatibility.clipboardData(format: format)
  }

  @objc dynamic func kitchenNotesInsertText(_ text: NSString) {
    let sanitized = KitchenNotesClipboardCompatibility.sanitize(text)
    // 安装时该 selector 已与 FlutterTextInputView.insertText: 交换，因此这里会调用
    // 引擎原实现，不会递归回到当前兼容方法。
    kitchenNotesInsertText(sanitized as NSString)
  }
}
