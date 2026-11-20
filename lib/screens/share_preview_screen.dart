import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../widgets/leaf_watermark.dart';

enum ShareCardTheme { forest, sunset, paper, midnight }

class SharePreviewScreen extends StatefulWidget {
  final Quote quote;

  const SharePreviewScreen({super.key, required this.quote});

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  ShareCardTheme _selectedTheme = ShareCardTheme.forest;
  bool _isSquareFormat = false; // false = 4:5 Portrait, true = 1:1 Square
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _justCopied = false;

  Color get _cardBg {
    switch (_selectedTheme) {
      case ShareCardTheme.forest:
        return AppColors.forestGreen;
      case ShareCardTheme.sunset:
        return const Color(0xFFF3E2DA);
      case ShareCardTheme.paper:
        return const Color(0xFFFDFCF9);
      case ShareCardTheme.midnight:
        return const Color(0xFF121A15);
    }
  }

  Color get _cardText {
    switch (_selectedTheme) {
      case ShareCardTheme.forest:
      case ShareCardTheme.midnight:
        return Colors.white;
      case ShareCardTheme.sunset:
      case ShareCardTheme.paper:
        return const Color(0xFF1E2D24);
    }
  }

  Color get _accentColor {
    switch (_selectedTheme) {
      case ShareCardTheme.forest:
      case ShareCardTheme.midnight:
        return AppColors.terracotta;
      case ShareCardTheme.sunset:
        return const Color(0xFFC86D51);
      case ShareCardTheme.paper:
        return AppColors.forestGreen;
    }
  }

  Color get _watermarkColor {
    switch (_selectedTheme) {
      case ShareCardTheme.forest:
        return Colors.white.withValues(alpha: 0.08);
      case ShareCardTheme.midnight:
        return const Color(0xFF8AB899).withValues(alpha: 0.10);
      case ShareCardTheme.sunset:
        return AppColors.terracotta.withValues(alpha: 0.18);
      case ShareCardTheme.paper:
        return AppColors.forestGreen.withValues(alpha: 0.08);
    }
  }

  double _responsiveFontSize(String text) {
    if (_isSquareFormat) {
      if (text.length > 100) return 18.0;
      if (text.length > 70) return 20.5;
      return 23.0;
    }
    if (text.length > 105) return 20.0;
    if (text.length > 75) return 22.5;
    return 25.5;
  }

  Future<void> _shareAsImage() async {
    if (_isSharing) return;
    HapticFeedback.lightImpact();
    setState(() => _isSharing = true);

    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: const ['pocket_wisdom_quote.png'],
          text: '"${widget.quote.text}" — ${widget.quote.author}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _copyText() {
    HapticFeedback.selectionClick();
    Clipboard.setData(
      ClipboardData(text: '"${widget.quote.text}" — ${widget.quote.author}'),
    );
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _justCopied = false);
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final c = messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Copied to clipboard',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) c.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fgColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;

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
          'Share studio',
          style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          // 4:5 Portrait vs 1:1 Square Aspect Ratio Switcher
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isSquareFormat = !_isSquareFormat);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSquareFormat
                          ? Icons.crop_square_rounded
                          : Icons.crop_portrait_rounded,
                      size: 16,
                      color: fgColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSquareFormat ? '1:1' : '4:5',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // 1. Centered Capturable Share Card Preview
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _isSquareFormat ? 1.0 : 0.80,
                    child: RepaintBoundary(
                      key: _cardBoundaryKey,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedTheme == ShareCardTheme.paper
                              ? Border.all(color: const Color(0xFFDCE3DA))
                              : _selectedTheme == ShareCardTheme.midnight
                              ? Border.all(color: const Color(0xFF28392E))
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: LeafWatermark(
                                color: _watermarkColor,
                                size: _isSquareFormat ? 135 : 165,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(_isSquareFormat ? 24 : 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Editorial Accent Quote Mark + Category Tag
                                  Row(
                                    children: [
                                      Text(
                                        '“',
                                        style: TextStyle(
                                          fontSize: 42,
                                          height: 0.85,
                                          fontWeight: FontWeight.w800,
                                          color: _accentColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _cardText.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          widget.quote.category.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: 1.1,
                                            fontWeight: FontWeight.w600,
                                            color:
                                            _cardText.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Text(
                                        widget.quote.text,
                                        style: TextStyle(
                                          fontSize: _responsiveFontSize(
                                              widget.quote.text),
                                          height: 1.36,
                                          fontWeight: FontWeight.w500,
                                          color: _cardText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Subtle Terracotta Accent Divider
                                  Container(
                                    width: 32,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: _accentColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.quote.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: _cardText.withValues(alpha: 0.92),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.eco_rounded,
                                        size: 13,
                                        color: _accentColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'POCKET WISDOM',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w600,
                                          color:
                                          _cardText.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. 4 Designer Theme Swatches
              Row(
                children: [
                  _buildThemeOption(
                    theme: ShareCardTheme.forest,
                    label: 'Forest',
                    swatchBg: AppColors.forestGreen,
                    swatchText: Colors.white,
                    labelColor: subColor,
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    theme: ShareCardTheme.sunset,
                    label: 'Sunset',
                    swatchBg: const Color(0xFFF3E2DA),
                    swatchText: const Color(0xFF1E2D24),
                    labelColor: subColor,
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    theme: ShareCardTheme.paper,
                    label: 'Paper',
                    swatchBg: const Color(0xFFFDFCF9),
                    swatchText: const Color(0xFF1E2D24),
                    labelColor: subColor,
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    theme: ShareCardTheme.midnight,
                    label: 'Midnight',
                    swatchBg: const Color(0xFF121A15),
                    swatchText: Colors.white,
                    labelColor: subColor,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Primary "Share as image" Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _shareAsImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.lightTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  label: Text(
                    _isSharing ? 'Rendering 3x PNG...' : 'Share as image',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. Secondary Animated "Copy text" Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _copyText,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fgColor,
                    side: BorderSide(
                      color:
                      _justCopied ? AppColors.forestGreen : borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _justCopied
                          ? Icons.check_rounded
                          : Icons.copy_rounded,
                      key: ValueKey(_justCopied),
                      size: 19,
                      color: _justCopied ? AppColors.terracotta : fgColor,
                    ),
                  ),
                  label: Text(
                    _justCopied ? 'Copied to clipboard!' : 'Copy text',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required ShareCardTheme theme,
    required String label,
    required Color swatchBg,
    required Color swatchText,
    required Color labelColor,
  }) {
    final isSelected = _selectedTheme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTheme = theme);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              decoration: BoxDecoration(
                color: swatchBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.terracotta
                      : const Color(0xFFD4DDD2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '”',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: swatchText,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 5,
                      right: 6,
                      child: Icon(Icons.check, size: 13, color: swatchText),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}