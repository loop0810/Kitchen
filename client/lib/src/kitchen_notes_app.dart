import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_notes/src/navigation/kitchen_notes_app_router.dart';
import 'package:kitchen_profile/kitchen_profile.dart';

const _appBackgroundAsset = 'assets/images/app_background_paper_grid.png';

class KitchenNotesApp extends ConsumerWidget {
  const KitchenNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visualStyle = ref.watch(visualStyleProvider);

    return MaterialApp.router(
      title: '厨房手记',
      debugShowCheckedModeBanner: false,
      // 根 App 负责背景图层，页面 Scaffold 透明后才能让各页面共享同一张纸张背景。
      theme: AppTheme.forStyle(
        visualStyle,
      ).copyWith(scaffoldBackgroundColor: Colors.transparent),
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_appBackgroundAsset),
            fit: BoxFit.cover,
          ),
        ),
        child: SizedBox.expand(child: child),
      ),
      routerConfig: appRouter,
    );
  }
}
