import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quote.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_quote_sheet.dart';
import 'share_preview_screen.dart';

class SavedQuotesScreen extends StatefulWidget {
  const SavedQuotesScreen({super.key});

  @override
  State<SavedQuotesScreen> createState() => _SavedQuotesScreenState();
}

class _SavedQuotesScreenState extends State<SavedQuotesScreen> {
  late List<String> _savedIds;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _savedIds = CacheService.getSavedQuoteIds();
  }

  Future<void> _removeQuote(Quote quote) async {
    HapticFeedback.mediumImpact();
    final updated = await CacheService.toggleSaveQuote(quote.id);
    setState(() => _savedIds = updated);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Removed from favorites.',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () async {
            final restored = await CacheService.toggleSaveQuote(quote.id);
            if (mounted) {
              setState(() => _savedIds = restored);
            }
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) controller.close();
    });
  }

  Future<void> _deleteCustomQuote(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete personal quote?'),
        content: const Text(
          'This will permanently delete your custom quote from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    await CacheService.deleteCustomQuote(quote.id);
    setState(() {
      _savedIds = CacheService.getSavedQuoteIds();
    });

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final c = messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Personal quote deleted.',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final fgColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final pillBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final quoteById = {
      for (final q in CacheService.getAllAvailableQuotes()) q.id: q
    };
    final List<Quote> allSavedQuotes =
    _savedIds.map((id) => quoteById[id]).whereType<Quote>().toList();

    final availableCategories = <String>{
      'All',
      ...allSavedQuotes.map((q) => q.category),
    };
    final activeCategory = availableCategories.contains(_selectedCategory)
        ? _selectedCategory
        : 'All';

    final List<Quote> displayedQuotes = activeCategory == 'All'
        ? allSavedQuotes
        : allSavedQuotes.where((q) => q.category == activeCategory).toList();

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
          'Saved quotes',
          style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: allSavedQuotes.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 52,
                  color: isDark
                      ? const Color(0xFF8AB899)
                      : AppColors.forestGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nothing saved yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart on a quote you love.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco_outlined, color: fgColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Your little collection',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${allSavedQuotes.length} saved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Words worth keeping.',
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                ],
              ),
            ),

            // Category filter pills (shown when 2+ quotes are saved)
            if (allSavedQuotes.length >= 2) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: quoteCategories
                      .where((c) => availableCategories.contains(c))
                      .length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final visibleCats = quoteCategories
                        .where((c) => availableCategories.contains(c))
                        .toList();
                    final cat = visibleCats[index];
                    final selected = cat == activeCategory;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.forestGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.forestGreen
                                : borderColor,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected ? Colors.white : subColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Saved Cards List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: displayedQuotes.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == displayedQuotes.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 24),
                      child: Center(
                        child: Text(
                          'Keep the words that stay with you.',
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                      ),
                    );
                  }

                  final quote = displayedQuotes[index];
                  final isCustom = quote.category == 'My Quotes';

                  return GestureDetector(
                    onLongPress: () {
                      HapticFeedback.selectionClick();
                      Clipboard.setData(
                        ClipboardData(
                          text: '"${quote.text}" — ${quote.author}',
                        ),
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      final c = messenger.showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Copied to clipboard',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.forestGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin:
                          const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        ),
                      );
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) c.close();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF8AB899)
                                    : AppColors.forestGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quote.text,
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                      color: fgColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          quote.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: subColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pillBg,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          quote.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: fgColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Action Column: Heart/Delete + Share Studio + Edit (for My Quotes)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => isCustom
                                      ? _deleteCustomQuote(quote)
                                      : _removeQuote(quote),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border:
                                      Border.all(color: borderColor),
                                    ),
                                    child: Icon(
                                      isCustom
                                          ? Icons.delete_outline_rounded
                                          : Icons.favorite_rounded,
                                      color: AppColors.terracotta,
                                      size: 19,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SharePreviewScreen(
                                                quote: quote),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border:
                                      Border.all(color: borderColor),
                                    ),
                                    child: Icon(
                                      Icons.ios_share_rounded,
                                      color: subColor,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                if (isCustom) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      HapticFeedback.selectionClick();
                                      final updated =
                                      await showModalBottomSheet<
                                          Quote>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor:
                                        Colors.transparent,
                                        builder: (_) => AddQuoteSheet(
                                            existingQuote: quote),
                                      );
                                      if (updated != null && mounted) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        border: Border.all(
                                            color: borderColor),
                                      ),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        color: subColor,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}