// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_import_data_app_database.dart';

// ignore_for_file: type=lint
class $ImportTasksTable extends ImportTasks
    with TableInfo<$ImportTasksTable, ImportTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputKindMeta = const VerificationMeta(
    'inputKind',
  );
  @override
  late final GeneratedColumn<String> inputKind = GeneratedColumn<String>(
    'input_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta(
    'originalText',
  );
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceShareIdMeta = const VerificationMeta(
    'sourceShareId',
  );
  @override
  late final GeneratedColumn<String> sourceShareId = GeneratedColumn<String>(
    'source_share_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detectedPublicUrlMeta = const VerificationMeta(
    'detectedPublicUrl',
  );
  @override
  late final GeneratedColumn<String> detectedPublicUrl =
      GeneratedColumn<String>(
        'detected_public_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mediaJsonMeta = const VerificationMeta(
    'mediaJson',
  );
  @override
  late final GeneratedColumn<String> mediaJson = GeneratedColumn<String>(
    'media_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctedOcrTextMeta = const VerificationMeta(
    'correctedOcrText',
  );
  @override
  late final GeneratedColumn<String> correctedOcrText = GeneratedColumn<String>(
    'corrected_ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplementalTextMeta = const VerificationMeta(
    'supplementalText',
  );
  @override
  late final GeneratedColumn<String> supplementalText = GeneratedColumn<String>(
    'supplemental_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _processingGenerationMeta =
      const VerificationMeta('processingGeneration');
  @override
  late final GeneratedColumn<int> processingGeneration = GeneratedColumn<int>(
    'processing_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _draftJsonMeta = const VerificationMeta(
    'draftJson',
  );
  @override
  late final GeneratedColumn<String> draftJson = GeneratedColumn<String>(
    'draft_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrQualityJsonMeta = const VerificationMeta(
    'ocrQualityJson',
  );
  @override
  late final GeneratedColumn<String> ocrQualityJson = GeneratedColumn<String>(
    'ocr_quality_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalRecipeIdMeta = const VerificationMeta(
    'finalRecipeId',
  );
  @override
  late final GeneratedColumn<String> finalRecipeId = GeneratedColumn<String>(
    'final_recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inputKind,
    status,
    originalText,
    sourceShareId,
    detectedPublicUrl,
    mediaJson,
    ocrText,
    correctedOcrText,
    supplementalText,
    processingGeneration,
    draftJson,
    ocrQualityJson,
    errorCode,
    errorMessage,
    finalRecipeId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('input_kind')) {
      context.handle(
        _inputKindMeta,
        inputKind.isAcceptableOrUnknown(data['input_kind']!, _inputKindMeta),
      );
    } else if (isInserting) {
      context.missing(_inputKindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('original_text')) {
      context.handle(
        _originalTextMeta,
        originalText.isAcceptableOrUnknown(
          data['original_text']!,
          _originalTextMeta,
        ),
      );
    }
    if (data.containsKey('source_share_id')) {
      context.handle(
        _sourceShareIdMeta,
        sourceShareId.isAcceptableOrUnknown(
          data['source_share_id']!,
          _sourceShareIdMeta,
        ),
      );
    }
    if (data.containsKey('detected_public_url')) {
      context.handle(
        _detectedPublicUrlMeta,
        detectedPublicUrl.isAcceptableOrUnknown(
          data['detected_public_url']!,
          _detectedPublicUrlMeta,
        ),
      );
    }
    if (data.containsKey('media_json')) {
      context.handle(
        _mediaJsonMeta,
        mediaJson.isAcceptableOrUnknown(data['media_json']!, _mediaJsonMeta),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('corrected_ocr_text')) {
      context.handle(
        _correctedOcrTextMeta,
        correctedOcrText.isAcceptableOrUnknown(
          data['corrected_ocr_text']!,
          _correctedOcrTextMeta,
        ),
      );
    }
    if (data.containsKey('supplemental_text')) {
      context.handle(
        _supplementalTextMeta,
        supplementalText.isAcceptableOrUnknown(
          data['supplemental_text']!,
          _supplementalTextMeta,
        ),
      );
    }
    if (data.containsKey('processing_generation')) {
      context.handle(
        _processingGenerationMeta,
        processingGeneration.isAcceptableOrUnknown(
          data['processing_generation']!,
          _processingGenerationMeta,
        ),
      );
    }
    if (data.containsKey('draft_json')) {
      context.handle(
        _draftJsonMeta,
        draftJson.isAcceptableOrUnknown(data['draft_json']!, _draftJsonMeta),
      );
    }
    if (data.containsKey('ocr_quality_json')) {
      context.handle(
        _ocrQualityJsonMeta,
        ocrQualityJson.isAcceptableOrUnknown(
          data['ocr_quality_json']!,
          _ocrQualityJsonMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('final_recipe_id')) {
      context.handle(
        _finalRecipeIdMeta,
        finalRecipeId.isAcceptableOrUnknown(
          data['final_recipe_id']!,
          _finalRecipeIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inputKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      originalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_text'],
      )!,
      sourceShareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_share_id'],
      ),
      detectedPublicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_public_url'],
      ),
      mediaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_json'],
      )!,
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      correctedOcrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_ocr_text'],
      ),
      supplementalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplemental_text'],
      )!,
      processingGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processing_generation'],
      )!,
      draftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_json'],
      ),
      ocrQualityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_quality_json'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      finalRecipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_recipe_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ImportTasksTable createAlias(String alias) {
    return $ImportTasksTable(attachedDatabase, alias);
  }
}

