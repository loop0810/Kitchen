import AppKit
import Foundation

struct Sample {
  let id: String
  let size: NSSize
  let title: String
  let ingredients: [String]
  let steps: [String]
  let traits: Set<String>
}

let samples = [
  Sample(id: "clear-hans", size: NSSize(width: 900, height: 1500), title: "番茄炒蛋", ingredients: ["食材", "番茄 2个", "鸡蛋 3个", "盐 少许"], steps: ["步骤", "1 番茄切块", "2 鸡蛋炒熟盛出", "3 倒入番茄和鸡蛋翻炒"], traits: ["clear", "hans"]),
  Sample(id: "blurred-hans", size: NSSize(width: 900, height: 1500), title: "青椒炒肉", ingredients: ["食材", "青椒 2个", "猪肉 200克"], steps: ["步骤", "1 猪肉切片腌制", "2 青椒和肉片炒熟"], traits: ["blurred", "hans"]),
  Sample(id: "small-text-hans", size: NSSize(width: 900, height: 1500), title: "香菇鸡汤", ingredients: ["食材", "鸡腿 2只", "香菇 8朵", "姜片 3片"], steps: ["步骤", "1 食材洗净", "2 小火炖煮四十分钟"], traits: ["smallText", "hans"]),
  Sample(id: "low-contrast-hans", size: NSSize(width: 900, height: 1500), title: "蒜蓉生菜", ingredients: ["食材", "生菜 1棵", "蒜末 适量"], steps: ["步骤", "1 蒜末炒香", "2 放入生菜快速翻炒"], traits: ["lowContrast", "hans"]),
  Sample(id: "rotated-hans", size: NSSize(width: 1500, height: 900), title: "红烧豆腐", ingredients: ["食材", "豆腐 1块", "生抽 2勺"], steps: ["步骤", "1 豆腐煎至金黄", "2 加入料汁焖煮"], traits: ["rotated", "hans"]),
  Sample(id: "multi-column-hans", size: NSSize(width: 1200, height: 1500), title: "清炒四季豆", ingredients: ["食材", "四季豆 300克", "蒜末 适量"], steps: ["步骤", "1 四季豆切段", "2 大火翻炒至断生"], traits: ["multiColumn", "hans"]),
  Sample(id: "chrome-noise-hans", size: NSSize(width: 900, height: 1500), title: "酸辣土豆丝", ingredients: ["食材", "土豆 2个", "干辣椒 3个"], steps: ["步骤", "1 土豆切丝泡水", "2 大火翻炒调味"], traits: ["excessChrome", "hans"]),
  Sample(id: "traditional-hant", size: NSSize(width: 900, height: 1500), title: "番茄炒蛋", ingredients: ["食材", "番茄 2個", "雞蛋 3個", "鹽 少許"], steps: ["步驟", "1 番茄切塊", "2 雞蛋炒熟盛出", "3 混合翻炒"], traits: ["clear", "hant"]),
  Sample(id: "mixed-script", size: NSSize(width: 900, height: 1500), title: "家常滷味拼盘", ingredients: ["食材", "雞蛋 4个", "豆腐 2塊", "生抽 2勺"], steps: ["步骤", "1 食材放入鍋中", "2 小火卤煮三十分鐘"], traits: ["mixedScript"]),
  Sample(id: "landscape-hans", size: NSSize(width: 1500, height: 900), title: "菌菇芦笋炒虾", ingredients: ["食材", "芦笋 150克", "虾仁 120克"], steps: ["步骤", "1 芦笋切段", "2 虾仁和菌菇翻炒"], traits: ["landscape", "hans"]),
]

guard CommandLine.arguments.count == 2 else {
  fputs("usage: swift generate_ocr_benchmark_images.swift <output-directory>\n", stderr)
  exit(64)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func draw(_ sample: Sample) -> NSImage {
  let image = NSImage(size: sample.size)
  image.lockFocus()
  NSColor.white.setFill()
  NSRect(origin: .zero, size: sample.size).fill()

  let lowContrast = sample.traits.contains("lowContrast")
  let foreground = lowContrast ? NSColor(calibratedWhite: 0.62, alpha: 1) : NSColor.black
  let shadow = NSShadow()
  shadow.shadowBlurRadius = sample.traits.contains("blurred") ? 3.2 : 0
  shadow.shadowOffset = .zero
  shadow.shadowColor = sample.traits.contains("blurred") ? NSColor.black.withAlphaComponent(0.45) : NSColor.clear
  let titleSize: CGFloat = sample.traits.contains("smallText") ? 24 : 54
  let bodySize: CGFloat = sample.traits.contains("smallText") ? 17 : 36
  let titleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: titleSize, weight: .bold),
    .foregroundColor: foreground,
    .shadow: shadow,
  ]
  let bodyStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: bodySize),
    .foregroundColor: foreground,
    .shadow: shadow,
  ]

  if sample.traits.contains("excessChrome") {
    ("10:08   5G                 86%" as NSString).draw(at: NSPoint(x: 36, y: sample.size.height - 55), withAttributes: bodyStyle)
    ("示例作者  关注  收藏  评论  分享" as NSString).draw(at: NSPoint(x: 36, y: sample.size.height - 125), withAttributes: bodyStyle)
    ("相关推荐  说点什么  查看更多" as NSString).draw(at: NSPoint(x: 36, y: 45), withAttributes: bodyStyle)
  }

  (sample.title as NSString).draw(at: NSPoint(x: 70, y: sample.size.height - 230), withAttributes: titleStyle)

  if sample.traits.contains("multiColumn") {
    for (index, line) in sample.ingredients.enumerated() {
      (line as NSString).draw(at: NSPoint(x: 70, y: sample.size.height - 340 - CGFloat(index) * 72), withAttributes: bodyStyle)
    }
    for (index, line) in sample.steps.enumerated() {
      (line as NSString).draw(at: NSPoint(x: 620, y: sample.size.height - 340 - CGFloat(index) * 72), withAttributes: bodyStyle)
    }
  } else {
    let lines = sample.ingredients + sample.steps
    for (index, line) in lines.enumerated() {
      (line as NSString).draw(at: NSPoint(x: 70, y: sample.size.height - 350 - CGFloat(index) * 78), withAttributes: bodyStyle)
    }
  }
  image.unlockFocus()
  return image
}

func pngData(_ image: NSImage, blurred: Bool) -> Data? {
  guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
  return bitmap.representation(using: .png, properties: [:])
}

for sample in samples {
  let destination = outputDirectory.appendingPathComponent("\(sample.id).png")
  guard let data = pngData(draw(sample), blurred: sample.traits.contains("blurred")) else {
    fputs("failed to render \(sample.id)\n", stderr)
    exit(1)
  }
  try data.write(to: destination, options: .atomic)
}

print("generated \(samples.count) benchmark images")
