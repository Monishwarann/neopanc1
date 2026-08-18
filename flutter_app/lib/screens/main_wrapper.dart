import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dashboard_screen.dart';
import 'prediction_screen.dart';
import 'sensor_screen.dart';
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainWrapperState>();
    state?.setIndex(index);
  }

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PredictionScreen(),
    const SensorScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: theme.primaryColor.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: Icon(CupertinoIcons.home, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              selectedIcon: Icon(CupertinoIcons.house_fill, color: theme.primaryColor),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.waveform_path_ecg, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              selectedIcon: Icon(CupertinoIcons.waveform_path_ecg, color: theme.primaryColor),
              label: 'Predict',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.antenna_radiowaves_left_right, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              selectedIcon: Icon(CupertinoIcons.antenna_radiowaves_left_right, color: theme.primaryColor),
              label: 'IoT',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.person, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              selectedIcon: Icon(CupertinoIcons.person_solid, color: theme.primaryColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
