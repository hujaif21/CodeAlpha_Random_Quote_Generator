import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pocket_logo.dart';

class AboutScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Future<void> Function(bool) onToggleDarkTheme;

  const AboutScreen({
    super.key,
    required this.isDarkTheme,
    required this.onToggleDarkTheme,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late bool _dark;
  late bool _dailyReminder;

  @override
  void initState() {
    super.initState();
    _dark = CacheService.getDarkTheme();
    _dailyReminder = CacheService.getDailyReminder();
  }

  void _showToast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) controller.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || _dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fgColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: fgColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: fgColor,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Brand Header Card
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                      ),
                      child: PocketLogo(
                        size: 76,
                        primaryColor: isDark
                            ? const Color(0xFF8AB899)
                            : AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pocket Wisdom',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A little wisdom, always with you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Story & Features Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMALL APP. LASTING WORDS.',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Built for the CodeAlpha App Development Internship',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.38,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A mindful pause in your day, one quote at a time.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: subColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(color: borderColor, height: 1),
                    ),
                    _featureRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Fresh words, whenever you need them',
                      surfaceColor: surfaceColor,
                      iconColor: isDark
                          ? const Color(0xFF8AB899)
                          : AppColors.forestGreen,
                      fgColor: fgColor,
                    ),
                    const SizedBox(height: 14),
                    _featureRow(
                      icon: Icons.favorite_border_rounded,
                      title: 'Keep your favorites close',
                      surfaceColor: surfaceColor,
                      iconColor: AppColors.terracotta,
                      fgColor: fgColor,
                    ),
                    const SizedBox(height: 14),
                    _featureRow(
                      icon: Icons.ios_share_rounded,
                      title: 'Share a little perspective',
                      surfaceColor: surfaceColor,
                      iconColor: isDark
                          ? const Color(0xFF8AB899)
                          : AppColors.forestGreen,
                      fgColor: fgColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Appearance / Dark Theme Toggle Card
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark
                            ? AppColors.terracotta
                            : AppColors.forestGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: fgColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'A softer glow after hours',
                            style: TextStyle(
                              fontSize: 13,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.terracotta,
                      inactiveThumbColor: AppColors.forestGreen,
                      inactiveTrackColor: AppColors.lightSurface,
                      onChanged: (val) async {
                        HapticFeedback.selectionClick();
                        setState(() => _dark = val);
                        await widget.onToggleDarkTheme(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Daily Quote Notification Card
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: isDark
                                ? const Color(0xFF8AB899)
                                : AppColors.forestGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily wisdom reminder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: fgColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'A quiet quote every morning at 8:30 AM',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _dailyReminder,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.terracotta,
                          inactiveThumbColor: AppColors.forestGreen,
                          inactiveTrackColor: AppColors.lightSurface,
                          onChanged: (val) async {
                            HapticFeedback.selectionClick();
                            setState(() => _dailyReminder = val);
                            await CacheService.setDailyReminder(val);
                            if (val) {
                              await NotificationService.scheduleDailyQuote();
                              if (mounted) {
                                _showToast('Daily 8:30 AM reminder scheduled.');
                              }
                            } else {
                              await NotificationService.cancelDailyQuote();
                              if (mounted) {
                                _showToast('Daily reminder turned off.');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final sent = await NotificationService.showInstantQuoteNotification();
                          if (!mounted) return;
                          if (sent) {
                            _showToast('Check your notification bar!');
                          } else {
                            _showToast('Enable notifications in Phone Settings > Apps > Pocket Wisdom.');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: fgColor,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text(
                          'Send sample notification now',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Designed for a little more calm.',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.2,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required Color surfaceColor,
    required Color iconColor,
    required Color fgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: fgColor,
            ),
          ),
        ),
      ],
    );
  }
}