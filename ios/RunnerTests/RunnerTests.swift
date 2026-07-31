import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testClipboardSanitizerReplacesIsolatedUtf16Surrogates() throws {
    KitchenNotesClipboardCompatibility.install()
    XCTAssertTrue(KitchenNotesClipboardCompatibility.isInstalled)

    let units: [unichar] = [
      0x0041,
      0xD800,
      0x0042,
      0xDC00,
      0xD83D,
      0xDE00,
    ]
    let invalidText = units.withUnsafeBufferPointer { buffer in
      NSString(characters: buffer.baseAddress!, length: buffer.count)
    }

    let sanitized = KitchenNotesClipboardCompatibility.sanitize(invalidText)

    XCTAssertEqual(sanitized, "A\u{FFFD}B\u{FFFD}😀")
    XCTAssertNoThrow(
      try JSONSerialization.data(withJSONObject: ["text": sanitized])
    )
  }
}
