import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/calendar_month_view.dart';
import 'screens/timeline_day_view.dart';
import 'screens/memo_view.dart';
import 'utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const TaskCalendarApp(),
    ),
  );
}

class TaskCalendarApp extends StatelessWidget {
  const TaskCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;

    return MaterialApp(
      title: 'TODOアプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: darkMode ? Brightness.dark : Brightness.light,
        colorSchemeSeed: kThemeColor,
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          displayMedium: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          displaySmall: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          headlineLarge: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          headlineSmall: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          labelLarge: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w500),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: prov.darkMode
          ? const Color(0xFF111827)
          : kBgColor,
      body: SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w500,
            color: prov.darkMode ? Colors.white : Colors.grey[800],
          ),
          child: Column(
          children: [
            // Header
            _Header(darkMode: prov.darkMode),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildCurrentView(prov.currentView),
              ),
            ),
            // Footer navigation
            _Footer(prov: prov),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(AppView view) {
    switch (view) {
      case AppView.calendar:
        return const CalendarMonthView();
      case AppView.day:
        return const TimelineDayView();
      case AppView.memo:
        return const MemoView();
    }
  }
}

class _Header extends StatelessWidget {
  final bool darkMode;
  const _Header({required this.darkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo image
          Image.asset(
            'assets/logo.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'TODOアプリ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
              color: darkMode ? Colors.white : kDarkTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final AppProvider prov;
  const _Footer({required this.prov});

  @override
  Widget build(BuildContext context) {
    final isCalendarActive =
        prov.currentView == AppView.calendar || prov.currentView == AppView.day;
    final isMemoActive = prov.currentView == AppView.memo;

    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: prov.darkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Calendar tab
          Expanded(
            child: _FooterTab(
              icon: Icons.check_box,
              label: 'カレンダー',
              active: isCalendarActive,
              darkMode: prov.darkMode,
              onTap: () => prov.setCurrentView(AppView.calendar),
            ),
          ),
          // Memo tab
          Expanded(
            child: _FooterTab(
              icon: Icons.description,
              label: 'メモ帳',
              active: isMemoActive,
              darkMode: prov.darkMode,
              onTap: () => prov.setCurrentView(AppView.memo),
            ),
          ),
          // Google Map link
          Expanded(
            child: _FooterTab(
              icon: Icons.map,
              label: 'Google Map',
              active: false,
              darkMode: prov.darkMode,
              onTap: () async {
                final url = Uri.parse('https://www.google.com/maps');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool darkMode;
  final VoidCallback onTap;

  const _FooterTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (darkMode ? const Color(0xFF60A5FA) : kThemeColor)
        : Colors.grey[400]!.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