class ImportTask extends DataClass implements Insertable<ImportTask> {
  /// 导入任务稳定 UUID。
  final String id;

  /// 输入类型的稳定枚举字符串。
  final String inputKind;

  /// 当前业务状态的稳定枚举字符串。
  final String status;

  /// 用户粘贴或分享的完整原始文字；无文字时为空字符串。
  final String originalText;

  /// iOS 或 Android 系统分享的稳定 ID；手动创建的任务为空。
  final String? sourceShareId;

  /// 从原文识别出的公开 HTTPS 地址；未识别时为空。
  final String? detectedPublicUrl;

  /// 应用受控媒体引用的 JSON 数组；无图片时为 `[]`。
  final String mediaJson;

  /// 按当前页面顺序汇总的机器 OCR 文字；尚未识别时为空。
  final String? ocrText;

  /// 用户校对后的 OCR 正文；未校对时为空。
  final String? correctedOcrText;

  /// 用户在识别文字之外增加的补充说明。
  final String supplementalText;

  /// 任务内容变化的单调递增代次，过期处理结果不得回写。
  final int processingGeneration;

  /// 最新版本化结构草稿 JSON；尚未整理时为空。
  final String? draftJson;

  /// OCR 文字质量、建议状态和校对修订的版本化 JSON。
  final String ocrQualityJson;

  /// 稳定错误分类；非失败状态为空。
  final String? errorCode;

  /// 面向用户的错误说明；非失败状态为空。
  final String? errorMessage;

  /// 保存成功后的正式菜谱 ID；未保存时为空。
  final String? finalRecipeId;

  /// 任务首次持久化时间。
  final DateTime createdAt;

