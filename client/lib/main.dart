import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';
import 'package:kitchen_recipe_data/kitchen_recipe_data.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_import_data/kitchen_import_data.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';
import 'package:kitchen_profile/kitchen_profile.dart';
import 'package:kitchen_notes/src/backup/kitchen_notes_local_backup_service.dart';
import 'package:kitchen_notes/src/kitchen_notes_app.dart';
import 'package:kitchen_notes/src/auth/kitchen_notes_auth_session_repository.dart';
import 'package:kitchen_notes/src/auth/kitchen_notes_phone_sign_in.dart';

void main() {
  // 数据库连接依赖 Flutter 插件提供的应用目录，因此要先初始化绑定。
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KitchenNotesBootstrap());
}

/// 应用的“组合根”：只在这里创建基础设施，并把实现注入各个 Feature。
///
/// Feature 只认识 Domain 中的 UseCase/Repository 接口，不直接依赖 Drift 数据库。
class KitchenNotesBootstrap extends StatefulWidget {
  const KitchenNotesBootstrap({super.key});

  @override
  State<KitchenNotesBootstrap> createState() => _KitchenNotesBootstrapState();
}

class _KitchenNotesBootstrapState extends State<KitchenNotesBootstrap>
    with WidgetsBindingObserver {
  late final RecipeDataModule _recipeDataModule;
  late final ImportDataModule _importDataModule;
  late final ImportPipeline _importPipeline;
  late final KitchenNotesLocalBackupService _backupService;
  late final KitchenNotesAuthSessionRepository _authSessionRepository;
  late final KitchenNotesPhoneSignInCoordinator _phoneSignInCoordinator;
  var _isConsumingAndroidShares = false;

  @override
  void initState() {
    super.initState();
    // 创建菜谱数据库和菜谱 Repository
    _recipeDataModule = RecipeDataModule();
    // 创建导入数据库、OCR、图片存储等能力
    _importDataModule = ImportDataModule();
    // 组织导入流程
    _importPipeline = ImportPipeline(
      repository: _importDataModule.importTaskRepository,
      localStructurer: const LocalRecipeStructurerService(),
      publicContentExtractor: _importDataModule.publicContentExtractor,
      ocrAdapter: _importDataModule.ocrAdapter,
    );
    _backupService = KitchenNotesLocalBackupService(
      recipeDataModule: _recipeDataModule,
      importDataModule: _importDataModule,
    );
    _authSessionRepository = KitchenNotesAuthSessionRepository(
      secureStore: FlutterSecureRefreshTokenStore(),
      gateway: _UnconfiguredAuthGateway(),
    );
    _phoneSignInCoordinator = KitchenNotesPhoneSignInCoordinator(
      gateway: KitchenNotesPhoneHttpAuthGateway(
        baseUri: Uri.parse(
          const String.fromEnvironment(
            'KITCHEN_NOTES_API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8080',
          ),
        ),
      ),
      sessionRepository: _authSessionRepository,
      installationId: 'local-development-installation',
    );
    unawaited(_authSessionRepository.restore());
    WidgetsBinding.instance.addObserver(this);
    _importDataModule.androidShareAdapter.setOnShareAvailable(
      _consumePendingAndroidShares,
    );
    // App 冷启动后恢复被系统中断的导入阶段；任务原文和中间结果已经在独立
    // Drift 数据库中，因此恢复不会依赖页面是否打开。
    unawaited(_importPipeline.resumePending());
    // 个性化配置先读本地缓存，不阻塞首屏；远端可用时再双向同步账号配置。
    unawaited(_recipeDataModule.personalRecipeConfigRepository.synchronize());
    unawaited(_consumePendingAndroidShares());
    unawaited(_purgeExpiredRecipes());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _importDataModule.androidShareAdapter.setOnShareAvailable(null);
    // App 生命周期结束时关闭 Drift，释放后台 isolate 和 SQLite 文件句柄。
    _recipeDataModule.close();
    _importDataModule.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_consumePendingAndroidShares());
      unawaited(_purgeExpiredRecipes());
    }
  }

  Future<void> _purgeExpiredRecipes() async {
    try {
      await PurgeExpiredRecipesUseCase(_recipeDataModule.deletionRepository)();
    } catch (_) {
      // 机会式清理失败不阻塞启动；下次启动、恢复前台或打开回收站会重试。
    }
  }

  Future<void> _consumePendingAndroidShares() async {
    if (_isConsumingAndroidShares) return;
    _isConsumingAndroidShares = true;
    try {
      final shares = await _importDataModule.androidShareAdapter
          .listPendingShares();
      for (final share in shares) {
        try {
          final existingTaskId = await _importDataModule.importTaskRepository
              .findSharedTask(share.id);
          if (existingTaskId != null) {
            await _importDataModule.androidShareAdapter.acknowledge(share.id);
            unawaited(_importPipeline.process(existingTaskId));
            continue;
          }
          final controlledPaths = share.localPaths.isEmpty
              ? const <String>[]
              : await _importDataModule.persistPickedImages(share.localPaths);
          final taskId = await _importDataModule.importTaskRepository
              .createSharedTask(
                originalText: share.combinedText,
                controlledLocalPaths: controlledPaths,
                sourceShareId: share.id,
              );
          // 原生分享清单只是交接箱，ImportTask 才是主 App 的正式接管记录。先
          // 持久化任务，再确认并删除清单；进程若在交接期间退出，下次启动仍可重试。
          // sourceShareId 同时用于避免同一份系统分享重复建任务。
          await _importDataModule.androidShareAdapter.acknowledge(share.id);
          unawaited(_importPipeline.process(taskId));
        } catch (_) {
          // 保留原生暂存清单，应用下次启动或恢复前台时再次尝试。
        }
      }
    } finally {
      _isConsumingAndroidShares = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 把真实实现注入到各个 Feature
    return ProviderScope(
      overrides: [
        // 注入菜谱 Feature 需要的依赖
        ...buildRecipeFeatureOverrides(
          _recipeDataModule.recipeRepository,
          collectionRepository: _recipeDataModule.collectionRepository,
          deletionRepository: _recipeDataModule.deletionRepository,
          sortPreferenceRepository: _recipeDataModule.sortPreferenceRepository,
          readingOrderPolicy: _recipeDataModule.readingOrderPolicy,
          personalRecipeConfigRepository:
              _recipeDataModule.personalRecipeConfigRepository,
        ),
        // 注入个人中心需要的依赖
        profileDependenciesProvider.overrideWithValue(
          ProfileDependencies(
            personalRecipeConfigRepository:
                _recipeDataModule.personalRecipeConfigRepository,
            authSessionRepository: _authSessionRepository,
            // 暂无 Apple Developer 付费团队，暂时关闭需要签名能力的 Apple 登录。
            signInWithApple: null,
            signInWithPhone:
                (kDebugMode ||
                    const bool.fromEnvironment(
                      'KITCHEN_NOTES_ENABLE_MOCK_PHONE_AUTH',
                      defaultValue: false,
                    ))
                ? (phone, code) async =>
                      (await _phoneSignInCoordinator.signIn(
                        phone: phone,
                        captchaToken: 'local-captcha-ok',
                        code: code,
                      )).status ==
                      KitchenNotesPhoneSignInStatus.authenticated
                : null,
            clearLocalData: () async {
              await _importDataModule.clearLocalData();
              await _recipeDataModule.clearLocalData();
            },
            exportBackup: () async =>
                (await _backupService.exportBackup()).path,
            restoreBackup: (path) => _backupService.restoreBackup(File(path)),
          ),
        ),
        // 注入导入 Feature 需要的依赖
        importDependenciesProvider.overrideWithValue(
          ImportDependencies(
            repository: _importDataModule.importTaskRepository,
            pipeline: _importPipeline,
            persistPickedImages: _importDataModule.persistPickedImages,
          ),
        ),
      ],
      child: const KitchenNotesApp(),
    );
  }
}

