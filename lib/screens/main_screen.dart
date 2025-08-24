import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'timeline_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'topic_tags_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const TimelineScreen(),
      HistoryScreen(
        onNavigateToHome: () {
          setState(() {
            _currentIndex = 0; // 切换到首页
          });
        },
      ),
      const AnalyticsScreen(),
      const TopicTagsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: '时间线',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '分析',
          ),
          NavigationDestination(
            icon: Icon(Icons.tag_outlined),
            selectedIcon: Icon(Icons.tag),
            label: '标签',
          ),
        ],
      ),
    );
  }
}