  /// 任务内容或状态最近更新时间。
  final DateTime updatedAt;
  const ImportTask({
    required this.id,
    required this.inputKind,
    required this.status,
    required this.originalText,
    this.sourceShareId,
    this.detectedPublicUrl,
    required this.mediaJson,
    this.ocrText,
    this.correctedOcrText,
    required this.supplementalText,
    required this.processingGeneration,
    this.draftJson,
    required this.ocrQualityJson,
    this.errorCode,
    this.errorMessage,
    this.finalRecipeId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['input_kind'] = Variable<String>(inputKind);
    map['status'] = Variable<String>(status);
    map['original_text'] = Variable<String>(originalText);
    if (!nullToAbsent || sourceShareId != null) {
      map['source_share_id'] = Variable<String>(sourceShareId);
    }
    if (!nullToAbsent || detectedPublicUrl != null) {
      map['detected_public_url'] = Variable<String>(detectedPublicUrl);
    }
    map['media_json'] = Variable<String>(mediaJson);
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    if (!nullToAbsent || correctedOcrText != null) {
      map['corrected_ocr_text'] = Variable<String>(correctedOcrText);
    }
    map['supplemental_text'] = Variable<String>(supplementalText);
    map['processing_generation'] = Variable<int>(processingGeneration);
    if (!nullToAbsent || draftJson != null) {
      map['draft_json'] = Variable<String>(draftJson);
    }
    map['ocr_quality_json'] = Variable<String>(ocrQualityJson);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || finalRecipeId != null) {
      map['final_recipe_id'] = Variable<String>(finalRecipeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ImportTasksCompanion toCompanion(bool nullToAbsent) {
    return ImportTasksCompanion(
      id: Value(id),
      inputKind: Value(inputKind),
      status: Value(status),
      originalText: Value(originalText),
      sourceShareId: sourceShareId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceShareId),
      detectedPublicUrl: detectedPublicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedPublicUrl),
      mediaJson: Value(mediaJson),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      correctedOcrText: correctedOcrText == null && nullToAbsent
          ? const Value.absent()
          : Value(correctedOcrText),
      supplementalText: Value(supplementalText),
      processingGeneration: Value(processingGeneration),
      draftJson: draftJson == null && nullToAbsent
          ? const Value.absent()
          : Value(draftJson),
      ocrQualityJson: Value(ocrQualityJson),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      finalRecipeId: finalRecipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(finalRecipeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ImportTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportTask(
      id: serializer.fromJson<String>(json['id']),
      inputKind: serializer.fromJson<String>(json['inputKind']),
      status: serializer.fromJson<String>(json['status']),
      originalText: serializer.fromJson<String>(json['originalText']),
      sourceShareId: serializer.fromJson<String?>(json['sourceShareId']),
      detectedPublicUrl: serializer.fromJson<String?>(
        json['detectedPublicUrl'],
      ),
      mediaJson: serializer.fromJson<String>(json['mediaJson']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      correctedOcrText: serializer.fromJson<String?>(json['correctedOcrText']),
      supplementalText: serializer.fromJson<String>(json['supplementalText']),
      processingGeneration: serializer.fromJson<int>(
        json['processingGeneration'],
      ),
      draftJson: serializer.fromJson<String?>(json['draftJson']),
      ocrQualityJson: serializer.fromJson<String>(json['ocrQualityJson']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      finalRecipeId: serializer.fromJson<String?>(json['finalRecipeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inputKind': serializer.toJson<String>(inputKind),
      'status': serializer.toJson<String>(status),
      'originalText': serializer.toJson<String>(originalText),
      'sourceShareId': serializer.toJson<String?>(sourceShareId),
      'detectedPublicUrl': serializer.toJson<String?>(detectedPublicUrl),
      'mediaJson': serializer.toJson<String>(mediaJson),
      'ocrText': serializer.toJson<String?>(ocrText),
      'correctedOcrText': serializer.toJson<String?>(correctedOcrText),
      'supplementalText': serializer.toJson<String>(supplementalText),
      'processingGeneration': serializer.toJson<int>(processingGeneration),
      'draftJson': serializer.toJson<String?>(draftJson),
      'ocrQualityJson': serializer.toJson<String>(ocrQualityJson),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'finalRecipeId': serializer.toJson<String?>(finalRecipeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ImportTask copyWith({
    String? id,
    String? inputKind,
    String? status,
    String? originalText,
    Value<String?> sourceShareId = const Value.absent(),
    Value<String?> detectedPublicUrl = const Value.absent(),
    String? mediaJson,
    Value<String?> ocrText = const Value.absent(),
    Value<String?> correctedOcrText = const Value.absent(),
    String? supplementalText,
    int? processingGeneration,
    Value<String?> draftJson = const Value.absent(),
    String? ocrQualityJson,
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> finalRecipeId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ImportTask(
    id: id ?? this.id,
    inputKind: inputKind ?? this.inputKind,
    status: status ?? this.status,
    originalText: originalText ?? this.originalText,
    sourceShareId: sourceShareId.present
        ? sourceShareId.value
        : this.sourceShareId,
    detectedPublicUrl: detectedPublicUrl.present
        ? detectedPublicUrl.value
        : this.detectedPublicUrl,
    mediaJson: mediaJson ?? this.mediaJson,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    correctedOcrText: correctedOcrText.present
        ? correctedOcrText.value
        : this.correctedOcrText,
    supplementalText: supplementalText ?? this.supplementalText,
    processingGeneration: processingGeneration ?? this.processingGeneration,
    draftJson: draftJson.present ? draftJson.value : this.draftJson,
    ocrQualityJson: ocrQualityJson ?? this.ocrQualityJson,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    finalRecipeId: finalRecipeId.present
        ? finalRecipeId.value
        : this.finalRecipeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ImportTask copyWithCompanion(ImportTasksCompanion data) {
    return ImportTask(
      id: data.id.present ? data.id.value : this.id,
      inputKind: data.inputKind.present ? data.inputKind.value : this.inputKind,
      status: data.status.present ? data.status.value : this.status,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      sourceShareId: data.sourceShareId.present
          ? data.sourceShareId.value
          : this.sourceShareId,
      detectedPublicUrl: data.detectedPublicUrl.present
          ? data.detectedPublicUrl.value
          : this.detectedPublicUrl,
      mediaJson: data.mediaJson.present ? data.mediaJson.value : this.mediaJson,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      correctedOcrText: data.correctedOcrText.present
          ? data.correctedOcrText.value
          : this.correctedOcrText,
      supplementalText: data.supplementalText.present
          ? data.supplementalText.value
          : this.supplementalText,
      processingGeneration: data.processingGeneration.present
          ? data.processingGeneration.value
          : this.processingGeneration,
      draftJson: data.draftJson.present ? data.draftJson.value : this.draftJson,
      ocrQualityJson: data.ocrQualityJson.present
          ? data.ocrQualityJson.value
          : this.ocrQualityJson,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      finalRecipeId: data.finalRecipeId.present
          ? data.finalRecipeId.value
          : this.finalRecipeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportTask(')
          ..write('id: $id, ')
          ..write('inputKind: $inputKind, ')
          ..write('status: $status, ')
          ..write('originalText: $originalText, ')
          ..write('sourceShareId: $sourceShareId, ')
          ..write('detectedPublicUrl: $detectedPublicUrl, ')
          ..write('mediaJson: $mediaJson, ')
          ..write('ocrText: $ocrText, ')
          ..write('correctedOcrText: $correctedOcrText, ')
          ..write('supplementalText: $supplementalText, ')
          ..write('processingGeneration: $processingGeneration, ')
          ..write('draftJson: $draftJson, ')
          ..write('ocrQualityJson: $ocrQualityJson, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('finalRecipeId: $finalRecipeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inputKind,
    status,
    originalText,
    sourceShareId,
    detectedPublicUrl,
    mediaJson,
    ocrText,
    correctedOcrText,
    supplementalText,
    processingGeneration,
    draftJson,
    ocrQualityJson,
    errorCode,
    errorMessage,
    finalRecipeId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportTask &&
          other.id == this.id &&
          other.inputKind == this.inputKind &&
          other.status == this.status &&
          other.originalText == this.originalText &&
          other.sourceShareId == this.sourceShareId &&
          other.detectedPublicUrl == this.detectedPublicUrl &&
          other.mediaJson == this.mediaJson &&
          other.ocrText == this.ocrText &&
          other.correctedOcrText == this.correctedOcrText &&
          other.supplementalText == this.supplementalText &&
          other.processingGeneration == this.processingGeneration &&
          other.draftJson == this.draftJson &&
          other.ocrQualityJson == this.ocrQualityJson &&
          other.errorCode == this.errorCode &&
          other.errorMessage == this.errorMessage &&
          other.finalRecipeId == this.finalRecipeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ImportTasksCompanion extends UpdateCompanion<ImportTask> {
  final Value<String> id;
  final Value<String> inputKind;
  final Value<String> status;
  final Value<String> originalText;
  final Value<String?> sourceShareId;
  final Value<String?> detectedPublicUrl;
  final Value<String> mediaJson;
  final Value<String?> ocrText;
  final Value<String?> correctedOcrText;
  final Value<String> supplementalText;
  final Value<int> processingGeneration;
  final Value<String?> draftJson;
  final Value<String> ocrQualityJson;
  final Value<String?> errorCode;
  final Value<String?> errorMessage;
  final Value<String?> finalRecipeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ImportTasksCompanion({
    this.id = const Value.absent(),
    this.inputKind = const Value.absent(),
    this.status = const Value.absent(),
    this.originalText = const Value.absent(),
    this.sourceShareId = const Value.absent(),
    this.detectedPublicUrl = const Value.absent(),
    this.mediaJson = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.correctedOcrText = const Value.absent(),
    this.supplementalText = const Value.absent(),
    this.processingGeneration = const Value.absent(),
    this.draftJson = const Value.absent(),
    this.ocrQualityJson = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.finalRecipeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportTasksCompanion.insert({
    required String id,
    required String inputKind,
    required String status,
    this.originalText = const Value.absent(),
    this.sourceShareId = const Value.absent(),
    this.detectedPublicUrl = const Value.absent(),
    this.mediaJson = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.correctedOcrText = const Value.absent(),
    this.supplementalText = const Value.absent(),
    this.processingGeneration = const Value.absent(),
    this.draftJson = const Value.absent(),
    this.ocrQualityJson = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.finalRecipeId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inputKind = Value(inputKind),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ImportTask> custom({
    Expression<String>? id,
    Expression<String>? inputKind,
    Expression<String>? status,
    Expression<String>? originalText,
    Expression<String>? sourceShareId,
    Expression<String>? detectedPublicUrl,
    Expression<String>? mediaJson,
    Expression<String>? ocrText,
    Expression<String>? correctedOcrText,
    Expression<String>? supplementalText,
    Expression<int>? processingGeneration,
    Expression<String>? draftJson,
    Expression<String>? ocrQualityJson,
    Expression<String>? errorCode,
    Expression<String>? errorMessage,
    Expression<String>? finalRecipeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inputKind != null) 'input_kind': inputKind,
      if (status != null) 'status': status,
      if (originalText != null) 'original_text': originalText,
      if (sourceShareId != null) 'source_share_id': sourceShareId,
      if (detectedPublicUrl != null) 'detected_public_url': detectedPublicUrl,
      if (mediaJson != null) 'media_json': mediaJson,
      if (ocrText != null) 'ocr_text': ocrText,
      if (correctedOcrText != null) 'corrected_ocr_text': correctedOcrText,
      if (supplementalText != null) 'supplemental_text': supplementalText,
      if (processingGeneration != null)
        'processing_generation': processingGeneration,
      if (draftJson != null) 'draft_json': draftJson,
      if (ocrQualityJson != null) 'ocr_quality_json': ocrQualityJson,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (finalRecipeId != null) 'final_recipe_id': finalRecipeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? inputKind,
    Value<String>? status,
    Value<String>? originalText,
    Value<String?>? sourceShareId,
    Value<String?>? detectedPublicUrl,
    Value<String>? mediaJson,
    Value<String?>? ocrText,
    Value<String?>? correctedOcrText,
    Value<String>? supplementalText,
    Value<int>? processingGeneration,
    Value<String?>? draftJson,
    Value<String>? ocrQualityJson,
    Value<String?>? errorCode,
    Value<String?>? errorMessage,
    Value<String?>? finalRecipeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ImportTasksCompanion(
      id: id ?? this.id,
      inputKind: inputKind ?? this.inputKind,
      status: status ?? this.status,
      originalText: originalText ?? this.originalText,
      sourceShareId: sourceShareId ?? this.sourceShareId,
      detectedPublicUrl: detectedPublicUrl ?? this.detectedPublicUrl,
      mediaJson: mediaJson ?? this.mediaJson,
      ocrText: ocrText ?? this.ocrText,
      correctedOcrText: correctedOcrText ?? this.correctedOcrText,
      supplementalText: supplementalText ?? this.supplementalText,
      processingGeneration: processingGeneration ?? this.processingGeneration,
      draftJson: draftJson ?? this.draftJson,
      ocrQualityJson: ocrQualityJson ?? this.ocrQualityJson,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      finalRecipeId: finalRecipeId ?? this.finalRecipeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inputKind.present) {
      map['input_kind'] = Variable<String>(inputKind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (sourceShareId.present) {
      map['source_share_id'] = Variable<String>(sourceShareId.value);
    }
    if (detectedPublicUrl.present) {
      map['detected_public_url'] = Variable<String>(detectedPublicUrl.value);
    }
    if (mediaJson.present) {
      map['media_json'] = Variable<String>(mediaJson.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (correctedOcrText.present) {
      map['corrected_ocr_text'] = Variable<String>(correctedOcrText.value);
    }
    if (supplementalText.present) {
      map['supplemental_text'] = Variable<String>(supplementalText.value);
    }
    if (processingGeneration.present) {
      map['processing_generation'] = Variable<int>(processingGeneration.value);
    }
    if (draftJson.present) {
      map['draft_json'] = Variable<String>(draftJson.value);
    }
    if (ocrQualityJson.present) {
      map['ocr_quality_json'] = Variable<String>(ocrQualityJson.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (finalRecipeId.present) {
      map['final_recipe_id'] = Variable<String>(finalRecipeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportTasksCompanion(')
          ..write('id: $id, ')
          ..write('inputKind: $inputKind, ')
          ..write('status: $status, ')
          ..write('originalText: $originalText, ')
          ..write('sourceShareId: $sourceShareId, ')
          ..write('detectedPublicUrl: $detectedPublicUrl, ')
          ..write('mediaJson: $mediaJson, ')
          ..write('ocrText: $ocrText, ')
          ..write('correctedOcrText: $correctedOcrText, ')
          ..write('supplementalText: $supplementalText, ')
          ..write('processingGeneration: $processingGeneration, ')
          ..write('draftJson: $draftJson, ')
          ..write('ocrQualityJson: $ocrQualityJson, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('finalRecipeId: $finalRecipeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ImportAppDatabase extends GeneratedDatabase {
  _$ImportAppDatabase(QueryExecutor e) : super(e);
  $ImportAppDatabaseManager get managers => $ImportAppDatabaseManager(this);
  late final $ImportTasksTable importTasks = $ImportTasksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [importTasks];
}

typedef $$ImportTasksTableCreateCompanionBuilder =
    ImportTasksCompanion Function({
      required String id,
      required String inputKind,
      required String status,
      Value<String> originalText,
      Value<String?> sourceShareId,
      Value<String?> detectedPublicUrl,
      Value<String> mediaJson,
      Value<String?> ocrText,
      Value<String?> correctedOcrText,
      Value<String> supplementalText,
      Value<int> processingGeneration,
      Value<String?> draftJson,
      Value<String> ocrQualityJson,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<String?> finalRecipeId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ImportTasksTableUpdateCompanionBuilder =
    ImportTasksCompanion Function({
      Value<String> id,
      Value<String> inputKind,
      Value<String> status,
      Value<String> originalText,
      Value<String?> sourceShareId,
      Value<String?> detectedPublicUrl,
      Value<String> mediaJson,
      Value<String?> ocrText,
      Value<String?> correctedOcrText,
      Value<String> supplementalText,
      Value<int> processingGeneration,
      Value<String?> draftJson,
      Value<String> ocrQualityJson,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<String?> finalRecipeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ImportTasksTableFilterComposer
    extends Composer<_$ImportAppDatabase, $ImportTasksTable> {
  $$ImportTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputKind => $composableBuilder(
    column: $table.inputKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceShareId => $composableBuilder(
    column: $table.sourceShareId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectedPublicUrl => $composableBuilder(
    column: $table.detectedPublicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaJson => $composableBuilder(
    column: $table.mediaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctedOcrText => $composableBuilder(
    column: $table.correctedOcrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplementalText => $composableBuilder(
    column: $table.supplementalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processingGeneration => $composableBuilder(
    column: $table.processingGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftJson => $composableBuilder(
    column: $table.draftJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrQualityJson => $composableBuilder(
    column: $table.ocrQualityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalRecipeId => $composableBuilder(
    column: $table.finalRecipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportTasksTableOrderingComposer
    extends Composer<_$ImportAppDatabase, $ImportTasksTable> {
  $$ImportTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputKind => $composableBuilder(
    column: $table.inputKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceShareId => $composableBuilder(
    column: $table.sourceShareId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectedPublicUrl => $composableBuilder(
    column: $table.detectedPublicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaJson => $composableBuilder(
    column: $table.mediaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctedOcrText => $composableBuilder(
    column: $table.correctedOcrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplementalText => $composableBuilder(
    column: $table.supplementalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processingGeneration => $composableBuilder(
    column: $table.processingGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftJson => $composableBuilder(
    column: $table.draftJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrQualityJson => $composableBuilder(
    column: $table.ocrQualityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalRecipeId => $composableBuilder(
    column: $table.finalRecipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportTasksTableAnnotationComposer
    extends Composer<_$ImportAppDatabase, $ImportTasksTable> {
  $$ImportTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inputKind =>
      $composableBuilder(column: $table.inputKind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceShareId => $composableBuilder(
    column: $table.sourceShareId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detectedPublicUrl => $composableBuilder(
    column: $table.detectedPublicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaJson =>
      $composableBuilder(column: $table.mediaJson, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get correctedOcrText => $composableBuilder(
    column: $table.correctedOcrText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplementalText => $composableBuilder(
    column: $table.supplementalText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get processingGeneration => $composableBuilder(
    column: $table.processingGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get draftJson =>
      $composableBuilder(column: $table.draftJson, builder: (column) => column);

  GeneratedColumn<String> get ocrQualityJson => $composableBuilder(
    column: $table.ocrQualityJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalRecipeId => $composableBuilder(
    column: $table.finalRecipeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ImportTasksTableTableManager
    extends
        RootTableManager<
          _$ImportAppDatabase,
          $ImportTasksTable,
          ImportTask,
          $$ImportTasksTableFilterComposer,
          $$ImportTasksTableOrderingComposer,
          $$ImportTasksTableAnnotationComposer,
          $$ImportTasksTableCreateCompanionBuilder,
          $$ImportTasksTableUpdateCompanionBuilder,
          (
            ImportTask,
            BaseReferences<_$ImportAppDatabase, $ImportTasksTable, ImportTask>,
          ),
          ImportTask,
          PrefetchHooks Function()
        > {
  $$ImportTasksTableTableManager(
    _$ImportAppDatabase db,
    $ImportTasksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inputKind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> originalText = const Value.absent(),
                Value<String?> sourceShareId = const Value.absent(),
                Value<String?> detectedPublicUrl = const Value.absent(),
                Value<String> mediaJson = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> correctedOcrText = const Value.absent(),
                Value<String> supplementalText = const Value.absent(),
                Value<int> processingGeneration = const Value.absent(),
                Value<String?> draftJson = const Value.absent(),
                Value<String> ocrQualityJson = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> finalRecipeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportTasksCompanion(
                id: id,
                inputKind: inputKind,
                status: status,
                originalText: originalText,
                sourceShareId: sourceShareId,
                detectedPublicUrl: detectedPublicUrl,
                mediaJson: mediaJson,
                ocrText: ocrText,
                correctedOcrText: correctedOcrText,
                supplementalText: supplementalText,
                processingGeneration: processingGeneration,
                draftJson: draftJson,
                ocrQualityJson: ocrQualityJson,
                errorCode: errorCode,
                errorMessage: errorMessage,
                finalRecipeId: finalRecipeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inputKind,
                required String status,
                Value<String> originalText = const Value.absent(),
                Value<String?> sourceShareId = const Value.absent(),
                Value<String?> detectedPublicUrl = const Value.absent(),
                Value<String> mediaJson = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> correctedOcrText = const Value.absent(),
                Value<String> supplementalText = const Value.absent(),
                Value<int> processingGeneration = const Value.absent(),
                Value<String?> draftJson = const Value.absent(),
                Value<String> ocrQualityJson = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> finalRecipeId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportTasksCompanion.insert(
                id: id,
                inputKind: inputKind,
                status: status,
                originalText: originalText,
                sourceShareId: sourceShareId,
                detectedPublicUrl: detectedPublicUrl,
                mediaJson: mediaJson,
                ocrText: ocrText,
                correctedOcrText: correctedOcrText,
                supplementalText: supplementalText,
                processingGeneration: processingGeneration,
                draftJson: draftJson,
                ocrQualityJson: ocrQualityJson,
                errorCode: errorCode,
                errorMessage: errorMessage,
                finalRecipeId: finalRecipeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$ImportAppDatabase,
      $ImportTasksTable,
      ImportTask,
      $$ImportTasksTableFilterComposer,
      $$ImportTasksTableOrderingComposer,
      $$ImportTasksTableAnnotationComposer,
      $$ImportTasksTableCreateCompanionBuilder,
      $$ImportTasksTableUpdateCompanionBuilder,
      (
        ImportTask,
        BaseReferences<_$ImportAppDatabase, $ImportTasksTable, ImportTask>,
      ),
      ImportTask,
      PrefetchHooks Function()
    >;

class $ImportAppDatabaseManager {
  final _$ImportAppDatabase _db;
  $ImportAppDatabaseManager(this._db);
  $$ImportTasksTableTableManager get importTasks =>
      $$ImportTasksTableTableManager(_db, _db.importTasks);
}
