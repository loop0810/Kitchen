package com.example.kitchen_notes

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var shareChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // 分享 URI 的临时读取授权可能在 Activity 生命周期结束后失效，因此必须先
        // 复制到应用私有暂存区，再启动 Flutter 侧的导入任务。
        stageShareIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (stageShareIntent(intent)) {
            shareChannel?.invokeMethod("shareAvailable", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kitchen_notes/import_share",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "listPendingShares" -> result.success(listPendingShares())
                    "acknowledgeShare" -> {
                        val id = call.argument<String>("id")
                        if (id.isNullOrBlank()) {
                            result.error("invalid_share_id", "分享暂存 ID 为空。", null)
                        } else {
                            File(shareRoot(), id).deleteRecursively()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(
          flutterEngine.dartExecutor.binaryMessenger,
          "kitchen_notes/import_ocr",
        ).setMethodCallHandler { call, result ->
            // 这是 Android 对同一个 MethodChannel 的实现。Dart 侧不需要知道这里
            // 使用 ML Kit；它只接收与 iOS 相同的 width、height 和 lines 数据。
            if (call.method != "recognizeDocument") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("invalid_image", "图片路径为空。", null)
                return@setMethodCallHandler
            }

            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            } catch (_: Exception) {
                result.error("invalid_image", "图片损坏或无法读取。", null)
                return@setMethodCallHandler
            }
            // 中文识别器同时覆盖中文字符与常见拉丁字符；模型随 APK/AAB 打包，
            // 因此离线首次启动也能使用。
            val recognizer = TextRecognition.getClient(
                ChineseTextRecognizerOptions.Builder().build(),
            )
            recognizer.process(image)
                .addOnSuccessListener { recognized ->
                    // ML Kit 已经把识别结果分成 textBlocks 和 lines。项目只保留 line
                    // 层，因为菜谱布局分析关心的是“每一行文字在哪里”，不需要保存
                    // ML Kit 的 Block 容器。
                    val width = image.width.coerceAtLeast(1)
                    val height = image.height.coerceAtLeast(1)
                    val lines = recognized.textBlocks
                        .flatMap { block -> block.lines }
                        .mapIndexedNotNull { index, line ->
                            val box = line.boundingBox ?: return@mapIndexedNotNull null
                            // ML Kit 返回像素坐标；除以图片宽高后转换为 0...1 的相对
                            // 坐标。Android 的 top/bottom 已经以左上角为原点，无需翻转。
                            mapOf(
                                "id" to "line-$index",
                                "text" to line.text,
                                "left" to box.left.toDouble() / width,
                                "top" to box.top.toDouble() / height,
                                "right" to box.right.toDouble() / width,
                                "bottom" to box.bottom.toDouble() / height,
                            )
                        }
                    result.success(
                        // 返回结构必须和 iOS 一致，Flutter 适配器才能共用一套解析代码。
                        mapOf(
                            "width" to width,
                            "height" to height,
                            "lines" to lines,
                        ),
                    )
                    recognizer.close()
                }
                .addOnFailureListener {
                    result.error("ocr_failed", "图片文字识别失败。", null)
                    recognizer.close()
                }
        }
    }

    private fun stageShareIntent(intent: Intent?): Boolean {
        if (intent == null ||
            (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE)
        ) {
            return false
        }
        if (intent.getBooleanExtra(SHARE_STAGED_EXTRA, false)) return false

        val id = UUID.randomUUID().toString()
        val directory = File(shareRoot(), id)
        val files = JSONArray()
        return try {
            directory.mkdirs()
            sharedUris(intent).distinct().forEachIndexed { index, uri ->
                val target = File(directory, sharedFileName(uri, index))
                contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { output -> input.copyTo(output) }
                } ?: error("无法读取分享图片")
                files.put(target.absolutePath)
            }
            val sharedText = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                ?: intent.clipData
                    ?.let { clip -> if (clip.itemCount > 0) clip.getItemAt(0).text else null }
                    ?.toString()
                ?: ""
            val manifest = JSONObject()
                .put("version", 1)
                .put("id", id)
                .put("action", intent.action)
                .put("mimeType", intent.type ?: "")
                .put("title", intent.getStringExtra(Intent.EXTRA_TITLE) ?: "")
                .put("subject", intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "")
                .put("text", sharedText)
                .put("files", files)
                .put("createdAtEpochMilliseconds", System.currentTimeMillis())
            val temporary = File(directory, "manifest.json.tmp")
            temporary.writeText(manifest.toString(), Charsets.UTF_8)
            check(temporary.renameTo(File(directory, MANIFEST_FILE)))
            intent.putExtra(SHARE_STAGED_EXTRA, true)
            true
        } catch (_: Exception) {
            directory.deleteRecursively()
            false
        }
    }

    private fun sharedUris(intent: Intent): List<Uri> {
        val result = mutableListOf<Uri>()
        intent.clipData?.let { clip ->
            for (index in 0 until clip.itemCount) {
                clip.getItemAt(index).uri?.let(result::add)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                    ?.let(result::addAll)
            } else {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let(result::add)
            }
        } else {
            if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let(result::addAll)
            } else {
                @Suppress("DEPRECATION")
                (intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))?.let(result::add)
            }
        }
        return result
    }

    private fun sharedFileName(uri: Uri, index: Int): String {
        var displayName: String? = null
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) displayName = cursor.getString(0)
            }
        val safeExtension = displayName
            ?.substringAfterLast('.', "")
            ?.takeIf { it.matches(Regex("[A-Za-z0-9]{1,8}")) }
            ?: MimeTypeMap.getSingleton()
                .getExtensionFromMimeType(contentResolver.getType(uri))
            ?: "jpg"
        return index.toString().padStart(3, '0') + "." + safeExtension.lowercase()
    }

    private fun listPendingShares(): List<Map<String, Any?>> {
        return shareRoot().listFiles()
            ?.sortedBy { it.name }
            ?.mapNotNull { directory ->
                val manifest = File(directory, MANIFEST_FILE)
                if (!manifest.isFile) return@mapNotNull null
                runCatching {
                    val json = JSONObject(manifest.readText(Charsets.UTF_8))
                    mapOf(
                        "version" to json.getInt("version"),
                        "id" to json.getString("id"),
                        "action" to json.optString("action"),
                        "mimeType" to json.optString("mimeType"),
                        "title" to json.optString("title"),
                        "subject" to json.optString("subject"),
                        "text" to json.optString("text"),
                        "files" to buildList {
                            val values = json.getJSONArray("files")
                            for (index in 0 until values.length()) add(values.getString(index))
                        },
                        "createdAtEpochMilliseconds" to
                            json.getLong("createdAtEpochMilliseconds"),
                    )
                }.getOrNull()
            } ?: emptyList()
    }

    private fun shareRoot(): File {
        return File(filesDir, "import_share_staging").apply { mkdirs() }
    }

    private companion object {
        const val SHARE_STAGED_EXTRA = "kitchen_notes.share_staged"
        const val MANIFEST_FILE = "manifest.json"
    }
}
