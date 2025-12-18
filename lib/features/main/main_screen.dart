import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../camera/camera_screen.dart';
import '../history/history_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final screens = [
      const CameraScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) => ref.read(navigationIndexProvider.notifier).state = index,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.camera_alt_outlined),
                    activeIcon: Icon(Icons.camera_alt),
                    label: 'Camera',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.photo_library_outlined),
                    activeIcon: Icon(Icons.photo_library),
                    label: 'Album',
                  ),
                ],
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white.withOpacity(0.4),
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
              ),
            ),
          ),
        ),
      ),
    );

  }
}
