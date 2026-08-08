// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_recipe_data_app_database.dart';

// ignore_for_file: type=lint
class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('家常菜'),
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prepMinutesMeta = const VerificationMeta(
    'prepMinutes',
  );
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
    'prep_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cookMinutesMeta = const VerificationMeta(
    'cookMinutes',
  );
  @override
  late final GeneratedColumn<int> cookMinutes = GeneratedColumn<int>(
    'cook_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('简单'),
  );
  static const VerificationMeta _presentationStyleMeta = const VerificationMeta(
    'presentationStyle',
  );
  @override
  late final GeneratedColumn<String> presentationStyle =
      GeneratedColumn<String>(
        'presentation_style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('inheritDefault'),
      );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('builtin.journal.basic'),
  );
  static const VerificationMeta _templateVersionMeta = const VerificationMeta(
    'templateVersion',
  );
  @override
  late final GeneratedColumn<int> templateVersion = GeneratedColumn<int>(
    'template_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastCookedAtMeta = const VerificationMeta(
    'lastCookedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCookedAt = GeneratedColumn<DateTime>(
    'last_cooked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cookCountMeta = const VerificationMeta(
    'cookCount',
  );
  @override
  late final GeneratedColumn<int> cookCount = GeneratedColumn<int>(
    'cook_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ready'),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusBeforeDeletionMeta =
      const VerificationMeta('statusBeforeDeletion');
  @override
  late final GeneratedColumn<String> statusBeforeDeletion =
      GeneratedColumn<String>(
        'status_before_deletion',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _coverColorMeta = const VerificationMeta(
    'coverColor',
  );
  @override
  late final GeneratedColumn<int> coverColor = GeneratedColumn<int>(
    'cover_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _importTaskIdMeta = const VerificationMeta(
    'importTaskId',
  );
  @override
  late final GeneratedColumn<String> importTaskId = GeneratedColumn<String>(
    'import_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sourceOriginalTextMeta =
      const VerificationMeta('sourceOriginalText');
  @override
  late final GeneratedColumn<String> sourceOriginalText =
      GeneratedColumn<String>(
        'source_original_text',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourcePublicUrlMeta = const VerificationMeta(
    'sourcePublicUrl',
  );
  @override
  late final GeneratedColumn<String> sourcePublicUrl = GeneratedColumn<String>(
    'source_public_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    summary,
    category,
    servings,
    prepMinutes,
    cookMinutes,
    difficulty,
    presentationStyle,
    templateId,
    templateVersion,
    isFavorite,
    lastCookedAt,
    cookCount,
    status,
    deletedAt,
    statusBeforeDeletion,
    coverColor,
    createdAt,
    updatedAt,
    importTaskId,
    sourceOriginalText,
    sourcePublicUrl,
    sourceTitle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
        _prepMinutesMeta,
        prepMinutes.isAcceptableOrUnknown(
          data['prep_minutes']!,
          _prepMinutesMeta,
        ),
      );
    }
    if (data.containsKey('cook_minutes')) {
      context.handle(
        _cookMinutesMeta,
        cookMinutes.isAcceptableOrUnknown(
          data['cook_minutes']!,
          _cookMinutesMeta,
        ),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('presentation_style')) {
      context.handle(
        _presentationStyleMeta,
        presentationStyle.isAcceptableOrUnknown(
          data['presentation_style']!,
          _presentationStyleMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('template_version')) {
      context.handle(
        _templateVersionMeta,
        templateVersion.isAcceptableOrUnknown(
          data['template_version']!,
          _templateVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('last_cooked_at')) {
      context.handle(
        _lastCookedAtMeta,
        lastCookedAt.isAcceptableOrUnknown(
          data['last_cooked_at']!,
          _lastCookedAtMeta,
        ),
      );
    }
    if (data.containsKey('cook_count')) {
      context.handle(
        _cookCountMeta,
        cookCount.isAcceptableOrUnknown(data['cook_count']!, _cookCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('status_before_deletion')) {
      context.handle(
        _statusBeforeDeletionMeta,
        statusBeforeDeletion.isAcceptableOrUnknown(
          data['status_before_deletion']!,
          _statusBeforeDeletionMeta,
        ),
      );
    }
    if (data.containsKey('cover_color')) {
      context.handle(
        _coverColorMeta,
        coverColor.isAcceptableOrUnknown(data['cover_color']!, _coverColorMeta),
      );
    } else if (isInserting) {
      context.missing(_coverColorMeta);
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
    if (data.containsKey('import_task_id')) {
      context.handle(
        _importTaskIdMeta,
        importTaskId.isAcceptableOrUnknown(
          data['import_task_id']!,
          _importTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('source_original_text')) {
      context.handle(
        _sourceOriginalTextMeta,
        sourceOriginalText.isAcceptableOrUnknown(
          data['source_original_text']!,
          _sourceOriginalTextMeta,
        ),
      );
    }
    if (data.containsKey('source_public_url')) {
      context.handle(
        _sourcePublicUrlMeta,
        sourcePublicUrl.isAcceptableOrUnknown(
          data['source_public_url']!,
          _sourcePublicUrlMeta,
        ),
      );
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      ),
      prepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_minutes'],
      ),
      cookMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cook_minutes'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      presentationStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation_style'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templateVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_version'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lastCookedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_cooked_at'],
      ),
      cookCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cook_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      statusBeforeDeletion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_before_deletion'],
      ),
      coverColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      importTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_task_id'],
      ),
      sourceOriginalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_original_text'],
      ),
      sourcePublicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_public_url'],
      ),
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      ),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  /// 菜谱主键，由 Repository 生成 UUID。
  final String id;

  /// 菜谱名称，数据库限制为 1～120 个字符。
  final String title;

  /// 菜谱简介；未填写时保存为空字符串。
  final String summary;

  /// 唯一主分类；未指定时使用“家常菜”。
  final String category;

  /// 适用人数；尚未填写时为空。
  final int? servings;

  /// 食材准备时间，单位为分钟；尚未填写时为空。
  final int? prepMinutes;

  /// 实际烹饪时间，单位为分钟；尚未填写时为空。
  final int? cookMinutes;

  /// 面向用户展示的难度名称。
  final String difficulty;

  /// 菜谱的视觉风格标识；默认继承用户的全局选择。
  final String presentationStyle;

  /// 固定到本菜谱的模板标识。
  final String templateId;

  /// 固定到本菜谱的模板版本。
  final int templateVersion;

  /// 用户是否已收藏该菜谱。
  final bool isFavorite;

  /// 历史烹饪时间列；仅为旧版 SQLite 兼容保留，新代码不读写。
  final DateTime? lastCookedAt;

  /// 历史烹饪次数列；仅为旧版 SQLite 兼容保留，新代码不读写。
  final int cookCount;

  /// 菜谱生命周期状态的稳定字符串值。
  final String status;

  /// 移入回收站的时间；未删除菜谱为空。
  final DateTime? deletedAt;

  /// 删除前生命周期状态；恢复完成后清空。
  final String? statusBeforeDeletion;

  /// 默认封面使用的 ARGB 颜色整数。
  final int coverColor;

  /// 菜谱首次创建时间。
  final DateTime createdAt;

  /// 菜谱内容或状态最近更新时间，用于默认排序。
  final DateTime updatedAt;

  /// 生成本菜谱的导入任务 ID；手动创建时为空，非空值全库唯一。
  final String? importTaskId;

  /// 导入时保存的原始来源文字；手动创建或没有来源时为空。
  final String? sourceOriginalText;

  /// 导入来源的公开 HTTPS 地址；没有链接时为空。
  final String? sourcePublicUrl;

  /// 导入来源标题；未提取成功时为空。
  final String? sourceTitle;
  const Recipe({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    this.servings,
    this.prepMinutes,
    this.cookMinutes,
    required this.difficulty,
    required this.presentationStyle,
    required this.templateId,
    required this.templateVersion,
    required this.isFavorite,
    this.lastCookedAt,
    required this.cookCount,
    required this.status,
    this.deletedAt,
    this.statusBeforeDeletion,
    required this.coverColor,
    required this.createdAt,
    required this.updatedAt,
    this.importTaskId,
    this.sourceOriginalText,
    this.sourcePublicUrl,
    this.sourceTitle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || servings != null) {
      map['servings'] = Variable<int>(servings);
    }
    if (!nullToAbsent || prepMinutes != null) {
      map['prep_minutes'] = Variable<int>(prepMinutes);
    }
    if (!nullToAbsent || cookMinutes != null) {
      map['cook_minutes'] = Variable<int>(cookMinutes);
    }
    map['difficulty'] = Variable<String>(difficulty);
    map['presentation_style'] = Variable<String>(presentationStyle);
    map['template_id'] = Variable<String>(templateId);
    map['template_version'] = Variable<int>(templateVersion);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lastCookedAt != null) {
      map['last_cooked_at'] = Variable<DateTime>(lastCookedAt);
    }
    map['cook_count'] = Variable<int>(cookCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || statusBeforeDeletion != null) {
      map['status_before_deletion'] = Variable<String>(statusBeforeDeletion);
    }
    map['cover_color'] = Variable<int>(coverColor);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || importTaskId != null) {
      map['import_task_id'] = Variable<String>(importTaskId);
    }
    if (!nullToAbsent || sourceOriginalText != null) {
      map['source_original_text'] = Variable<String>(sourceOriginalText);
    }
    if (!nullToAbsent || sourcePublicUrl != null) {
      map['source_public_url'] = Variable<String>(sourcePublicUrl);
    }
    if (!nullToAbsent || sourceTitle != null) {
      map['source_title'] = Variable<String>(sourceTitle);
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      title: Value(title),
      summary: Value(summary),
      category: Value(category),
      servings: servings == null && nullToAbsent
          ? const Value.absent()
          : Value(servings),
      prepMinutes: prepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(prepMinutes),
      cookMinutes: cookMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(cookMinutes),
      difficulty: Value(difficulty),
      presentationStyle: Value(presentationStyle),
      templateId: Value(templateId),
      templateVersion: Value(templateVersion),
      isFavorite: Value(isFavorite),
      lastCookedAt: lastCookedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCookedAt),
      cookCount: Value(cookCount),
      status: Value(status),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      statusBeforeDeletion: statusBeforeDeletion == null && nullToAbsent
          ? const Value.absent()
          : Value(statusBeforeDeletion),
      coverColor: Value(coverColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      importTaskId: importTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(importTaskId),
      sourceOriginalText: sourceOriginalText == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceOriginalText),
      sourcePublicUrl: sourcePublicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePublicUrl),
      sourceTitle: sourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTitle),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      category: serializer.fromJson<String>(json['category']),
      servings: serializer.fromJson<int?>(json['servings']),
      prepMinutes: serializer.fromJson<int?>(json['prepMinutes']),
      cookMinutes: serializer.fromJson<int?>(json['cookMinutes']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      presentationStyle: serializer.fromJson<String>(json['presentationStyle']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templateVersion: serializer.fromJson<int>(json['templateVersion']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastCookedAt: serializer.fromJson<DateTime?>(json['lastCookedAt']),
      cookCount: serializer.fromJson<int>(json['cookCount']),
      status: serializer.fromJson<String>(json['status']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      statusBeforeDeletion: serializer.fromJson<String?>(
        json['statusBeforeDeletion'],
      ),
      coverColor: serializer.fromJson<int>(json['coverColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      importTaskId: serializer.fromJson<String?>(json['importTaskId']),
      sourceOriginalText: serializer.fromJson<String?>(
        json['sourceOriginalText'],
      ),
      sourcePublicUrl: serializer.fromJson<String?>(json['sourcePublicUrl']),
      sourceTitle: serializer.fromJson<String?>(json['sourceTitle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'category': serializer.toJson<String>(category),
      'servings': serializer.toJson<int?>(servings),
      'prepMinutes': serializer.toJson<int?>(prepMinutes),
      'cookMinutes': serializer.toJson<int?>(cookMinutes),
      'difficulty': serializer.toJson<String>(difficulty),
      'presentationStyle': serializer.toJson<String>(presentationStyle),
      'templateId': serializer.toJson<String>(templateId),
      'templateVersion': serializer.toJson<int>(templateVersion),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastCookedAt': serializer.toJson<DateTime?>(lastCookedAt),
      'cookCount': serializer.toJson<int>(cookCount),
      'status': serializer.toJson<String>(status),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'statusBeforeDeletion': serializer.toJson<String?>(statusBeforeDeletion),
      'coverColor': serializer.toJson<int>(coverColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'importTaskId': serializer.toJson<String?>(importTaskId),
      'sourceOriginalText': serializer.toJson<String?>(sourceOriginalText),
      'sourcePublicUrl': serializer.toJson<String?>(sourcePublicUrl),
      'sourceTitle': serializer.toJson<String?>(sourceTitle),
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? summary,
    String? category,
    Value<int?> servings = const Value.absent(),
    Value<int?> prepMinutes = const Value.absent(),
    Value<int?> cookMinutes = const Value.absent(),
    String? difficulty,
    String? presentationStyle,
    String? templateId,
    int? templateVersion,
    bool? isFavorite,
    Value<DateTime?> lastCookedAt = const Value.absent(),
    int? cookCount,
    String? status,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> statusBeforeDeletion = const Value.absent(),
    int? coverColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> importTaskId = const Value.absent(),
    Value<String?> sourceOriginalText = const Value.absent(),
    Value<String?> sourcePublicUrl = const Value.absent(),
    Value<String?> sourceTitle = const Value.absent(),
  }) => Recipe(
    id: id ?? this.id,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    category: category ?? this.category,
    servings: servings.present ? servings.value : this.servings,
    prepMinutes: prepMinutes.present ? prepMinutes.value : this.prepMinutes,
    cookMinutes: cookMinutes.present ? cookMinutes.value : this.cookMinutes,
    difficulty: difficulty ?? this.difficulty,
    presentationStyle: presentationStyle ?? this.presentationStyle,
    templateId: templateId ?? this.templateId,
    templateVersion: templateVersion ?? this.templateVersion,
    isFavorite: isFavorite ?? this.isFavorite,
    lastCookedAt: lastCookedAt.present ? lastCookedAt.value : this.lastCookedAt,
    cookCount: cookCount ?? this.cookCount,
    status: status ?? this.status,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    statusBeforeDeletion: statusBeforeDeletion.present
        ? statusBeforeDeletion.value
        : this.statusBeforeDeletion,
    coverColor: coverColor ?? this.coverColor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    importTaskId: importTaskId.present ? importTaskId.value : this.importTaskId,
    sourceOriginalText: sourceOriginalText.present
        ? sourceOriginalText.value
        : this.sourceOriginalText,
    sourcePublicUrl: sourcePublicUrl.present
        ? sourcePublicUrl.value
        : this.sourcePublicUrl,
    sourceTitle: sourceTitle.present ? sourceTitle.value : this.sourceTitle,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      category: data.category.present ? data.category.value : this.category,
      servings: data.servings.present ? data.servings.value : this.servings,
      prepMinutes: data.prepMinutes.present
          ? data.prepMinutes.value
          : this.prepMinutes,
      cookMinutes: data.cookMinutes.present
          ? data.cookMinutes.value
          : this.cookMinutes,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      presentationStyle: data.presentationStyle.present
          ? data.presentationStyle.value
          : this.presentationStyle,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateVersion: data.templateVersion.present
          ? data.templateVersion.value
          : this.templateVersion,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lastCookedAt: data.lastCookedAt.present
          ? data.lastCookedAt.value
          : this.lastCookedAt,
      cookCount: data.cookCount.present ? data.cookCount.value : this.cookCount,
      status: data.status.present ? data.status.value : this.status,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      statusBeforeDeletion: data.statusBeforeDeletion.present
          ? data.statusBeforeDeletion.value
          : this.statusBeforeDeletion,
      coverColor: data.coverColor.present
          ? data.coverColor.value
          : this.coverColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      importTaskId: data.importTaskId.present
          ? data.importTaskId.value
          : this.importTaskId,
      sourceOriginalText: data.sourceOriginalText.present
          ? data.sourceOriginalText.value
          : this.sourceOriginalText,
      sourcePublicUrl: data.sourcePublicUrl.present
          ? data.sourcePublicUrl.value
          : this.sourcePublicUrl,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('category: $category, ')
          ..write('servings: $servings, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('presentationStyle: $presentationStyle, ')
          ..write('templateId: $templateId, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastCookedAt: $lastCookedAt, ')
          ..write('cookCount: $cookCount, ')
          ..write('status: $status, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('statusBeforeDeletion: $statusBeforeDeletion, ')
          ..write('coverColor: $coverColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('importTaskId: $importTaskId, ')
          ..write('sourceOriginalText: $sourceOriginalText, ')
          ..write('sourcePublicUrl: $sourcePublicUrl, ')
          ..write('sourceTitle: $sourceTitle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    summary,
    category,
    servings,
    prepMinutes,
    cookMinutes,
    difficulty,
    presentationStyle,
    templateId,
    templateVersion,
    isFavorite,
    lastCookedAt,
    cookCount,
    status,
    deletedAt,
    statusBeforeDeletion,
    coverColor,
    createdAt,
    updatedAt,
    importTaskId,
    sourceOriginalText,
    sourcePublicUrl,
    sourceTitle,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.category == this.category &&
          other.servings == this.servings &&
          other.prepMinutes == this.prepMinutes &&
          other.cookMinutes == this.cookMinutes &&
          other.difficulty == this.difficulty &&
          other.presentationStyle == this.presentationStyle &&
          other.templateId == this.templateId &&
          other.templateVersion == this.templateVersion &&
          other.isFavorite == this.isFavorite &&
          other.lastCookedAt == this.lastCookedAt &&
          other.cookCount == this.cookCount &&
          other.status == this.status &&
          other.deletedAt == this.deletedAt &&
          other.statusBeforeDeletion == this.statusBeforeDeletion &&
          other.coverColor == this.coverColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.importTaskId == this.importTaskId &&
          other.sourceOriginalText == this.sourceOriginalText &&
          other.sourcePublicUrl == this.sourcePublicUrl &&
          other.sourceTitle == this.sourceTitle);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> category;
  final Value<int?> servings;
  final Value<int?> prepMinutes;
  final Value<int?> cookMinutes;
  final Value<String> difficulty;
  final Value<String> presentationStyle;
  final Value<String> templateId;
  final Value<int> templateVersion;
  final Value<bool> isFavorite;
  final Value<DateTime?> lastCookedAt;
  final Value<int> cookCount;
  final Value<String> status;
  final Value<DateTime?> deletedAt;
  final Value<String?> statusBeforeDeletion;
  final Value<int> coverColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> importTaskId;
  final Value<String?> sourceOriginalText;
  final Value<String?> sourcePublicUrl;
  final Value<String?> sourceTitle;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.category = const Value.absent(),
    this.servings = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.presentationStyle = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastCookedAt = const Value.absent(),
    this.cookCount = const Value.absent(),
    this.status = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.statusBeforeDeletion = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.importTaskId = const Value.absent(),
    this.sourceOriginalText = const Value.absent(),
    this.sourcePublicUrl = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required String title,
    this.summary = const Value.absent(),
    this.category = const Value.absent(),
    this.servings = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.presentationStyle = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastCookedAt = const Value.absent(),
    this.cookCount = const Value.absent(),
    this.status = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.statusBeforeDeletion = const Value.absent(),
    required int coverColor,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.importTaskId = const Value.absent(),
    this.sourceOriginalText = const Value.absent(),
    this.sourcePublicUrl = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       coverColor = Value(coverColor),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Recipe> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? category,
    Expression<int>? servings,
    Expression<int>? prepMinutes,
    Expression<int>? cookMinutes,
    Expression<String>? difficulty,
    Expression<String>? presentationStyle,
    Expression<String>? templateId,
    Expression<int>? templateVersion,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastCookedAt,
    Expression<int>? cookCount,
    Expression<String>? status,
    Expression<DateTime>? deletedAt,
    Expression<String>? statusBeforeDeletion,
    Expression<int>? coverColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? importTaskId,
    Expression<String>? sourceOriginalText,
    Expression<String>? sourcePublicUrl,
    Expression<String>? sourceTitle,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (category != null) 'category': category,
      if (servings != null) 'servings': servings,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (cookMinutes != null) 'cook_minutes': cookMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      if (presentationStyle != null) 'presentation_style': presentationStyle,
      if (templateId != null) 'template_id': templateId,
      if (templateVersion != null) 'template_version': templateVersion,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastCookedAt != null) 'last_cooked_at': lastCookedAt,
      if (cookCount != null) 'cook_count': cookCount,
      if (status != null) 'status': status,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (statusBeforeDeletion != null)
        'status_before_deletion': statusBeforeDeletion,
      if (coverColor != null) 'cover_color': coverColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (importTaskId != null) 'import_task_id': importTaskId,
      if (sourceOriginalText != null)
        'source_original_text': sourceOriginalText,
      if (sourcePublicUrl != null) 'source_public_url': sourcePublicUrl,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? category,
    Value<int?>? servings,
    Value<int?>? prepMinutes,
    Value<int?>? cookMinutes,
    Value<String>? difficulty,
    Value<String>? presentationStyle,
    Value<String>? templateId,
    Value<int>? templateVersion,
    Value<bool>? isFavorite,
    Value<DateTime?>? lastCookedAt,
    Value<int>? cookCount,
    Value<String>? status,
    Value<DateTime?>? deletedAt,
    Value<String?>? statusBeforeDeletion,
    Value<int>? coverColor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? importTaskId,
    Value<String?>? sourceOriginalText,
    Value<String?>? sourcePublicUrl,
    Value<String?>? sourceTitle,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      servings: servings ?? this.servings,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      difficulty: difficulty ?? this.difficulty,
      presentationStyle: presentationStyle ?? this.presentationStyle,
      templateId: templateId ?? this.templateId,
      templateVersion: templateVersion ?? this.templateVersion,
      isFavorite: isFavorite ?? this.isFavorite,
      lastCookedAt: lastCookedAt ?? this.lastCookedAt,
      cookCount: cookCount ?? this.cookCount,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      statusBeforeDeletion: statusBeforeDeletion ?? this.statusBeforeDeletion,
      coverColor: coverColor ?? this.coverColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      importTaskId: importTaskId ?? this.importTaskId,
      sourceOriginalText: sourceOriginalText ?? this.sourceOriginalText,
      sourcePublicUrl: sourcePublicUrl ?? this.sourcePublicUrl,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (cookMinutes.present) {
      map['cook_minutes'] = Variable<int>(cookMinutes.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (presentationStyle.present) {
      map['presentation_style'] = Variable<String>(presentationStyle.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateVersion.present) {
      map['template_version'] = Variable<int>(templateVersion.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastCookedAt.present) {
      map['last_cooked_at'] = Variable<DateTime>(lastCookedAt.value);
    }
    if (cookCount.present) {
      map['cook_count'] = Variable<int>(cookCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (statusBeforeDeletion.present) {
      map['status_before_deletion'] = Variable<String>(
        statusBeforeDeletion.value,
      );
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<int>(coverColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (importTaskId.present) {
      map['import_task_id'] = Variable<String>(importTaskId.value);
    }
    if (sourceOriginalText.present) {
      map['source_original_text'] = Variable<String>(sourceOriginalText.value);
    }
    if (sourcePublicUrl.present) {
      map['source_public_url'] = Variable<String>(sourcePublicUrl.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('category: $category, ')
          ..write('servings: $servings, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('presentationStyle: $presentationStyle, ')
          ..write('templateId: $templateId, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastCookedAt: $lastCookedAt, ')
          ..write('cookCount: $cookCount, ')
          ..write('status: $status, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('statusBeforeDeletion: $statusBeforeDeletion, ')
          ..write('coverColor: $coverColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('importTaskId: $importTaskId, ')
          ..write('sourceOriginalText: $sourceOriginalText, ')
          ..write('sourcePublicUrl: $sourcePublicUrl, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountTextMeta = const VerificationMeta(
    'amountText',
  );
  @override
  late final GeneratedColumn<String> amountText = GeneratedColumn<String>(
    'amount_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('适量'),
  );
  static const VerificationMeta _amountValueMeta = const VerificationMeta(
    'amountValue',
  );
  @override
  late final GeneratedColumn<double> amountValue = GeneratedColumn<double>(
    'amount_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preparationMeta = const VerificationMeta(
    'preparation',
  );
  @override
  late final GeneratedColumn<String> preparation = GeneratedColumn<String>(
    'preparation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOptionalMeta = const VerificationMeta(
    'isOptional',
  );
  @override
  late final GeneratedColumn<bool> isOptional = GeneratedColumn<bool>(
    'is_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_optional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    name,
    amountText,
    amountValue,
    unit,
    preparation,
    isOptional,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_text')) {
      context.handle(
        _amountTextMeta,
        amountText.isAcceptableOrUnknown(data['amount_text']!, _amountTextMeta),
      );
    }
    if (data.containsKey('amount_value')) {
      context.handle(
        _amountValueMeta,
        amountValue.isAcceptableOrUnknown(
          data['amount_value']!,
          _amountValueMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('preparation')) {
      context.handle(
        _preparationMeta,
        preparation.isAcceptableOrUnknown(
          data['preparation']!,
          _preparationMeta,
        ),
      );
    }
    if (data.containsKey('is_optional')) {
      context.handle(
        _isOptionalMeta,
        isOptional.isAcceptableOrUnknown(data['is_optional']!, _isOptionalMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_text'],
      )!,
      amountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_value'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      preparation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preparation'],
      ),
      isOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_optional'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  /// 食材记录主键。
  final String id;

  /// 所属菜谱 ID；删除菜谱时级联删除食材。
  final String recipeId;

  /// 食材名称。
  final String name;

  /// 面向用户展示的完整用量文本。
  final String amountText;

  /// 可参与份量换算的数值；无法量化时为空。
  final double? amountValue;

  /// 结构化计量单位；未解析出单位时为空。
  final String? unit;

  /// 使用前的处理方式；未填写时为空。
  final String? preparation;

  /// 是否属于可以省略的食材。
  final bool isOptional;

  /// 食材在菜谱中的零基排序位置。
  final int position;
  const Ingredient({
    required this.id,
    required this.recipeId,
    required this.name,
    required this.amountText,
    this.amountValue,
    this.unit,
    this.preparation,
    required this.isOptional,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['name'] = Variable<String>(name);
    map['amount_text'] = Variable<String>(amountText);
    if (!nullToAbsent || amountValue != null) {
      map['amount_value'] = Variable<double>(amountValue);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || preparation != null) {
      map['preparation'] = Variable<String>(preparation);
    }
    map['is_optional'] = Variable<bool>(isOptional);
    map['position'] = Variable<int>(position);
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      name: Value(name),
      amountText: Value(amountText),
      amountValue: amountValue == null && nullToAbsent
          ? const Value.absent()
          : Value(amountValue),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      preparation: preparation == null && nullToAbsent
          ? const Value.absent()
          : Value(preparation),
      isOptional: Value(isOptional),
      position: Value(position),
    );
  }

  factory Ingredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      name: serializer.fromJson<String>(json['name']),
      amountText: serializer.fromJson<String>(json['amountText']),
      amountValue: serializer.fromJson<double?>(json['amountValue']),
      unit: serializer.fromJson<String?>(json['unit']),
      preparation: serializer.fromJson<String?>(json['preparation']),
      isOptional: serializer.fromJson<bool>(json['isOptional']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'name': serializer.toJson<String>(name),
      'amountText': serializer.toJson<String>(amountText),
      'amountValue': serializer.toJson<double?>(amountValue),
      'unit': serializer.toJson<String?>(unit),
      'preparation': serializer.toJson<String?>(preparation),
      'isOptional': serializer.toJson<bool>(isOptional),
      'position': serializer.toJson<int>(position),
    };
  }

  Ingredient copyWith({
    String? id,
    String? recipeId,
    String? name,
    String? amountText,
    Value<double?> amountValue = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> preparation = const Value.absent(),
    bool? isOptional,
    int? position,
  }) => Ingredient(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    name: name ?? this.name,
    amountText: amountText ?? this.amountText,
    amountValue: amountValue.present ? amountValue.value : this.amountValue,
    unit: unit.present ? unit.value : this.unit,
    preparation: preparation.present ? preparation.value : this.preparation,
    isOptional: isOptional ?? this.isOptional,
    position: position ?? this.position,
  );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      name: data.name.present ? data.name.value : this.name,
      amountText: data.amountText.present
          ? data.amountText.value
          : this.amountText,
      amountValue: data.amountValue.present
          ? data.amountValue.value
          : this.amountValue,
      unit: data.unit.present ? data.unit.value : this.unit,
      preparation: data.preparation.present
          ? data.preparation.value
          : this.preparation,
      isOptional: data.isOptional.present
          ? data.isOptional.value
          : this.isOptional,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('name: $name, ')
          ..write('amountText: $amountText, ')
          ..write('amountValue: $amountValue, ')
          ..write('unit: $unit, ')
          ..write('preparation: $preparation, ')
          ..write('isOptional: $isOptional, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipeId,
    name,
    amountText,
    amountValue,
    unit,
    preparation,
    isOptional,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.name == this.name &&
          other.amountText == this.amountText &&
          other.amountValue == this.amountValue &&
          other.unit == this.unit &&
          other.preparation == this.preparation &&
          other.isOptional == this.isOptional &&
          other.position == this.position);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> name;
  final Value<String> amountText;
  final Value<double?> amountValue;
  final Value<String?> unit;
  final Value<String?> preparation;
  final Value<bool> isOptional;
  final Value<int> position;
  final Value<int> rowid;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountText = const Value.absent(),
    this.amountValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.preparation = const Value.absent(),
    this.isOptional = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsCompanion.insert({
    required String id,
    required String recipeId,
    required String name,
    this.amountText = const Value.absent(),
    this.amountValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.preparation = const Value.absent(),
    this.isOptional = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipeId = Value(recipeId),
       name = Value(name),
       position = Value(position);
  static Insertable<Ingredient> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? name,
    Expression<String>? amountText,
    Expression<double>? amountValue,
    Expression<String>? unit,
    Expression<String>? preparation,
    Expression<bool>? isOptional,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (name != null) 'name': name,
      if (amountText != null) 'amount_text': amountText,
      if (amountValue != null) 'amount_value': amountValue,
      if (unit != null) 'unit': unit,
      if (preparation != null) 'preparation': preparation,
      if (isOptional != null) 'is_optional': isOptional,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipeId,
    Value<String>? name,
    Value<String>? amountText,
    Value<double?>? amountValue,
    Value<String?>? unit,
    Value<String?>? preparation,
    Value<bool>? isOptional,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return IngredientsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      amountText: amountText ?? this.amountText,
      amountValue: amountValue ?? this.amountValue,
      unit: unit ?? this.unit,
      preparation: preparation ?? this.preparation,
      isOptional: isOptional ?? this.isOptional,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountText.present) {
      map['amount_text'] = Variable<String>(amountText.value);
    }
    if (amountValue.present) {
      map['amount_value'] = Variable<double>(amountValue.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (preparation.present) {
      map['preparation'] = Variable<String>(preparation.value);
    }
    if (isOptional.present) {
      map['is_optional'] = Variable<bool>(isOptional.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('name: $name, ')
          ..write('amountText: $amountText, ')
          ..write('amountValue: $amountValue, ')
          ..write('unit: $unit, ')
          ..write('preparation: $preparation, ')
          ..write('isOptional: $isOptional, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeStepsTable extends RecipeSteps
    with TableInfo<$RecipeStepsTable, RecipeStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionMeta = const VerificationMeta(
    'instruction',
  );
  @override
  late final GeneratedColumn<String> instruction = GeneratedColumn<String>(
    'instruction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heatLevelMeta = const VerificationMeta(
    'heatLevel',
  );
  @override
  late final GeneratedColumn<String> heatLevel = GeneratedColumn<String>(
    'heat_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    position,
    title,
    instruction,
    durationMinutes,
    heatLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('instruction')) {
      context.handle(
        _instructionMeta,
        instruction.isAcceptableOrUnknown(
          data['instruction']!,
          _instructionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('heat_level')) {
      context.handle(
        _heatLevelMeta,
        heatLevel.isAcceptableOrUnknown(data['heat_level']!, _heatLevelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      instruction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instruction'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      heatLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heat_level'],
      ),
    );
  }

  @override
  $RecipeStepsTable createAlias(String alias) {
    return $RecipeStepsTable(attachedDatabase, alias);
  }
}

class RecipeStep extends DataClass implements Insertable<RecipeStep> {
  /// 步骤记录主键。
  final String id;

  /// 所属菜谱 ID；删除菜谱时级联删除步骤。
  final String recipeId;

  /// 步骤在菜谱中的零基执行顺序。
  final int position;

  /// 可选的步骤小标题。
  final String? title;

  /// 用户实际阅读和执行的操作说明。
  final String instruction;

  /// 预计执行分钟数；未设置计时时为空。
  final int? durationMinutes;

  /// 火力描述；不适用时为空。
  final String? heatLevel;
  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.position,
    this.title,
    required this.instruction,
    this.durationMinutes,
    this.heatLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['instruction'] = Variable<String>(instruction);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || heatLevel != null) {
      map['heat_level'] = Variable<String>(heatLevel);
    }
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      position: Value(position),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      instruction: Value(instruction),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      heatLevel: heatLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(heatLevel),
    );
  }

  factory RecipeStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStep(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      position: serializer.fromJson<int>(json['position']),
      title: serializer.fromJson<String?>(json['title']),
      instruction: serializer.fromJson<String>(json['instruction']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      heatLevel: serializer.fromJson<String?>(json['heatLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'position': serializer.toJson<int>(position),
      'title': serializer.toJson<String?>(title),
      'instruction': serializer.toJson<String>(instruction),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'heatLevel': serializer.toJson<String?>(heatLevel),
    };
  }

  RecipeStep copyWith({
    String? id,
    String? recipeId,
    int? position,
    Value<String?> title = const Value.absent(),
    String? instruction,
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> heatLevel = const Value.absent(),
  }) => RecipeStep(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    position: position ?? this.position,
    title: title.present ? title.value : this.title,
    instruction: instruction ?? this.instruction,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    heatLevel: heatLevel.present ? heatLevel.value : this.heatLevel,
  );
  RecipeStep copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStep(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      position: data.position.present ? data.position.value : this.position,
      title: data.title.present ? data.title.value : this.title,
      instruction: data.instruction.present
          ? data.instruction.value
          : this.instruction,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      heatLevel: data.heatLevel.present ? data.heatLevel.value : this.heatLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStep(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('instruction: $instruction, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('heatLevel: $heatLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipeId,
    position,
    title,
    instruction,
    durationMinutes,
    heatLevel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStep &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.position == this.position &&
          other.title == this.title &&
          other.instruction == this.instruction &&
          other.durationMinutes == this.durationMinutes &&
          other.heatLevel == this.heatLevel);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStep> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<int> position;
  final Value<String?> title;
  final Value<String> instruction;
  final Value<int?> durationMinutes;
  final Value<String?> heatLevel;
  final Value<int> rowid;
  const RecipeStepsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.position = const Value.absent(),
    this.title = const Value.absent(),
    this.instruction = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.heatLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    required String id,
    required String recipeId,
    required int position,
    this.title = const Value.absent(),
    required String instruction,
    this.durationMinutes = const Value.absent(),
    this.heatLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipeId = Value(recipeId),
       position = Value(position),
       instruction = Value(instruction);
  static Insertable<RecipeStep> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<int>? position,
    Expression<String>? title,
    Expression<String>? instruction,
    Expression<int>? durationMinutes,
    Expression<String>? heatLevel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (position != null) 'position': position,
      if (title != null) 'title': title,
      if (instruction != null) 'instruction': instruction,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (heatLevel != null) 'heat_level': heatLevel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeStepsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipeId,
    Value<int>? position,
    Value<String?>? title,
    Value<String>? instruction,
    Value<int?>? durationMinutes,
    Value<String?>? heatLevel,
    Value<int>? rowid,
  }) {
    return RecipeStepsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      position: position ?? this.position,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      heatLevel: heatLevel ?? this.heatLevel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (instruction.present) {
      map['instruction'] = Variable<String>(instruction.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (heatLevel.present) {
      map['heat_level'] = Variable<String>(heatLevel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('instruction: $instruction, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('heatLevel: $heatLevel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeTagsTable extends RecipeTags
    with TableInfo<$RecipeTagsTable, RecipeTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recipeId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {recipeId, tag},
  ];
  @override
  RecipeTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $RecipeTagsTable createAlias(String alias) {
    return $RecipeTagsTable(attachedDatabase, alias);
  }
}

class RecipeTag extends DataClass implements Insertable<RecipeTag> {
  /// 关联记录的自增主键。
  final int id;

  /// 所属菜谱 ID；删除菜谱时级联删除标签关联。
  final String recipeId;

  /// 标签的显示名称。
  final String tag;
  const RecipeTag({
    required this.id,
    required this.recipeId,
    required this.tag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  RecipeTagsCompanion toCompanion(bool nullToAbsent) {
    return RecipeTagsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      tag: Value(tag),
    );
  }

  factory RecipeTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeTag(
      id: serializer.fromJson<int>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  RecipeTag copyWith({int? id, String? recipeId, String? tag}) => RecipeTag(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    tag: tag ?? this.tag,
  );
  RecipeTag copyWithCompanion(RecipeTagsCompanion data) {
    return RecipeTag(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTag(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeTag &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.tag == this.tag);
}

class RecipeTagsCompanion extends UpdateCompanion<RecipeTag> {
  final Value<int> id;
  final Value<String> recipeId;
  final Value<String> tag;
  const RecipeTagsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.tag = const Value.absent(),
  });
  RecipeTagsCompanion.insert({
    this.id = const Value.absent(),
    required String recipeId,
    required String tag,
  }) : recipeId = Value(recipeId),
       tag = Value(tag);
  static Insertable<RecipeTag> custom({
    Expression<int>? id,
    Expression<String>? recipeId,
    Expression<String>? tag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (tag != null) 'tag': tag,
    });
  }

  RecipeTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? recipeId,
    Value<String>? tag,
  }) {
    return RecipeTagsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      tag: tag ?? this.tag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }
}

class $RecipeCollectionsTable extends RecipeCollections
    with TableInfo<$RecipeCollectionsTable, RecipeCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
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
    name,
    position,
    coverPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
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
  RecipeCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeCollection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
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
  $RecipeCollectionsTable createAlias(String alias) {
    return $RecipeCollectionsTable(attachedDatabase, alias);
  }
}

class RecipeCollection extends DataClass
    implements Insertable<RecipeCollection> {
  /// 菜谱集主键。
  final String id;

  /// 去除首尾空格的名称，最长 40 字。
  final String name;

  /// 菜谱集在列表中的零基展示位置。
  ///
  /// v6 起仅为兼容旧数据库保留，不再参与产品排序。
  final int position;

  /// 受控封面目录中的相对 JPEG 路径；未设置自定义封面时为空。
  final String? coverPath;

  /// 菜谱集首次创建时间。
  final DateTime createdAt;

  /// 名称、成员或展示位置最近变更时间。
  final DateTime updatedAt;
  const RecipeCollection({
    required this.id,
    required this.name,
    required this.position,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecipeCollectionsCompanion toCompanion(bool nullToAbsent) {
    return RecipeCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecipeCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeCollection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'coverPath': serializer.toJson<String?>(coverPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecipeCollection copyWith({
    String? id,
    String? name,
    int? position,
    Value<String?> coverPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecipeCollection(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecipeCollection copyWithCompanion(RecipeCollectionsCompanion data) {
    return RecipeCollection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeCollection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('coverPath: $coverPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, position, coverPath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeCollection &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.coverPath == this.coverPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecipeCollectionsCompanion extends UpdateCompanion<RecipeCollection> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<String?> coverPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecipeCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeCollectionsCompanion.insert({
    required String id,
    required String name,
    required int position,
    this.coverPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecipeCollection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? coverPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (coverPath != null) 'cover_path': coverPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeCollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<String?>? coverPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecipeCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      coverPath: coverPath ?? this.coverPath,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
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
    return (StringBuffer('RecipeCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('coverPath: $coverPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeCollectionMembersTable extends RecipeCollectionMembers
    with TableInfo<$RecipeCollectionMembersTable, RecipeCollectionMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeCollectionMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipe_collections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    collectionId,
    recipeId,
    addedAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_collection_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeCollectionMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, recipeId};
  @override
  RecipeCollectionMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeCollectionMember(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $RecipeCollectionMembersTable createAlias(String alias) {
    return $RecipeCollectionMembersTable(attachedDatabase, alias);
  }
}

class RecipeCollectionMember extends DataClass
    implements Insertable<RecipeCollectionMember> {
  /// 所属菜谱集 ID；删除集合时只级联删除关系。
  final String collectionId;

  /// 成员菜谱 ID；永久删除菜谱时级联删除关系。
  final String recipeId;

  /// 加入集合的时间，用于集合详情默认排序。
  final DateTime addedAt;

  /// 成员在集合中的零基位置；软删除菜谱时保留。
  final int position;
  const RecipeCollectionMember({
    required this.collectionId,
    required this.recipeId,
    required this.addedAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['recipe_id'] = Variable<String>(recipeId);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['position'] = Variable<int>(position);
    return map;
  }

  RecipeCollectionMembersCompanion toCompanion(bool nullToAbsent) {
    return RecipeCollectionMembersCompanion(
      collectionId: Value(collectionId),
      recipeId: Value(recipeId),
      addedAt: Value(addedAt),
      position: Value(position),
    );
  }

  factory RecipeCollectionMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeCollectionMember(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'recipeId': serializer.toJson<String>(recipeId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'position': serializer.toJson<int>(position),
    };
  }

  RecipeCollectionMember copyWith({
    String? collectionId,
    String? recipeId,
    DateTime? addedAt,
    int? position,
  }) => RecipeCollectionMember(
    collectionId: collectionId ?? this.collectionId,
    recipeId: recipeId ?? this.recipeId,
    addedAt: addedAt ?? this.addedAt,
    position: position ?? this.position,
  );
  RecipeCollectionMember copyWithCompanion(
    RecipeCollectionMembersCompanion data,
  ) {
    return RecipeCollectionMember(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeCollectionMember(')
          ..write('collectionId: $collectionId, ')
          ..write('recipeId: $recipeId, ')
          ..write('addedAt: $addedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionId, recipeId, addedAt, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeCollectionMember &&
          other.collectionId == this.collectionId &&
          other.recipeId == this.recipeId &&
          other.addedAt == this.addedAt &&
          other.position == this.position);
}

class RecipeCollectionMembersCompanion
    extends UpdateCompanion<RecipeCollectionMember> {
  final Value<String> collectionId;
  final Value<String> recipeId;
  final Value<DateTime> addedAt;
  final Value<int> position;
  final Value<int> rowid;
  const RecipeCollectionMembersCompanion({
    this.collectionId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeCollectionMembersCompanion.insert({
    required String collectionId,
    required String recipeId,
    required DateTime addedAt,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       recipeId = Value(recipeId),
       addedAt = Value(addedAt);
  static Insertable<RecipeCollectionMember> custom({
    Expression<String>? collectionId,
    Expression<String>? recipeId,
    Expression<DateTime>? addedAt,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (recipeId != null) 'recipe_id': recipeId,
      if (addedAt != null) 'added_at': addedAt,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeCollectionMembersCompanion copyWith({
    Value<String>? collectionId,
    Value<String>? recipeId,
    Value<DateTime>? addedAt,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return RecipeCollectionMembersCompanion(
      collectionId: collectionId ?? this.collectionId,
      recipeId: recipeId ?? this.recipeId,
      addedAt: addedAt ?? this.addedAt,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeCollectionMembersCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('recipeId: $recipeId, ')
          ..write('addedAt: $addedAt, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeLibrarySettingsTable extends RecipeLibrarySettings
    with TableInfo<$RecipeLibrarySettingsTable, RecipeLibrarySetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeLibrarySettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<String> sortOrder = GeneratedColumn<String>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('recentlyUpdated'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_library_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeLibrarySetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeLibrarySetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeLibrarySetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $RecipeLibrarySettingsTable createAlias(String alias) {
    return $RecipeLibrarySettingsTable(attachedDatabase, alias);
  }
}

class RecipeLibrarySetting extends DataClass
    implements Insertable<RecipeLibrarySetting> {
  /// 固定为 1 的单例主键。
  final int id;

  /// 上次选择的菜谱库排序稳定字符串值。
  final String sortOrder;
  const RecipeLibrarySetting({required this.id, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sort_order'] = Variable<String>(sortOrder);
    return map;
  }

  RecipeLibrarySettingsCompanion toCompanion(bool nullToAbsent) {
    return RecipeLibrarySettingsCompanion(
      id: Value(id),
      sortOrder: Value(sortOrder),
    );
  }

  factory RecipeLibrarySetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeLibrarySetting(
      id: serializer.fromJson<int>(json['id']),
      sortOrder: serializer.fromJson<String>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sortOrder': serializer.toJson<String>(sortOrder),
    };
  }

  RecipeLibrarySetting copyWith({int? id, String? sortOrder}) =>
      RecipeLibrarySetting(
        id: id ?? this.id,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  RecipeLibrarySetting copyWithCompanion(RecipeLibrarySettingsCompanion data) {
    return RecipeLibrarySetting(
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeLibrarySetting(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeLibrarySetting &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder);
}

class RecipeLibrarySettingsCompanion
    extends UpdateCompanion<RecipeLibrarySetting> {
  final Value<int> id;
  final Value<String> sortOrder;
  const RecipeLibrarySettingsCompanion({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  RecipeLibrarySettingsCompanion.insert({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  static Insertable<RecipeLibrarySetting> custom({
    Expression<int>? id,
    Expression<String>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  RecipeLibrarySettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? sortOrder,
  }) {
    return RecipeLibrarySettingsCompanion(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<String>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeLibrarySettingsCompanion(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $PersonalRecipeConfigCacheTable extends PersonalRecipeConfigCache
    with
        TableInfo<
          $PersonalRecipeConfigCacheTable,
          PersonalRecipeConfigCacheData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalRecipeConfigCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _namespaceMeta = const VerificationMeta(
    'namespace',
  );
  @override
  late final GeneratedColumn<String> namespace = GeneratedColumn<String>(
    'namespace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriesJsonMeta = const VerificationMeta(
    'categoriesJson',
  );
  @override
  late final GeneratedColumn<String> categoriesJson = GeneratedColumn<String>(
    'categories_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultiesJsonMeta = const VerificationMeta(
    'difficultiesJson',
  );
  @override
  late final GeneratedColumn<String> difficultiesJson = GeneratedColumn<String>(
    'difficulties_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverRevisionMeta = const VerificationMeta(
    'serverRevision',
  );
  @override
  late final GeneratedColumn<String> serverRevision = GeneratedColumn<String>(
    'server_revision',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    namespace,
    categoriesJson,
    tagsJson,
    difficultiesJson,
    serverRevision,
    syncPending,
    lastSyncedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_recipe_config_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalRecipeConfigCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('namespace')) {
      context.handle(
        _namespaceMeta,
        namespace.isAcceptableOrUnknown(data['namespace']!, _namespaceMeta),
      );
    } else if (isInserting) {
      context.missing(_namespaceMeta);
    }
    if (data.containsKey('categories_json')) {
      context.handle(
        _categoriesJsonMeta,
        categoriesJson.isAcceptableOrUnknown(
          data['categories_json']!,
          _categoriesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoriesJsonMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    if (data.containsKey('difficulties_json')) {
      context.handle(
        _difficultiesJsonMeta,
        difficultiesJson.isAcceptableOrUnknown(
          data['difficulties_json']!,
          _difficultiesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultiesJsonMeta);
    }
    if (data.containsKey('server_revision')) {
      context.handle(
        _serverRevisionMeta,
        serverRevision.isAcceptableOrUnknown(
          data['server_revision']!,
          _serverRevisionMeta,
        ),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {namespace};
  @override
  PersonalRecipeConfigCacheData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalRecipeConfigCacheData(
      namespace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}namespace'],
      )!,
      categoriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories_json'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      difficultiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulties_json'],
      )!,
      serverRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_revision'],
      ),
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PersonalRecipeConfigCacheTable createAlias(String alias) {
    return $PersonalRecipeConfigCacheTable(attachedDatabase, alias);
  }
}

class PersonalRecipeConfigCacheData extends DataClass
    implements Insertable<PersonalRecipeConfigCacheData> {
  /// 配置所属命名空间，如 `device:anonymous` 或 `account:<userId>`。
  final String namespace;

  /// 按用户顺序保存的分类 JSON 数组。
  final String categoriesJson;

  /// 按用户顺序保存的标签 JSON 数组。
  final String tagsJson;

  /// 按用户顺序保存的难度 JSON 数组，首项为默认难度。
  final String difficultiesJson;

  /// 服务端配置修订号；尚未成功同步时为空。
  final String? serverRevision;

  /// 是否存在尚未上传成功的本地修改。
  final bool syncPending;

  /// 最近一次成功同步时间；从未同步时为空。
  final DateTime? lastSyncedAt;

  /// 缓存最近更新时间，用于诊断和备份合并。
  final DateTime updatedAt;
  const PersonalRecipeConfigCacheData({
    required this.namespace,
    required this.categoriesJson,
    required this.tagsJson,
    required this.difficultiesJson,
    this.serverRevision,
    required this.syncPending,
    this.lastSyncedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['namespace'] = Variable<String>(namespace);
    map['categories_json'] = Variable<String>(categoriesJson);
    map['tags_json'] = Variable<String>(tagsJson);
    map['difficulties_json'] = Variable<String>(difficultiesJson);
    if (!nullToAbsent || serverRevision != null) {
      map['server_revision'] = Variable<String>(serverRevision);
    }
    map['sync_pending'] = Variable<bool>(syncPending);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PersonalRecipeConfigCacheCompanion toCompanion(bool nullToAbsent) {
    return PersonalRecipeConfigCacheCompanion(
      namespace: Value(namespace),
      categoriesJson: Value(categoriesJson),
      tagsJson: Value(tagsJson),
      difficultiesJson: Value(difficultiesJson),
      serverRevision: serverRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRevision),
      syncPending: Value(syncPending),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PersonalRecipeConfigCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalRecipeConfigCacheData(
      namespace: serializer.fromJson<String>(json['namespace']),
      categoriesJson: serializer.fromJson<String>(json['categoriesJson']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      difficultiesJson: serializer.fromJson<String>(json['difficultiesJson']),
      serverRevision: serializer.fromJson<String?>(json['serverRevision']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'namespace': serializer.toJson<String>(namespace),
      'categoriesJson': serializer.toJson<String>(categoriesJson),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'difficultiesJson': serializer.toJson<String>(difficultiesJson),
      'serverRevision': serializer.toJson<String?>(serverRevision),
      'syncPending': serializer.toJson<bool>(syncPending),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PersonalRecipeConfigCacheData copyWith({
    String? namespace,
    String? categoriesJson,
    String? tagsJson,
    String? difficultiesJson,
    Value<String?> serverRevision = const Value.absent(),
    bool? syncPending,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => PersonalRecipeConfigCacheData(
    namespace: namespace ?? this.namespace,
    categoriesJson: categoriesJson ?? this.categoriesJson,
    tagsJson: tagsJson ?? this.tagsJson,
    difficultiesJson: difficultiesJson ?? this.difficultiesJson,
    serverRevision: serverRevision.present
        ? serverRevision.value
        : this.serverRevision,
    syncPending: syncPending ?? this.syncPending,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PersonalRecipeConfigCacheData copyWithCompanion(
    PersonalRecipeConfigCacheCompanion data,
  ) {
    return PersonalRecipeConfigCacheData(
      namespace: data.namespace.present ? data.namespace.value : this.namespace,
      categoriesJson: data.categoriesJson.present
          ? data.categoriesJson.value
          : this.categoriesJson,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      difficultiesJson: data.difficultiesJson.present
          ? data.difficultiesJson.value
          : this.difficultiesJson,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecipeConfigCacheData(')
          ..write('namespace: $namespace, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('difficultiesJson: $difficultiesJson, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('syncPending: $syncPending, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    namespace,
    categoriesJson,
    tagsJson,
    difficultiesJson,
    serverRevision,
    syncPending,
    lastSyncedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalRecipeConfigCacheData &&
          other.namespace == this.namespace &&
          other.categoriesJson == this.categoriesJson &&
          other.tagsJson == this.tagsJson &&
          other.difficultiesJson == this.difficultiesJson &&
          other.serverRevision == this.serverRevision &&
          other.syncPending == this.syncPending &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.updatedAt == this.updatedAt);
}

class PersonalRecipeConfigCacheCompanion
    extends UpdateCompanion<PersonalRecipeConfigCacheData> {
  final Value<String> namespace;
  final Value<String> categoriesJson;
  final Value<String> tagsJson;
  final Value<String> difficultiesJson;
  final Value<String?> serverRevision;
  final Value<bool> syncPending;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PersonalRecipeConfigCacheCompanion({
    this.namespace = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.difficultiesJson = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalRecipeConfigCacheCompanion.insert({
    required String namespace,
    required String categoriesJson,
    required String tagsJson,
    required String difficultiesJson,
    this.serverRevision = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : namespace = Value(namespace),
       categoriesJson = Value(categoriesJson),
       tagsJson = Value(tagsJson),
       difficultiesJson = Value(difficultiesJson),
       updatedAt = Value(updatedAt);
  static Insertable<PersonalRecipeConfigCacheData> custom({
    Expression<String>? namespace,
    Expression<String>? categoriesJson,
    Expression<String>? tagsJson,
    Expression<String>? difficultiesJson,
    Expression<String>? serverRevision,
    Expression<bool>? syncPending,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (namespace != null) 'namespace': namespace,
      if (categoriesJson != null) 'categories_json': categoriesJson,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (difficultiesJson != null) 'difficulties_json': difficultiesJson,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (syncPending != null) 'sync_pending': syncPending,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalRecipeConfigCacheCompanion copyWith({
    Value<String>? namespace,
    Value<String>? categoriesJson,
    Value<String>? tagsJson,
    Value<String>? difficultiesJson,
    Value<String?>? serverRevision,
    Value<bool>? syncPending,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PersonalRecipeConfigCacheCompanion(
      namespace: namespace ?? this.namespace,
      categoriesJson: categoriesJson ?? this.categoriesJson,
      tagsJson: tagsJson ?? this.tagsJson,
      difficultiesJson: difficultiesJson ?? this.difficultiesJson,
      serverRevision: serverRevision ?? this.serverRevision,
      syncPending: syncPending ?? this.syncPending,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (namespace.present) {
      map['namespace'] = Variable<String>(namespace.value);
    }
    if (categoriesJson.present) {
      map['categories_json'] = Variable<String>(categoriesJson.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (difficultiesJson.present) {
      map['difficulties_json'] = Variable<String>(difficultiesJson.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<String>(serverRevision.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
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
    return (StringBuffer('PersonalRecipeConfigCacheCompanion(')
          ..write('namespace: $namespace, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('difficultiesJson: $difficultiesJson, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('syncPending: $syncPending, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $RecipeStepsTable recipeSteps = $RecipeStepsTable(this);
  late final $RecipeTagsTable recipeTags = $RecipeTagsTable(this);
  late final $RecipeCollectionsTable recipeCollections =
      $RecipeCollectionsTable(this);
  late final $RecipeCollectionMembersTable recipeCollectionMembers =
      $RecipeCollectionMembersTable(this);
  late final $RecipeLibrarySettingsTable recipeLibrarySettings =
      $RecipeLibrarySettingsTable(this);
  late final $PersonalRecipeConfigCacheTable personalRecipeConfigCache =
      $PersonalRecipeConfigCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recipes,
    ingredients,
    recipeSteps,
    recipeTags,
    recipeCollections,
    recipeCollectionMembers,
    recipeLibrarySettings,
    personalRecipeConfigCache,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_steps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipe_collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('recipe_collection_members', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('recipe_collection_members', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      required String id,
      required String title,
      Value<String> summary,
      Value<String> category,
      Value<int?> servings,
      Value<int?> prepMinutes,
      Value<int?> cookMinutes,
      Value<String> difficulty,
      Value<String> presentationStyle,
      Value<String> templateId,
      Value<int> templateVersion,
      Value<bool> isFavorite,
      Value<DateTime?> lastCookedAt,
      Value<int> cookCount,
      Value<String> status,
      Value<DateTime?> deletedAt,
      Value<String?> statusBeforeDeletion,
      required int coverColor,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> importTaskId,
      Value<String?> sourceOriginalText,
      Value<String?> sourcePublicUrl,
      Value<String?> sourceTitle,
      Value<int> rowid,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> summary,
      Value<String> category,
      Value<int?> servings,
      Value<int?> prepMinutes,
      Value<int?> cookMinutes,
      Value<String> difficulty,
      Value<String> presentationStyle,
      Value<String> templateId,
      Value<int> templateVersion,
      Value<bool> isFavorite,
      Value<DateTime?> lastCookedAt,
      Value<int> cookCount,
      Value<String> status,
      Value<DateTime?> deletedAt,
      Value<String?> statusBeforeDeletion,
      Value<int> coverColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> importTaskId,
      Value<String?> sourceOriginalText,
      Value<String?> sourcePublicUrl,
      Value<String?> sourceTitle,
      Value<int> rowid,
    });

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, Recipe> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientsTable, List<Ingredient>>
  _ingredientsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ingredients,
    aliasName: 'recipes__id__ingredients__recipe_id',
  );

  $$IngredientsTableProcessedTableManager get ingredientsRefs {
    final manager = $$IngredientsTableTableManager(
      $_db,
      $_db.ingredients,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ingredientsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeStepsTable, List<RecipeStep>>
  _recipeStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeSteps,
    aliasName: 'recipes__id__recipe_steps__recipe_id',
  );

  $$RecipeStepsTableProcessedTableManager get recipeStepsRefs {
    final manager = $$RecipeStepsTableTableManager(
      $_db,
      $_db.recipeSteps,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeTagsTable, List<RecipeTag>>
  _recipeTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeTags,
    aliasName: 'recipes__id__recipe_tags__recipe_id',
  );

  $$RecipeTagsTableProcessedTableManager get recipeTagsRefs {
    final manager = $$RecipeTagsTableTableManager(
      $_db,
      $_db.recipeTags,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RecipeCollectionMembersTable,
    List<RecipeCollectionMember>
  >
  _recipeCollectionMembersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recipeCollectionMembers,
        aliasName: 'recipes__id__recipe_collection_members__recipe_id',
      );

  $$RecipeCollectionMembersTableProcessedTableManager
  get recipeCollectionMembersRefs {
    final manager = $$RecipeCollectionMembersTableTableManager(
      $_db,
      $_db.recipeCollectionMembers,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recipeCollectionMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentationStyle => $composableBuilder(
    column: $table.presentationStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCookedAt => $composableBuilder(
    column: $table.lastCookedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cookCount => $composableBuilder(
    column: $table.cookCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusBeforeDeletion => $composableBuilder(
    column: $table.statusBeforeDeletion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
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

  ColumnFilters<String> get importTaskId => $composableBuilder(
    column: $table.importTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceOriginalText => $composableBuilder(
    column: $table.sourceOriginalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePublicUrl => $composableBuilder(
    column: $table.sourcePublicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ingredientsRefs(
    Expression<bool> Function($$IngredientsTableFilterComposer f) f,
  ) {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableFilterComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeStepsRefs(
    Expression<bool> Function($$RecipeStepsTableFilterComposer f) f,
  ) {
    final $$RecipeStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeStepsTableFilterComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeTagsRefs(
    Expression<bool> Function($$RecipeTagsTableFilterComposer f) f,
  ) {
    final $$RecipeTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableFilterComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeCollectionMembersRefs(
    Expression<bool> Function($$RecipeCollectionMembersTableFilterComposer f) f,
  ) {
    final $$RecipeCollectionMembersTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeCollectionMembers,
          getReferencedColumn: (t) => t.recipeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeCollectionMembersTableFilterComposer(
                $db: $db,
                $table: $db.recipeCollectionMembers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentationStyle => $composableBuilder(
    column: $table.presentationStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCookedAt => $composableBuilder(
    column: $table.lastCookedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cookCount => $composableBuilder(
    column: $table.cookCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusBeforeDeletion => $composableBuilder(
    column: $table.statusBeforeDeletion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
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

  ColumnOrderings<String> get importTaskId => $composableBuilder(
    column: $table.importTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceOriginalText => $composableBuilder(
    column: $table.sourceOriginalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePublicUrl => $composableBuilder(
    column: $table.sourcePublicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presentationStyle => $composableBuilder(
    column: $table.presentationStyle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCookedAt => $composableBuilder(
    column: $table.lastCookedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cookCount =>
      $composableBuilder(column: $table.cookCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get statusBeforeDeletion => $composableBuilder(
    column: $table.statusBeforeDeletion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get importTaskId => $composableBuilder(
    column: $table.importTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceOriginalText => $composableBuilder(
    column: $table.sourceOriginalText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePublicUrl => $composableBuilder(
    column: $table.sourcePublicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  Expression<T> ingredientsRefs<T extends Object>(
    Expression<T> Function($$IngredientsTableAnnotationComposer a) f,
  ) {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeStepsRefs<T extends Object>(
    Expression<T> Function($$RecipeStepsTableAnnotationComposer a) f,
  ) {
    final $$RecipeStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeTagsRefs<T extends Object>(
    Expression<T> Function($$RecipeTagsTableAnnotationComposer a) f,
  ) {
    final $$RecipeTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeCollectionMembersRefs<T extends Object>(
    Expression<T> Function($$RecipeCollectionMembersTableAnnotationComposer a)
    f,
  ) {
    final $$RecipeCollectionMembersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeCollectionMembers,
          getReferencedColumn: (t) => t.recipeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeCollectionMembersTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeCollectionMembers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, $$RecipesTableReferences),
          Recipe,
          PrefetchHooks Function({
            bool ingredientsRefs,
            bool recipeStepsRefs,
            bool recipeTagsRefs,
            bool recipeCollectionMembersRefs,
          })
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int?> servings = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> presentationStyle = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<int> templateVersion = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastCookedAt = const Value.absent(),
                Value<int> cookCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> statusBeforeDeletion = const Value.absent(),
                Value<int> coverColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> importTaskId = const Value.absent(),
                Value<String?> sourceOriginalText = const Value.absent(),
                Value<String?> sourcePublicUrl = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                title: title,
                summary: summary,
                category: category,
                servings: servings,
                prepMinutes: prepMinutes,
                cookMinutes: cookMinutes,
                difficulty: difficulty,
                presentationStyle: presentationStyle,
                templateId: templateId,
                templateVersion: templateVersion,
                isFavorite: isFavorite,
                lastCookedAt: lastCookedAt,
                cookCount: cookCount,
                status: status,
                deletedAt: deletedAt,
                statusBeforeDeletion: statusBeforeDeletion,
                coverColor: coverColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                importTaskId: importTaskId,
                sourceOriginalText: sourceOriginalText,
                sourcePublicUrl: sourcePublicUrl,
                sourceTitle: sourceTitle,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> summary = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int?> servings = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> presentationStyle = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<int> templateVersion = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastCookedAt = const Value.absent(),
                Value<int> cookCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> statusBeforeDeletion = const Value.absent(),
                required int coverColor,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> importTaskId = const Value.absent(),
                Value<String?> sourceOriginalText = const Value.absent(),
                Value<String?> sourcePublicUrl = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                title: title,
                summary: summary,
                category: category,
                servings: servings,
                prepMinutes: prepMinutes,
                cookMinutes: cookMinutes,
                difficulty: difficulty,
                presentationStyle: presentationStyle,
                templateId: templateId,
                templateVersion: templateVersion,
                isFavorite: isFavorite,
                lastCookedAt: lastCookedAt,
                cookCount: cookCount,
                status: status,
                deletedAt: deletedAt,
                statusBeforeDeletion: statusBeforeDeletion,
                coverColor: coverColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                importTaskId: importTaskId,
                sourceOriginalText: sourceOriginalText,
                sourcePublicUrl: sourcePublicUrl,
                sourceTitle: sourceTitle,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ingredientsRefs = false,
                recipeStepsRefs = false,
                recipeTagsRefs = false,
                recipeCollectionMembersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ingredientsRefs) db.ingredients,
                    if (recipeStepsRefs) db.recipeSteps,
                    if (recipeTagsRefs) db.recipeTags,
                    if (recipeCollectionMembersRefs) db.recipeCollectionMembers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ingredientsRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          Ingredient
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._ingredientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).ingredientsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeStepsRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          RecipeStep
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeStepsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeTagsRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          RecipeTag
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeCollectionMembersRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          RecipeCollectionMember
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeCollectionMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeCollectionMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, $$RecipesTableReferences),
      Recipe,
      PrefetchHooks Function({
        bool ingredientsRefs,
        bool recipeStepsRefs,
        bool recipeTagsRefs,
        bool recipeCollectionMembersRefs,
      })
    >;
typedef $$IngredientsTableCreateCompanionBuilder =
    IngredientsCompanion Function({
      required String id,
      required String recipeId,
      required String name,
      Value<String> amountText,
      Value<double?> amountValue,
      Value<String?> unit,
      Value<String?> preparation,
      Value<bool> isOptional,
      required int position,
      Value<int> rowid,
    });
typedef $$IngredientsTableUpdateCompanionBuilder =
    IngredientsCompanion Function({
      Value<String> id,
      Value<String> recipeId,
      Value<String> name,
      Value<String> amountText,
      Value<double?> amountValue,
      Value<String?> unit,
      Value<String?> preparation,
      Value<bool> isOptional,
      Value<int> position,
      Value<int> rowid,
    });

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('ingredients__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountText => $composableBuilder(
    column: $table.amountText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountValue => $composableBuilder(
    column: $table.amountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preparation => $composableBuilder(
    column: $table.preparation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountText => $composableBuilder(
    column: $table.amountText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountValue => $composableBuilder(
    column: $table.amountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preparation => $composableBuilder(
    column: $table.preparation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get amountText => $composableBuilder(
    column: $table.amountText,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amountValue => $composableBuilder(
    column: $table.amountValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get preparation => $composableBuilder(
    column: $table.preparation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientsTable,
          Ingredient,
          $$IngredientsTableFilterComposer,
          $$IngredientsTableOrderingComposer,
          $$IngredientsTableAnnotationComposer,
          $$IngredientsTableCreateCompanionBuilder,
          $$IngredientsTableUpdateCompanionBuilder,
          (Ingredient, $$IngredientsTableReferences),
          Ingredient,
          PrefetchHooks Function({bool recipeId})
        > {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> amountText = const Value.absent(),
                Value<double?> amountValue = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> preparation = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion(
                id: id,
                recipeId: recipeId,
                name: name,
                amountText: amountText,
                amountValue: amountValue,
                unit: unit,
                preparation: preparation,
                isOptional: isOptional,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipeId,
                required String name,
                Value<String> amountText = const Value.absent(),
                Value<double?> amountValue = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> preparation = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion.insert(
                id: id,
                recipeId: recipeId,
                name: name,
                amountText: amountText,
                amountValue: amountValue,
                unit: unit,
                preparation: preparation,
                isOptional: isOptional,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$IngredientsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$IngredientsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientsTable,
      Ingredient,
      $$IngredientsTableFilterComposer,
      $$IngredientsTableOrderingComposer,
      $$IngredientsTableAnnotationComposer,
      $$IngredientsTableCreateCompanionBuilder,
      $$IngredientsTableUpdateCompanionBuilder,
      (Ingredient, $$IngredientsTableReferences),
      Ingredient,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$RecipeStepsTableCreateCompanionBuilder =
    RecipeStepsCompanion Function({
      required String id,
      required String recipeId,
      required int position,
      Value<String?> title,
      required String instruction,
      Value<int?> durationMinutes,
      Value<String?> heatLevel,
      Value<int> rowid,
    });
typedef $$RecipeStepsTableUpdateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<String> id,
      Value<String> recipeId,
      Value<int> position,
      Value<String?> title,
      Value<String> instruction,
      Value<int?> durationMinutes,
      Value<String?> heatLevel,
      Value<int> rowid,
    });

final class $$RecipeStepsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep> {
  $$RecipeStepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_steps__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeStepsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instruction => $composableBuilder(
    column: $table.instruction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatLevel => $composableBuilder(
    column: $table.heatLevel,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instruction => $composableBuilder(
    column: $table.instruction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatLevel => $composableBuilder(
    column: $table.heatLevel,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get instruction => $composableBuilder(
    column: $table.instruction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatLevel =>
      $composableBuilder(column: $table.heatLevel, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeStepsTable,
          RecipeStep,
          $$RecipeStepsTableFilterComposer,
          $$RecipeStepsTableOrderingComposer,
          $$RecipeStepsTableAnnotationComposer,
          $$RecipeStepsTableCreateCompanionBuilder,
          $$RecipeStepsTableUpdateCompanionBuilder,
          (RecipeStep, $$RecipeStepsTableReferences),
          RecipeStep,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeStepsTableTableManager(_$AppDatabase db, $RecipeStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> instruction = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> heatLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeStepsCompanion(
                id: id,
                recipeId: recipeId,
                position: position,
                title: title,
                instruction: instruction,
                durationMinutes: durationMinutes,
                heatLevel: heatLevel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipeId,
                required int position,
                Value<String?> title = const Value.absent(),
                required String instruction,
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> heatLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeStepsCompanion.insert(
                id: id,
                recipeId: recipeId,
                position: position,
                title: title,
                instruction: instruction,
                durationMinutes: durationMinutes,
                heatLevel: heatLevel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeStepsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeStepsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeStepsTable,
      RecipeStep,
      $$RecipeStepsTableFilterComposer,
      $$RecipeStepsTableOrderingComposer,
      $$RecipeStepsTableAnnotationComposer,
      $$RecipeStepsTableCreateCompanionBuilder,
      $$RecipeStepsTableUpdateCompanionBuilder,
      (RecipeStep, $$RecipeStepsTableReferences),
      RecipeStep,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$RecipeTagsTableCreateCompanionBuilder =
    RecipeTagsCompanion Function({
      Value<int> id,
      required String recipeId,
      required String tag,
    });
typedef $$RecipeTagsTableUpdateCompanionBuilder =
    RecipeTagsCompanion Function({
      Value<int> id,
      Value<String> recipeId,
      Value<String> tag,
    });

final class $$RecipeTagsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTag> {
  $$RecipeTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_tags__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeTagsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeTagsTable,
          RecipeTag,
          $$RecipeTagsTableFilterComposer,
          $$RecipeTagsTableOrderingComposer,
          $$RecipeTagsTableAnnotationComposer,
          $$RecipeTagsTableCreateCompanionBuilder,
          $$RecipeTagsTableUpdateCompanionBuilder,
          (RecipeTag, $$RecipeTagsTableReferences),
          RecipeTag,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeTagsTableTableManager(_$AppDatabase db, $RecipeTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> tag = const Value.absent(),
              }) => RecipeTagsCompanion(id: id, recipeId: recipeId, tag: tag),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String recipeId,
                required String tag,
              }) => RecipeTagsCompanion.insert(
                id: id,
                recipeId: recipeId,
                tag: tag,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeTagsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeTagsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeTagsTable,
      RecipeTag,
      $$RecipeTagsTableFilterComposer,
      $$RecipeTagsTableOrderingComposer,
      $$RecipeTagsTableAnnotationComposer,
      $$RecipeTagsTableCreateCompanionBuilder,
      $$RecipeTagsTableUpdateCompanionBuilder,
      (RecipeTag, $$RecipeTagsTableReferences),
      RecipeTag,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$RecipeCollectionsTableCreateCompanionBuilder =
    RecipeCollectionsCompanion Function({
      required String id,
      required String name,
      required int position,
      Value<String?> coverPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RecipeCollectionsTableUpdateCompanionBuilder =
    RecipeCollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> position,
      Value<String?> coverPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RecipeCollectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecipeCollectionsTable,
          RecipeCollection
        > {
  $$RecipeCollectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $RecipeCollectionMembersTable,
    List<RecipeCollectionMember>
  >
  _recipeCollectionMembersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recipeCollectionMembers,
        aliasName:
            'recipe_collections__id__recipe_collection_members__collection_id',
      );

  $$RecipeCollectionMembersTableProcessedTableManager
  get recipeCollectionMembersRefs {
    final manager = $$RecipeCollectionMembersTableTableManager(
      $_db,
      $_db.recipeCollectionMembers,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recipeCollectionMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipeCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeCollectionsTable> {
  $$RecipeCollectionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
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

  Expression<bool> recipeCollectionMembersRefs(
    Expression<bool> Function($$RecipeCollectionMembersTableFilterComposer f) f,
  ) {
    final $$RecipeCollectionMembersTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeCollectionMembers,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeCollectionMembersTableFilterComposer(
                $db: $db,
                $table: $db.recipeCollectionMembers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecipeCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeCollectionsTable> {
  $$RecipeCollectionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
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

class $$RecipeCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeCollectionsTable> {
  $$RecipeCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> recipeCollectionMembersRefs<T extends Object>(
    Expression<T> Function($$RecipeCollectionMembersTableAnnotationComposer a)
    f,
  ) {
    final $$RecipeCollectionMembersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeCollectionMembers,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeCollectionMembersTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeCollectionMembers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecipeCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeCollectionsTable,
          RecipeCollection,
          $$RecipeCollectionsTableFilterComposer,
          $$RecipeCollectionsTableOrderingComposer,
          $$RecipeCollectionsTableAnnotationComposer,
          $$RecipeCollectionsTableCreateCompanionBuilder,
          $$RecipeCollectionsTableUpdateCompanionBuilder,
          (RecipeCollection, $$RecipeCollectionsTableReferences),
          RecipeCollection,
          PrefetchHooks Function({bool recipeCollectionMembersRefs})
        > {
  $$RecipeCollectionsTableTableManager(
    _$AppDatabase db,
    $RecipeCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeCollectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeCollectionsCompanion(
                id: id,
                name: name,
                position: position,
                coverPath: coverPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int position,
                Value<String?> coverPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecipeCollectionsCompanion.insert(
                id: id,
                name: name,
                position: position,
                coverPath: coverPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeCollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeCollectionMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipeCollectionMembersRefs) db.recipeCollectionMembers,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeCollectionMembersRefs)
                    await $_getPrefetchedData<
                      RecipeCollection,
                      $RecipeCollectionsTable,
                      RecipeCollectionMember
                    >(
                      currentTable: table,
                      referencedTable: $$RecipeCollectionsTableReferences
                          ._recipeCollectionMembersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecipeCollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).recipeCollectionMembersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecipeCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeCollectionsTable,
      RecipeCollection,
      $$RecipeCollectionsTableFilterComposer,
      $$RecipeCollectionsTableOrderingComposer,
      $$RecipeCollectionsTableAnnotationComposer,
      $$RecipeCollectionsTableCreateCompanionBuilder,
      $$RecipeCollectionsTableUpdateCompanionBuilder,
      (RecipeCollection, $$RecipeCollectionsTableReferences),
      RecipeCollection,
      PrefetchHooks Function({bool recipeCollectionMembersRefs})
    >;
typedef $$RecipeCollectionMembersTableCreateCompanionBuilder =
    RecipeCollectionMembersCompanion Function({
      required String collectionId,
      required String recipeId,
      required DateTime addedAt,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$RecipeCollectionMembersTableUpdateCompanionBuilder =
    RecipeCollectionMembersCompanion Function({
      Value<String> collectionId,
      Value<String> recipeId,
      Value<DateTime> addedAt,
      Value<int> position,
      Value<int> rowid,
    });

final class $$RecipeCollectionMembersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecipeCollectionMembersTable,
          RecipeCollectionMember
        > {
  $$RecipeCollectionMembersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipeCollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.recipeCollections.createAlias(
        'recipe_collection_members__collection_id__recipe_collections__id',
      );

  $$RecipeCollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$RecipeCollectionsTableTableManager(
      $_db,
      $_db.recipeCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecipesTable _recipeIdTable(_$AppDatabase db) => db.recipes
      .createAlias('recipe_collection_members__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeCollectionMembersTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeCollectionMembersTable> {
  $$RecipeCollectionMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipeCollectionsTableFilterComposer get collectionId {
    final $$RecipeCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.recipeCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.recipeCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeCollectionMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeCollectionMembersTable> {
  $$RecipeCollectionMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipeCollectionsTableOrderingComposer get collectionId {
    final $$RecipeCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.recipeCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.recipeCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeCollectionMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeCollectionMembersTable> {
  $$RecipeCollectionMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$RecipeCollectionsTableAnnotationComposer get collectionId {
    final $$RecipeCollectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.collectionId,
          referencedTable: $db.recipeCollections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeCollectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeCollections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeCollectionMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeCollectionMembersTable,
          RecipeCollectionMember,
          $$RecipeCollectionMembersTableFilterComposer,
          $$RecipeCollectionMembersTableOrderingComposer,
          $$RecipeCollectionMembersTableAnnotationComposer,
          $$RecipeCollectionMembersTableCreateCompanionBuilder,
          $$RecipeCollectionMembersTableUpdateCompanionBuilder,
          (RecipeCollectionMember, $$RecipeCollectionMembersTableReferences),
          RecipeCollectionMember,
          PrefetchHooks Function({bool collectionId, bool recipeId})
        > {
  $$RecipeCollectionMembersTableTableManager(
    _$AppDatabase db,
    $RecipeCollectionMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeCollectionMembersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecipeCollectionMembersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecipeCollectionMembersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeCollectionMembersCompanion(
                collectionId: collectionId,
                recipeId: recipeId,
                addedAt: addedAt,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required String recipeId,
                required DateTime addedAt,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeCollectionMembersCompanion.insert(
                collectionId: collectionId,
                recipeId: recipeId,
                addedAt: addedAt,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeCollectionMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false, recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (collectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.collectionId,
                                referencedTable:
                                    $$RecipeCollectionMembersTableReferences
                                        ._collectionIdTable(db),
                                referencedColumn:
                                    $$RecipeCollectionMembersTableReferences
                                        ._collectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable:
                                    $$RecipeCollectionMembersTableReferences
                                        ._recipeIdTable(db),
                                referencedColumn:
                                    $$RecipeCollectionMembersTableReferences
                                        ._recipeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeCollectionMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeCollectionMembersTable,
      RecipeCollectionMember,
      $$RecipeCollectionMembersTableFilterComposer,
      $$RecipeCollectionMembersTableOrderingComposer,
      $$RecipeCollectionMembersTableAnnotationComposer,
      $$RecipeCollectionMembersTableCreateCompanionBuilder,
      $$RecipeCollectionMembersTableUpdateCompanionBuilder,
      (RecipeCollectionMember, $$RecipeCollectionMembersTableReferences),
      RecipeCollectionMember,
      PrefetchHooks Function({bool collectionId, bool recipeId})
    >;
typedef $$RecipeLibrarySettingsTableCreateCompanionBuilder =
    RecipeLibrarySettingsCompanion Function({
      Value<int> id,
      Value<String> sortOrder,
    });
typedef $$RecipeLibrarySettingsTableUpdateCompanionBuilder =
    RecipeLibrarySettingsCompanion Function({
      Value<int> id,
      Value<String> sortOrder,
    });

class $$RecipeLibrarySettingsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeLibrarySettingsTable> {
  $$RecipeLibrarySettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeLibrarySettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeLibrarySettingsTable> {
  $$RecipeLibrarySettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeLibrarySettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeLibrarySettingsTable> {
  $$RecipeLibrarySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$RecipeLibrarySettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeLibrarySettingsTable,
          RecipeLibrarySetting,
          $$RecipeLibrarySettingsTableFilterComposer,
          $$RecipeLibrarySettingsTableOrderingComposer,
          $$RecipeLibrarySettingsTableAnnotationComposer,
          $$RecipeLibrarySettingsTableCreateCompanionBuilder,
          $$RecipeLibrarySettingsTableUpdateCompanionBuilder,
          (
            RecipeLibrarySetting,
            BaseReferences<
              _$AppDatabase,
              $RecipeLibrarySettingsTable,
              RecipeLibrarySetting
            >,
          ),
          RecipeLibrarySetting,
          PrefetchHooks Function()
        > {
  $$RecipeLibrarySettingsTableTableManager(
    _$AppDatabase db,
    $RecipeLibrarySettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeLibrarySettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecipeLibrarySettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecipeLibrarySettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sortOrder = const Value.absent(),
              }) =>
                  RecipeLibrarySettingsCompanion(id: id, sortOrder: sortOrder),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sortOrder = const Value.absent(),
              }) => RecipeLibrarySettingsCompanion.insert(
                id: id,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeLibrarySettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeLibrarySettingsTable,
      RecipeLibrarySetting,
      $$RecipeLibrarySettingsTableFilterComposer,
      $$RecipeLibrarySettingsTableOrderingComposer,
      $$RecipeLibrarySettingsTableAnnotationComposer,
      $$RecipeLibrarySettingsTableCreateCompanionBuilder,
      $$RecipeLibrarySettingsTableUpdateCompanionBuilder,
      (
        RecipeLibrarySetting,
        BaseReferences<
          _$AppDatabase,
          $RecipeLibrarySettingsTable,
          RecipeLibrarySetting
        >,
      ),
      RecipeLibrarySetting,
      PrefetchHooks Function()
    >;
typedef $$PersonalRecipeConfigCacheTableCreateCompanionBuilder =
    PersonalRecipeConfigCacheCompanion Function({
      required String namespace,
      required String categoriesJson,
      required String tagsJson,
      required String difficultiesJson,
      Value<String?> serverRevision,
      Value<bool> syncPending,
      Value<DateTime?> lastSyncedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PersonalRecipeConfigCacheTableUpdateCompanionBuilder =
    PersonalRecipeConfigCacheCompanion Function({
      Value<String> namespace,
      Value<String> categoriesJson,
      Value<String> tagsJson,
      Value<String> difficultiesJson,
      Value<String?> serverRevision,
      Value<bool> syncPending,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PersonalRecipeConfigCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalRecipeConfigCacheTable> {
  $$PersonalRecipeConfigCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get namespace => $composableBuilder(
    column: $table.namespace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoriesJson => $composableBuilder(
    column: $table.categoriesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficultiesJson => $composableBuilder(
    column: $table.difficultiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonalRecipeConfigCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalRecipeConfigCacheTable> {
  $$PersonalRecipeConfigCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get namespace => $composableBuilder(
    column: $table.namespace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoriesJson => $composableBuilder(
    column: $table.categoriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficultiesJson => $composableBuilder(
    column: $table.difficultiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonalRecipeConfigCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalRecipeConfigCacheTable> {
  $$PersonalRecipeConfigCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get namespace =>
      $composableBuilder(column: $table.namespace, builder: (column) => column);

  GeneratedColumn<String> get categoriesJson => $composableBuilder(
    column: $table.categoriesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get difficultiesJson => $composableBuilder(
    column: $table.difficultiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PersonalRecipeConfigCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalRecipeConfigCacheTable,
          PersonalRecipeConfigCacheData,
          $$PersonalRecipeConfigCacheTableFilterComposer,
          $$PersonalRecipeConfigCacheTableOrderingComposer,
          $$PersonalRecipeConfigCacheTableAnnotationComposer,
          $$PersonalRecipeConfigCacheTableCreateCompanionBuilder,
          $$PersonalRecipeConfigCacheTableUpdateCompanionBuilder,
          (
            PersonalRecipeConfigCacheData,
            BaseReferences<
              _$AppDatabase,
              $PersonalRecipeConfigCacheTable,
              PersonalRecipeConfigCacheData
            >,
          ),
          PersonalRecipeConfigCacheData,
          PrefetchHooks Function()
        > {
  $$PersonalRecipeConfigCacheTableTableManager(
    _$AppDatabase db,
    $PersonalRecipeConfigCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalRecipeConfigCacheTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PersonalRecipeConfigCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PersonalRecipeConfigCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> namespace = const Value.absent(),
                Value<String> categoriesJson = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> difficultiesJson = const Value.absent(),
                Value<String?> serverRevision = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalRecipeConfigCacheCompanion(
                namespace: namespace,
                categoriesJson: categoriesJson,
                tagsJson: tagsJson,
                difficultiesJson: difficultiesJson,
                serverRevision: serverRevision,
                syncPending: syncPending,
                lastSyncedAt: lastSyncedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String namespace,
                required String categoriesJson,
                required String tagsJson,
                required String difficultiesJson,
                Value<String?> serverRevision = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PersonalRecipeConfigCacheCompanion.insert(
                namespace: namespace,
                categoriesJson: categoriesJson,
                tagsJson: tagsJson,
                difficultiesJson: difficultiesJson,
                serverRevision: serverRevision,
                syncPending: syncPending,
                lastSyncedAt: lastSyncedAt,
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

typedef $$PersonalRecipeConfigCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalRecipeConfigCacheTable,
      PersonalRecipeConfigCacheData,
      $$PersonalRecipeConfigCacheTableFilterComposer,
      $$PersonalRecipeConfigCacheTableOrderingComposer,
      $$PersonalRecipeConfigCacheTableAnnotationComposer,
      $$PersonalRecipeConfigCacheTableCreateCompanionBuilder,
      $$PersonalRecipeConfigCacheTableUpdateCompanionBuilder,
      (
        PersonalRecipeConfigCacheData,
        BaseReferences<
          _$AppDatabase,
          $PersonalRecipeConfigCacheTable,
          PersonalRecipeConfigCacheData
        >,
      ),
      PersonalRecipeConfigCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db, _db.recipeSteps);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db, _db.recipeTags);
  $$RecipeCollectionsTableTableManager get recipeCollections =>
      $$RecipeCollectionsTableTableManager(_db, _db.recipeCollections);
  $$RecipeCollectionMembersTableTableManager get recipeCollectionMembers =>
      $$RecipeCollectionMembersTableTableManager(
        _db,
        _db.recipeCollectionMembers,
      );
  $$RecipeLibrarySettingsTableTableManager get recipeLibrarySettings =>
      $$RecipeLibrarySettingsTableTableManager(_db, _db.recipeLibrarySettings);
  $$PersonalRecipeConfigCacheTableTableManager get personalRecipeConfigCache =>
      $$PersonalRecipeConfigCacheTableTableManager(
        _db,
        _db.personalRecipeConfigCache,
      );
}