/// 具体 Apple/手机号/微信网关接入前，恢复失败会清除无效凭证并回到失效状态。
final class _UnconfiguredAuthGateway implements KitchenNotesAuthGateway {
  Never _unconfigured() => throw StateError('auth_gateway_not_configured');

  @override
  Future<AuthSessionTokens> authenticate(VerifiedAuthIdentity identity) async =>
      _unconfigured();

  @override
  Future<AuthSessionTokens> refresh(String refreshToken) async =>
      _unconfigured();

  @override
  Future<void> signOutCurrent(String sessionId, String accessToken) async =>
      _unconfigured();

  @override
  Future<void> signOutAll(String accessToken) async => _unconfigured();

  @override
  Future<void> deleteAccount(
    String accessToken, {
    required bool clearLocalData,
  }) async => _unconfigured();

  @override
  Future<List<AuthIdentitySummary>> listIdentities(String accessToken) async =>
      _unconfigured();

  @override
  Future<void> unbindIdentity(String accessToken, String identityId) async =>
      _unconfigured();
}

List<Override> buildRecipeFeatureOverrides(
  RecipeRepository repository, {
  RecipeCollectionRepository? collectionRepository,
  RecipeDeletionRepository? deletionRepository,
  RecipeSortPreferenceRepository? sortPreferenceRepository,
  RecipeReadingOrderPolicy? readingOrderPolicy,
  PersonalRecipeConfigRepository? personalRecipeConfigRepository,
}) {
  // Riverpod override 是根 App 向 Feature 注入依赖的入口。这样 Feature 可以独立测试，
  // 测试时也能用内存实现替换真实数据库。
  return [
    recipeLibraryDependenciesProvider.overrideWithValue(
      RecipeLibraryDependencies(
        watchRecipes: WatchRecipesUseCase(repository),
        getRecipeDetail: GetRecipeDetailUseCase(repository),
        setFavorite: SetRecipeFavoriteUseCase(repository),
        watchCollections: collectionRepository == null
            ? null
            : WatchRecipeCollectionsUseCase(collectionRepository),
        getCollectionDetail: collectionRepository == null
            ? null
            : GetRecipeCollectionDetailUseCase(collectionRepository),
        createCollection: collectionRepository == null
            ? null
            : CreateRecipeCollectionUseCase(collectionRepository),
        updateCollection: collectionRepository == null
            ? null
            : UpdateRecipeCollectionUseCase(collectionRepository),
        deleteCollection: collectionRepository == null
            ? null
            : DeleteRecipeCollectionUseCase(collectionRepository),
        getCollectionIdsForRecipe: collectionRepository == null
            ? null
            : GetCollectionIdsForRecipeUseCase(collectionRepository),
        setCollectionsForRecipe: collectionRepository == null
            ? null
            : SetCollectionsForRecipeUseCase(collectionRepository),
        appendRecipesToCollection: collectionRepository == null
            ? null
            : AppendRecipesToCollectionUseCase(collectionRepository),
        removeRecipeFromCollection: collectionRepository == null
            ? null
            : RemoveRecipeFromCollectionUseCase(collectionRepository),
        restoreRecipeToCollection: collectionRepository == null
            ? null
            : RestoreRecipeToCollectionUseCase(collectionRepository),
        reorderCollectionMembers: collectionRepository == null
            ? null
            : ReorderCollectionMembersUseCase(collectionRepository),
        getCollectionReaderSnapshot:
            collectionRepository == null || readingOrderPolicy == null
            ? null
            : GetRecipeCollectionReaderSnapshotUseCase(
                collectionRepository,
                readingOrderPolicy,
              ),
        getRecipeJournalSummary: GetRecipeJournalSummaryUseCase(repository),
        moveToTrash: deletionRepository == null
            ? null
            : MoveRecipeToTrashUseCase(deletionRepository),
        restoreRecipe: deletionRepository == null
            ? null
            : RestoreRecipeUseCase(deletionRepository),
        permanentlyDeleteRecipe: deletionRepository == null
            ? null
            : PermanentlyDeleteRecipeUseCase(deletionRepository),
        purgeExpiredRecipes: deletionRepository == null
            ? null
            : PurgeExpiredRecipesUseCase(deletionRepository),
        getSortPreference: sortPreferenceRepository == null
            ? null
            : GetRecipeSortPreferenceUseCase(sortPreferenceRepository),
        setSortPreference: sortPreferenceRepository == null
            ? null
            : SetRecipeSortPreferenceUseCase(sortPreferenceRepository),
      ),
    ),
    recipeEditorDependenciesProvider.overrideWithValue(
      RecipeEditorDependencies(
        createRecipe: CreateRecipeUseCase(repository),
        getRecipeDetail: GetRecipeDetailUseCase(repository),
        updateRecipe: UpdateRecipeUseCase(repository),
        personalRecipeConfigRepository: personalRecipeConfigRepository,
      ),
    ),
  ];
}
