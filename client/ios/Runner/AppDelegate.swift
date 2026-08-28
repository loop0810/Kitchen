import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 必须在 Flutter 平台通道首次读取剪贴板前安装，避免异常 UTF-16 触发原生断言。
    KitchenNotesClipboardCompatibility.install()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "kitchen_notes/import_ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    // 这里是 Flutter MethodChannel 的 iOS 实现。Dart 侧调用 recognizeDocument
    // 时会进入这个闭包；识别完成后必须通过 result 回传一次成功值或错误。
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeDocument" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String,
        let image = UIImage(contentsOfFile: path),
        let cgImage = image.cgImage
      else {
        result(FlutterError(
          code: "invalid_image",
          message: "图片损坏或无法读取。",
          details: nil
        ))
        return
      }
      let request = VNRecognizeTextRequest { request, error in
        if error != nil {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "ocr_failed",
              message: "图片文字识别失败。",
              details: nil
            ))
          }
          return
        }
        // Vision 返回的是一组文字区域。每个 observation 代表一行（或一个可读的
        // 文字块），这里选它最可信的候选文字，并把区域一起传给 Flutter。
        let lines = (request.results as? [VNRecognizedTextObservation])?
          .enumerated()
          .compactMap { index, observation -> [String: Any]? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            // Vision 的 boundingBox 已经是 0...1 的相对坐标，但原点在左下角。
            // Domain 和 Android 统一使用左上角原点，所以要翻转垂直方向：
            // Domain top    = 1 - Vision maxY
            // Domain bottom = 1 - Vision minY
            return [
              "id": "line-\(index)",
              "text": candidate.string,
              "confidence": candidate.confidence,
              "left": box.minX,
              "top": 1 - box.maxY,
              "right": box.maxX,
              "bottom": 1 - box.minY,
            ]
          } ?? []
        DispatchQueue.main.async {
          result([
            "width": Int(image.size.width * image.scale),
            "height": Int(image.size.height * image.scale),
            "lines": lines,
          ])
        }
      }
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
      request.usesLanguageCorrection = true
      // OCR 可能耗时较长，放到后台队列执行，避免阻塞 Flutter 主线程；完成后再
      // 切回主线程调用 result，因为 Flutter 通道回调需要在主线程完成。
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "ocr_failed",
              message: "图片文字识别失败。",
              details: nil
            ))
          }
        }
      }
    }

  }
}
