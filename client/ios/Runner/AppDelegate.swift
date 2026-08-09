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
        let lines = (request.results as? [VNRecognizedTextObservation])?
          .enumerated()
          .compactMap { index, observation -> [String: Any]? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            // Vision 使用左下角原点；Domain 统一为左上角原点和 0...1 坐标。
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
