# OCR 图片质量 benchmark

本目录保存可重新调用端侧 OCR 的图片级质量样本，与 `ocr_replay/` 只回放既有文字行
和坐标的用途不同。公开样本均由仓库脚本生成，不包含真实账号、设备标识、第三方平台
截图或本机绝对路径，可在项目内用于测试；不得把未授权用户图片复制进本目录。

## 文件

- `manifest.schema.json`：样本与人工标准答案的数据约束。
- `manifest.json`：版本化样本清单、相对图片路径、场景标签与人工标准答案。
- `budgets.json`：按场景设置的质量与性能预算；Android 真机基线后只允许显式评审调整。
- `images/`：由 `client/tool/generate_ocr_benchmark_images.swift` 生成的合成 PNG。
- `results/reference-ground-truth.json`：用于验证 runner 的零误差参考结果，不代表平台 OCR。

## 私有真实截图

未脱敏或没有再分发授权的真实截图只能放在仓库根 `.gitignore` 已排除的
`client/.ocr_benchmark_private/`。私有 manifest 使用相同 schema，图片路径必须相对
manifest，匿名 `sampleId` 不得包含菜名、账号或设备信息。报告只允许输出匿名 ID、
场景标签和聚合指标，不输出 OCR 正文。

## 运行

```sh
cd client
dart run tool/ocr_quality_benchmark.dart \
  --manifest packages/kitchen_import_domain/test/fixtures/ocr_benchmark/manifest.json \
  --results packages/kitchen_import_domain/test/fixtures/ocr_benchmark/results/reference-ground-truth.json \
  --budgets packages/kitchen_import_domain/test/fixtures/ocr_benchmark/budgets.json
```

Android 真机采集结果使用同一 results schema，并额外记录引擎、设备类别、处理 profile、
每页耗时与峰值内存。相同 manifest、引擎版本、预处理版本与预算版本才可直接比较。
