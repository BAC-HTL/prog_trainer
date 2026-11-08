import 'package:flutter/material.dart';

import 'achievements_screen.dart';
import 'challenges_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Hauptgerüst mit unterer Navigation: Lernen, Herausforderungen, Erfolge.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tab = 0;

  static const _titles = ['Lernen', 'Herausforderungen', 'Erfolge'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          ChallengesScreen(),
          AchievementsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school), label: 'Lernen'),
          NavigationDestination(
              icon: Icon(Icons.extension), label: 'Herausforderungen'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Erfolge'),
        ],
      ),
    );
  }
}
