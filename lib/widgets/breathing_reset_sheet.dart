import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BreathingResetSheet extends StatefulWidget {
  const BreathingResetSheet({super.key});

  @override
  State<BreathingResetSheet> createState() => _BreathingResetSheetState();
}

class _BreathingResetSheetState extends State<BreathingResetSheet>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 60;
  late final AnimationController _cycleController;
  Timer? _countdownTimer;
  int _secondsLeft = _totalSeconds;
  String _lastPhase = 'Inhale';
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    // 12-second loop: 4s Inhale (0.0 -> 0.333), 4s Hold (0.333 -> 0.666), 4s Exhale (0.666 -> 1.0)
    _cycleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addListener(_handlePhaseHaptics);

    HapticFeedback.lightImpact();
    _cycleController.repeat();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _cycleController.stop();
        HapticFeedback.mediumImpact();
        setState(() {
          _secondsLeft = 0;
          _completed = true;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handlePhaseHaptics() {
    final currentPhase = _phaseLabel(_cycleController.value);
    if (currentPhase != _lastPhase) {
      _lastPhase = currentPhase;
      if (currentPhase == 'Inhale') {
        HapticFeedback.lightImpact();
      } else if (currentPhase == 'Hold') {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  String _phaseLabel(double t) {
    if (t < 1 / 3) return 'Inhale';
    if (t < 2 / 3) return 'Hold';
    return 'Exhale';
  }

  String _phaseHint(double t) {
    if (t < 1 / 3) return 'Breathe in slowly through your nose';
    if (t < 2 / 3) return 'Rest gently at the top';
    return 'Release all tension smoothly';
  }

  double _circleScale(double t) {
    if (t < 1 / 3) {
      final p = Curves.easeInOutSine.transform(t * 3);
      return 0.62 + (0.38 * p); // 0.62 -> 1.00
    } else if (t < 2 / 3) {
      return 1.00; // Hold expanded
    } else {
      final p = Curves.easeInOutSine.transform((t - 2 / 3) * 3);
      return 1.00 - (0.38 * p); // 1.00 -> 0.62
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cycleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkCard : AppColors.lightBg;
    final fgColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.air_rounded,
                color: isDark ? const Color(0xFF8AB899) : AppColors.forestGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Pause & Breathe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _completed ? 'Done' : '${_secondsLeft}s',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Animated Forest Breathing Circle
          SizedBox(
            width: 210,
            height: 210,
            child: AnimatedBuilder(
              animation: _cycleController,
              builder: (context, _) {
                final t = _cycleController.value;
                final scale = _completed ? 0.85 : _circleScale(t);
                final label = _completed ? 'Centered' : _phaseLabel(t);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer subtle ring
                    Container(
                      width: 204,
                      height: 204,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.forestGreen.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Expanding/contracting Forest circle
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 196,
                        height: 196,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.forestGreen,
                          boxShadow: [
                            BoxShadow(
                              color:
                              AppColors.forestGreen.withValues(alpha: 0.28),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _completed ? 'Ready when you are' : '4s · 4s · 4s',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 22),

          AnimatedBuilder(
            animation: _cycleController,
            builder: (context, _) {
              final hint = _completed
                  ? 'One quiet minute makes the rest of the day clearer.'
                  : _phaseHint(_cycleController.value);
              return Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subColor),
              );
            },
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: fgColor,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _completed ? 'Return to Quotes' : 'Close',
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}