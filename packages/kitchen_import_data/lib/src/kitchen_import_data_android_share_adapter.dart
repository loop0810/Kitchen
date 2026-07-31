import 'dart:io';

import 'package:flutter/services.dart';

class AndroidSharedImportPayload {
  const AndroidSharedImportPayload({
    required this.version,
    required this.id,
    required this.action,
    required this.mimeType,
    required this.title,
    required this.subject,
    required this.text,
    required this.localPaths,
    required this.createdAt,
  });

  /// 原生暂存清单版本，用于未来兼容字段迁移。
  final int version;

  /// 单次系统分享的稳定 ID，也是原生暂存目录名。
  final String id;

  /// Android Intent action，用于诊断单项或多项分享来源。
  final String action;

  /// 分享方声明的 MIME 类型；分享方未声明时为空字符串。
  final String mimeType;

  /// Android `EXTRA_TITLE` 原始值；分享方未提供时为空字符串。
  final String title;

  /// Android `EXTRA_SUBJECT` 原始值；分享方未提供时为空字符串。
  final String subject;

  /// Android `EXTRA_TEXT` 原始值；仅图片分享时允许为空字符串。
  final String text;

  /// 已复制到应用私有暂存区的媒体绝对路径，保持分享顺序。
  final List<String> localPaths;

  /// 原生层完成暂存的时间。
  final DateTime createdAt;

  factory AndroidSharedImportPayload.fromMap(Map<Object?, Object?> map) {
    return AndroidSharedImportPayload(
      version: map['version'] as int,
      id: map['id'] as String,
      action: map['action'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      text: map['text'] as String? ?? '',
      localPaths: (map['files'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAtEpochMilliseconds'] as int,
      ),
    );
  }

  String get combinedText {
    return <String>[
      title.trim(),
      subject.trim(),
      text.trim(),
    ].where((part) => part.isNotEmpty).toSet().join('\n');
  }
}

class AndroidShareAdapter {
  AndroidShareAdapter([
    this._channel = const MethodChannel('kitchen_notes/import_share'),
  ]);

  final MethodChannel _channel;

  void setOnShareAvailable(Future<void> Function()? callback) {
    if (!Platform.isAndroid) return;
    if (callback == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shareAvailable') await callback();
    });
  }

  Future<List<AndroidSharedImportPayload>> listPendingShares() async {
    if (!Platform.isAndroid) return const [];
    final values =
        await _channel.invokeListMethod<Object?>('listPendingShares') ??
        const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(AndroidSharedImportPayload.fromMap)
        .toList(growable: false);
  }

  Future<void> acknowledge(String id) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('acknowledgeShare', {'id': id});
  }
}
