import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/cache_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.init();
  runApp(const PocketWisdomApp());
}

class PocketWisdomApp extends StatefulWidget {
  const PocketWisdomApp({super.key});

  @override
  State<PocketWisdomApp> createState() => _PocketWisdomAppState();
}

class _PocketWisdomAppState extends State<PocketWisdomApp> {
  late bool _isDarkTheme;

  @override
  void initState() {
    super.initState();
    _isDarkTheme = CacheService.getDarkTheme();
  }

  Future<void> _handleToggleDarkTheme(bool value) async {
    setState(() => _isDarkTheme = value);
    await CacheService.setDarkTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Wisdom',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashScreen(
        nextScreen: HomeScreen(
          isDarkTheme: _isDarkTheme,
          onToggleDarkTheme: _handleToggleDarkTheme,
        ),
      ),
    );
  }
}