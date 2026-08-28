import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _tabIconSize = 25.0;

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            // 再次点击当前 Tab 时回到该分支的初始页；切换 Tab 时则恢复原导航栈。
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: _tabIcon('assets/images/tab_home_unselected.png'),
            selectedIcon: _tabIcon('assets/images/tab_home_selected.png'),
            label: '首页',
          ),
          NavigationDestination(
            icon: _tabIcon('assets/images/tab_recipe_library_unselected.png'),
            selectedIcon: _tabIcon(
              'assets/images/tab_recipe_library_selected.png',
            ),
            label: '菜谱库',
          ),
          NavigationDestination(
            icon: _tabIcon('assets/images/tab_import_inbox_unselected.png'),
            selectedIcon: _tabIcon(
              'assets/images/tab_import_inbox_selected.png',
            ),
            label: '导入箱',
          ),
          NavigationDestination(
            icon: _tabIcon('assets/images/tab_profile_unselected.png'),
            selectedIcon: _tabIcon('assets/images/tab_profile_selected.png'),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
