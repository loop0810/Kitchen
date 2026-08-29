import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

const _tabIconSize = 25.0;
const _tabBarHeight = 68.0;
const _tabItemHeight = 50.0;
const _tabItemHorizontalPadding = 4.0;
const _tabItemVerticalPadding = 9.0;

Widget _tabIcon(String assetPath) {
  return SizedBox(
    width: _tabIconSize,
    height: _tabIconSize,
    child: Image.asset(
      assetPath,
      width: _tabIconSize,
      height: _tabIconSize,
      fit: BoxFit.contain,
      // NavigationDestination 已提供 Tab 语义，避免图片再次生成重复读屏内容。
      excludeFromSemantics: true,
    ),
  );
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _MainTabBar(
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          navigationShell.goBranch(
            index,
            // 再次点击当前 Tab 时回到该分支的初始页；切换 Tab 时则恢复原导航栈。
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _MainTabBar extends StatelessWidget {
  const _MainTabBar({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const _labels = ['首页', '菜谱库', '导入箱', '我的'];
  static const _selectedAssets = [
    'assets/images/tab_home_selected.png',
    'assets/images/tab_recipe_library_selected.png',
    'assets/images/tab_import_inbox_selected.png',
    'assets/images/tab_profile_selected.png',
  ];
  static const _unselectedAssets = [
    'assets/images/tab_home_unselected.png',
    'assets/images/tab_recipe_library_unselected.png',
    'assets/images/tab_import_inbox_unselected.png',
    'assets/images/tab_profile_unselected.png',
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('main-tab-bar'),
      decoration: const BoxDecoration(
        color: AppColor.paper,
        border: Border(top: BorderSide(color: AppColor.butter)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _tabBarHeight,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: Row(
              children: [
                for (var index = 0; index < _labels.length; index++)
                  Expanded(
                    child: _MainTabItem(
                      index: index,
                      label: _labels[index],
                      selected: index == selectedIndex,
                      selectedAsset: _selectedAssets[index],
                      unselectedAsset: _unselectedAssets[index],
                      onTap: () => onTabSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainTabItem extends StatelessWidget {
  const _MainTabItem({
    required this.index,
    required this.label,
    required this.selected,
    required this.selectedAsset,
    required this.unselectedAsset,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final String selectedAsset;
  final String unselectedAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key('main-tab-$index'),
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _tabItemHorizontalPadding,
          vertical: _tabItemVerticalPadding,
        ),
        child: Material(
          key: selected ? const Key('main-tab-selected-indicator') : null,
          color: selected ? AppColor.blush : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.r14),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: SizedBox(
              height: _tabItemHeight,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tabIcon(selected ? selectedAsset : unselectedAsset),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColor.coral : AppColor.ink,
                      fontSize: AppText.label,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
