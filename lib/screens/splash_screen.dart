import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/pocket_logo.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pocketScale;
  late final Animation<double> _stitchDraw;
  late final Animation<double> _sproutGrow;
  late final Animation<double> _leavesFloat;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pocketScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
    );

    _stitchDraw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.70, curve: Curves.easeInOutCubic),
    );

    _sproutGrow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.85, curve: Curves.elasticOut),
    );

    _leavesFloat = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.98, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.98, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Wait 500ms so Android 12+ native splash overlay fully dismisses first
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await _controller.forward();
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final titleColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final floatOffset = math.sin(_leavesFloat.value * math.pi) * 8;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _pocketScale.value.clamp(0.0, 1.0),
                        child: Container(
                          width: 145 * _pocketScale.value,
                          height: 145 * _pocketScale.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forestGreen.withValues(
                                    alpha: isDark ? 0.28 : 0.09),
                                blurRadius: 48,
                                spreadRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 44 - floatOffset,
                        child: Opacity(
                          opacity: (_leavesFloat.value * 0.45).clamp(0.0, 0.45),
                          child: Transform.rotate(
                            angle: -0.3 + (_leavesFloat.value * 0.25),
                            child: Icon(Icons.eco_outlined,
                                size: 16, color: subColor),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 26,
                        top: 18 - floatOffset,
                        child: Opacity(
                          opacity: (_leavesFloat.value * 0.45).clamp(0.0, 0.45),
                          child: Transform.rotate(
                            angle: 0.4 - (_leavesFloat.value * 0.25),
                            child: Icon(Icons.eco_outlined,
                                size: 15, color: subColor),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 38,
                        bottom: 14 - floatOffset,
                        child: Opacity(
                          opacity: (_leavesFloat.value * 0.45).clamp(0.0, 0.45),
                          child: Transform.rotate(
                            angle: 0.2 + (_leavesFloat.value * 0.3),
                            child: Icon(Icons.eco_outlined,
                                size: 16, color: subColor),
                          ),
                        ),
                      ),
                      PocketLogo(
                        size: 132,
                        pocketScale: _pocketScale.value.clamp(0.0, 1.15),
                        stitchProgress: _stitchDraw.value,
                        sproutProgress: _sproutGrow.value.clamp(0.0, 1.12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'Pocket Wisdom',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A little wisdom, always with you.',
                          style: TextStyle(
                            fontSize: 15,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}