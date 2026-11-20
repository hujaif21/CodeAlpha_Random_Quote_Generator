import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quote.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_quote_sheet.dart';
import '../widgets/breathing_reset_sheet.dart';
import '../widgets/leaf_watermark.dart';
import 'about_screen.dart';
import 'saved_quotes_screen.dart';
import 'share_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Future<void> Function(bool) onToggleDarkTheme;

  const HomeScreen({
    super.key,
    required this.isDarkTheme,
    required this.onToggleDarkTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  String _selectedCategory = 'All';
  Quote? _currentQuote;
  late List<String> _savedIds;

  final Map<String, List<Quote>> _categoryDeck = {};
  final Map<String, int> _categoryIndex = {};

  StreamSubscription<String>? _notifSub;
  bool _justCopied = false;

  // Swipe drag & fly-off animation
  late final AnimationController _swipeController;
  Offset _dragOffset = Offset.zero;
  Offset _flyStartOffset = Offset.zero;
  Offset _flyEndOffset = Offset.zero;
  bool _isFlyingOut = false;

  // Double-tap heart burst animation
  late final AnimationController _heartBurstController;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _savedIds = CacheService.getSavedQuoteIds();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          _flyStartOffset,
          _flyEndOffset,
          Curves.easeOutCubic.transform(_swipeController.value),
        )!;
      });
    });

    _heartBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0),
        weight: 50,
      ),
    ]).animate(_heartBurstController);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.95), weight: 25),
      TweenSequenceItem(tween: ConstantTween(0.95), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 0.0), weight: 30),
    ]).animate(_heartBurstController);

    _initDeckForCategory('All', avoidLastId: CacheService.getLastQuoteId());
    final initialDeck = _categoryDeck['All']!;
    _currentQuote = initialDeck.isNotEmpty ? initialDeck[0] : null;
    if (_currentQuote != null) {
      CacheService.setLastQuoteId(_currentQuote!.id);
    }

    if (NotificationService.initialQuoteId != null) {
      _openQuoteById(NotificationService.initialQuoteId!);
      NotificationService.initialQuoteId = null;
    }

    _notifSub = NotificationService.onQuoteTapped.stream.listen((quoteId) {
      if (mounted) {
        _openQuoteById(quoteId);
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _swipeController.dispose();
    _heartBurstController.dispose();
    super.dispose();
  }

  void _openQuoteById(String quoteId) {
    final available = CacheService.getAllAvailableQuotes();
    final match = available.where((q) => q.id == quoteId).firstOrNull;
    if (match == null) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    final deck = _categoryDeck['All']!;
    final idxInDeck = deck.indexWhere((q) => q.id == match.id);
    if (idxInDeck != -1) {
      _categoryIndex['All'] = idxInDeck;
    }

    setState(() {
      _selectedCategory = 'All';
      _currentQuote = match;
      _dragOffset = Offset.zero;
      _isFlyingOut = false;
      _justCopied = false;
    });
    CacheService.setLastQuoteId(match.id);
    NotificationService.initialQuoteId = null;
  }

  void _initDeckForCategory(String category, {String? avoidLastId}) {
    final allAvailable = CacheService.getAllAvailableQuotes();
    final pool = category == 'All'
        ? List<Quote>.from(allAvailable)
        : allAvailable.where((q) => q.category == category).toList();

    if (category != 'My Quotes') {
      pool.shuffle(_random);
    }

    if (avoidLastId != null &&
        pool.length > 1 &&
        pool.first.id == avoidLastId) {
      final first = pool.removeAt(0);
      pool.add(first);
    }

    _categoryDeck[category] = pool;
    _categoryIndex[category] = 0;
  }

  void _advanceToNextQuote() {
    final deck = _categoryDeck[_selectedCategory] ?? [];
    if (deck.isEmpty) return;

    final nextIdx = ((_categoryIndex[_selectedCategory] ?? 0) + 1) % deck.length;
    _categoryIndex[_selectedCategory] = nextIdx;

    setState(() {
      _currentQuote = deck[nextIdx];
      _dragOffset = Offset.zero;
      _isFlyingOut = false;
      _justCopied = false;
    });
    CacheService.setLastQuoteId(_currentQuote!.id);
  }

  Future<void> _animateCardOut({double direction = -1.0}) async {
    final deck = _categoryDeck[_selectedCategory] ?? [];
    if (_isFlyingOut || deck.isEmpty) return;

    HapticFeedback.lightImpact();
    _isFlyingOut = true;
    final screenWidth = MediaQuery.of(context).size.width;
    _flyStartOffset = _dragOffset;
    _flyEndOffset = Offset(direction * screenWidth * 1.25, _dragOffset.dy * 0.5);

    await _swipeController.forward(from: 0.0);
    _advanceToNextQuote();
  }

  void _snapCardBack() {
    _flyStartOffset = _dragOffset;
    _flyEndOffset = Offset.zero;
    _swipeController.forward(from: 0.0);
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    HapticFeedback.selectionClick();
    if (!_categoryDeck.containsKey(category) || category == 'My Quotes') {
      _initDeckForCategory(category);
    }
    final deck = _categoryDeck[category]!;
    setState(() {
      _selectedCategory = category;
      final idx = _categoryIndex[category] ?? 0;
      _currentQuote = deck.isNotEmpty ? deck[idx] : null;
      _dragOffset = Offset.zero;
      _justCopied = false;
    });
    if (_currentQuote != null) {
      CacheService.setLastQuoteId(_currentQuote!.id);
    }
  }

  Future<void> _openAddQuoteSheet() async {
    HapticFeedback.selectionClick();
    final created = await showModalBottomSheet<Quote>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddQuoteSheet(),
    );

    if (created != null && mounted) {
      _initDeckForCategory('All');
      _initDeckForCategory('My Quotes');
      setState(() {
        _savedIds = CacheService.getSavedQuoteIds();
        _selectedCategory = 'My Quotes';
        _currentQuote = created;
        _dragOffset = Offset.zero;
        _justCopied = false;
      });
      CacheService.setLastQuoteId(created.id);
      _showForestToast('Added to My Quotes!');
    }
  }

  Future<void> _editCurrentCustomQuote() async {
    final quote = _currentQuote;
    if (quote == null || quote.category != 'My Quotes') return;

    HapticFeedback.selectionClick();
    final updated = await showModalBottomSheet<Quote>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddQuoteSheet(existingQuote: quote),
    );

    if (updated != null && mounted) {
      _initDeckForCategory('All');
      _initDeckForCategory('My Quotes');
      setState(() {
        _currentQuote = updated;
        _dragOffset = Offset.zero;
      });
      _showForestToast('Quote updated.');
    }
  }

  Future<void> _deleteCurrentCustomQuote() async {
    final quote = _currentQuote;
    if (quote == null || quote.category != 'My Quotes') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete personal quote?'),
        content: const Text(
          'This will permanently remove this quote from My Quotes and Favorites.',
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

    _initDeckForCategory('All');
    _initDeckForCategory('My Quotes');
    final activeDeck = _categoryDeck[_selectedCategory] ?? [];

    setState(() {
      _savedIds = CacheService.getSavedQuoteIds();
      _currentQuote = activeDeck.isNotEmpty ? activeDeck[0] : null;
      _dragOffset = Offset.zero;
    });

    if (_currentQuote != null) {
      CacheService.setLastQuoteId(_currentQuote!.id);
    }
    _showForestToast('Personal quote deleted.');
  }

  void _openBreathingSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BreathingResetSheet(),
    );
  }

  Future<void> _toggleSaveCurrent({bool fromDoubleTap = false}) async {
    final quote = _currentQuote;
    if (quote == null) return;

    HapticFeedback.mediumImpact();
    if (fromDoubleTap) {
      _heartBurstController.forward(from: 0.0);
      if (_savedIds.contains(quote.id)) return;
    }

    final updated = await CacheService.toggleSaveQuote(quote.id);
    final nowSaved = updated.contains(quote.id);
    setState(() => _savedIds = updated);

    if (!mounted) return;
    _showForestToast(
      nowSaved ? 'Saved to your collection.' : 'Removed from favorites.',
    );
  }

  void _showForestToast(String message) {
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

  String _formattedToday() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return "TODAY'S PICK · ${months[now.month - 1]} ${now.day}";
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'All':
        return Icons.grid_view_rounded;
      case 'My Quotes':
        return Icons.edit_note_rounded;
      case 'Motivation':
        return Icons.local_fire_department_outlined;
      case 'Focus':
        return Icons.adjust_rounded;
      case 'Wisdom':
        return Icons.auto_awesome_outlined;
      case 'Calm':
        return Icons.spa_outlined;
      case 'Learning':
        return Icons.menu_book_rounded;
      case 'Resilience':
        return Icons.shield_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  double _responsiveQuoteFontSize(String text) {
    if (text.length > 100) return 19.5;
    if (text.length > 75) return 22.0;
    return 25.5;
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

    final deck = _categoryDeck[_selectedCategory] ?? [];
    final currentIdx = _categoryIndex[_selectedCategory] ?? 0;
    final quote = _currentQuote;
    final isSaved = quote != null && _savedIds.contains(quote.id);
    final nextQuote =
    deck.isNotEmpty ? deck[(currentIdx + 1) % deck.length] : null;

    final swipeAngle = (_dragOffset.dx / 380).clamp(-0.18, 0.18);
    final dragProgress = (_dragOffset.dx.abs() / 160).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    color: isDark
                        ? const Color(0xFF8AB899)
                        : AppColors.forestGreen,
                    size: 25,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pocket Wisdom',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ),
                  // 60s Pause & Breathe Button
                  IconButton(
                    tooltip: 'Pause & Breathe (60s)',
                    visualDensity: VisualDensity.compact,
                    onPressed: _openBreathingSheet,
                    icon: Icon(Icons.air_rounded, color: fgColor, size: 22),
                  ),
                  // Write Your Own Quote Button
                  IconButton(
                    tooltip: 'Write your own quote',
                    visualDensity: VisualDensity.compact,
                    onPressed: _openAddQuoteSheet,
                    icon: Icon(Icons.edit_note_rounded, color: fgColor, size: 24),
                  ),
                  // About & Notifications Button
                  IconButton(
                    tooltip: 'About & Reminders',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AboutScreen(
                            isDarkTheme: CacheService.getDarkTheme(),
                            onToggleDarkTheme: widget.onToggleDarkTheme,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.info_outline_rounded,
                        color: fgColor, size: 22),
                  ),
                  const SizedBox(width: 4),
                  // Saved Favorites Heart Button
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedQuotesScreen(),
                        ),
                      );
                      if (mounted) {
                        _initDeckForCategory('All');
                        _initDeckForCategory('My Quotes');
                        final refreshedDeck =
                            _categoryDeck[_selectedCategory] ?? [];
                        final matchingQuote = _currentQuote == null
                            ? null
                            : refreshedDeck
                            .where((q) => q.id == _currentQuote!.id)
                            .firstOrNull;
                        setState(() {
                          _savedIds = CacheService.getSavedQuoteIds();
                          _currentQuote = matchingQuote ??
                              (refreshedDeck.isNotEmpty
                                  ? refreshedDeck[0]
                                  : null);
                        });
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            color: fgColor,
                            size: 21,
                          ),
                        ),
                        if (_savedIds.isNotEmpty)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_savedIds.length}',
                                style: const TextStyle(
                                  color: AppColors.lightTextPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Category Chips (includes 'My Quotes')
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: quoteCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = quoteCategories[index];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => _selectCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.forestGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.forestGreen
                              : borderColor,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _categoryIcon(cat),
                                size: 16,
                                color: selected ? Colors.white : subColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selected ? Colors.white : subColor,
                                ),
                              ),
                            ],
                          ),
                          if (selected) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 22,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 3. Today's Pick Header + Cycle Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _formattedToday(),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                  const Spacer(),
                  if (deck.isNotEmpty)
                    Text(
                      '${currentIdx + 1} / ${deck.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4. Interactive Swipeable Deck (or 'My Quotes' Empty State)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: quote == null
                    ? Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.terracotta,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No personal quotes yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Write a mantra or quote of your own—stored offline and ready to share.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _openAddQuoteSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: AppColors.lightTextPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Write a Quote',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
                    : Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 26,
                      decoration: BoxDecoration(
                        color:
                        AppColors.forestGreen.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    if (nextQuote != null)
                      Transform.scale(
                        scale: 0.96 + (0.04 * dragProgress),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A3123),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: _buildQuoteCardContent(nextQuote),
                        ),
                      ),
                    GestureDetector(
                      onDoubleTap: () =>
                          _toggleSaveCurrent(fromDoubleTap: true),
                      onPanUpdate: (details) {
                        if (_isFlyingOut) return;
                        setState(() {
                          _dragOffset += Offset(
                            details.delta.dx,
                            details.delta.dy * 0.25,
                          );
                        });
                      },
                      onPanEnd: (details) {
                        if (_isFlyingOut) return;
                        final velocity =
                            details.velocity.pixelsPerSecond.dx;
                        if (_dragOffset.dx.abs() > 95 ||
                            velocity.abs() > 450) {
                          final dir = _dragOffset.dx != 0
                              ? _dragOffset.dx.sign
                              : velocity.sign;
                          _animateCardOut(direction: dir);
                        } else {
                          _snapCardBack();
                        }
                      },
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: Transform.rotate(
                          angle: swipeAngle,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildQuoteCardContent(quote,
                                    isForeground: true),
                                IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _heartBurstController,
                                    builder: (context, _) {
                                      if (_heartBurstController.value ==
                                          0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Opacity(
                                        opacity: _heartOpacity.value,
                                        child: Transform.scale(
                                          scale: _heartScale.value,
                                          child: const Icon(
                                            Icons.favorite_rounded,
                                            color: AppColors.terracotta,
                                            size: 86,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 5. Minimal Gesture Hint
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'swipe or tap New Quote',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: subColor),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 6. Animated Copy / Share / Save Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (quote == null) return;
                    HapticFeedback.selectionClick();
                    Clipboard.setData(
                      ClipboardData(
                        text: '"${quote.text}" — ${quote.author}',
                      ),
                    );
                    setState(() => _justCopied = true);
                    _showForestToast('Copied to clipboard');
                    Future.delayed(const Duration(milliseconds: 1600), () {
                      if (mounted) setState(() => _justCopied = false);
                    });
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _justCopied
                              ? AppColors.forestGreen
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _justCopied
                                ? AppColors.forestGreen
                                : borderColor,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _justCopied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            key: ValueKey(_justCopied),
                            color: _justCopied ? Colors.white : fgColor,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          _justCopied ? FontWeight.w600 : FontWeight.w400,
                          color: _justCopied ? AppColors.terracotta : subColor,
                        ),
                        child: Text(_justCopied ? 'Copied!' : 'Copy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                _buildActionTile(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  fgColor: fgColor,
                  subColor: subColor,
                  borderColor: borderColor,
                  surfaceColor: surfaceColor,
                  onTap: () {
                    if (quote == null) return;
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SharePreviewScreen(quote: quote),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 28),
                _buildActionTile(
                  icon: isSaved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isSaved ? AppColors.terracotta : fgColor,
                  label: isSaved ? 'Saved' : 'Save',
                  fgColor: fgColor,
                  subColor: subColor,
                  borderColor: borderColor,
                  surfaceColor: surfaceColor,
                  onTap: _toggleSaveCurrent,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 7. Primary "New Quote" Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: quote == null
                      ? _openAddQuoteSheet
                      : () => _animateCardOut(direction: -1.0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.lightTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: Icon(
                    quote == null ? Icons.add_rounded : Icons.refresh_rounded,
                    size: 22,
                  ),
                  label: Text(
                    quote == null ? 'Write a Quote' : 'New Quote',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCardContent(Quote quote, {bool isForeground = false}) {
    return Stack(
      children: [
        Positioned(
          right: 10,
          bottom: 10,
          child: LeafWatermark(
            color: Colors.white.withValues(alpha: 0.08),
            size: 165,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '“',
                    style: TextStyle(
                      fontSize: 48,
                      height: 0.9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const Spacer(),
                  if (isForeground && quote.category == 'My Quotes') ...[
                    GestureDetector(
                      onTap: _editCurrentCustomQuote,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _deleteCurrentCustomQuote,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        quote.text,
                        style: TextStyle(
                          fontSize: _responsiveQuoteFontSize(quote.text),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                color: Colors.white.withValues(alpha: 0.14),
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quote.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quote.category,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    Color? iconColor,
    required String label,
    required Color fgColor,
    required Color subColor,
    required Color borderColor,
    required Color surfaceColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: iconColor ?? fgColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: subColor),
          ),
        ],
      ),
    );
  }
}