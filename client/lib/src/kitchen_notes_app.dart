import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_notes/src/navigation/kitchen_notes_app_router.dart';
import 'package:kitchen_profile/kitchen_profile.dart';

class KitchenNotesApp extends ConsumerWidget {
  const KitchenNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visualStyle = ref.watch(visualStyleProvider);

    return MaterialApp.router(
      title: '厨房手记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forStyle(visualStyle),
      routerConfig: appRouter,
    );
  }
}
