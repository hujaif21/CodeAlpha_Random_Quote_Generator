import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quotes_data.dart';
import '../models/quote.dart';

class CacheService {
  static const String _savedQuotesKey = 'pw_saved_quote_ids';
  static const String _customQuotesKey = 'pw_custom_quotes_json';
  static const String _darkThemeKey = 'pw_dark_theme';
  static const String _lastQuoteIdKey = 'pw_last_quote_id';
  static const String _dailyReminderKey = 'pw_daily_reminder';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Combines user-created quotes (newest first) with the 60 curated quotes
  static List<Quote> getAllAvailableQuotes() {
    return [...getCustomQuotes(), ...allQuotes];
  }

  /// Reads user-created quotes serialized in SharedPreferences
  static List<Quote> getCustomQuotes() {
    final raw = _prefs.getString(_customQuotesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Quote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Adds a new custom quote and automatically bookmarks it in Favorites
  static Future<Quote> addCustomQuote({
    required String text,
    required String author,
  }) async {
    final cleanAuthor = author.trim().isEmpty ? 'You' : author.trim();
    final newQuote = Quote(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      author: cleanAuthor,
      category: 'My Quotes',
    );

    final existing = getCustomQuotes();
    existing.insert(0, newQuote);
    await _prefs.setString(
      _customQuotesKey,
      jsonEncode(existing.map((q) => q.toJson()).toList()),
    );

    // Also add to saved favorites so it appears in Saved Quotes immediately
    final saved = getSavedQuoteIds();
    if (!saved.contains(newQuote.id)) {
      saved.insert(0, newQuote.id);
      await _prefs.setStringList(_savedQuotesKey, saved);
    }

    return newQuote;
  }

  static Future<void> deleteCustomQuote(String quoteId) async {
    final existing = getCustomQuotes()..removeWhere((q) => q.id == quoteId);
    await _prefs.setString(
      _customQuotesKey,
      jsonEncode(existing.map((q) => q.toJson()).toList()),
    );
    final saved = getSavedQuoteIds()..remove(quoteId);
    await _prefs.setStringList(_savedQuotesKey, saved);
  }
  static Future<Quote?> updateCustomQuote({
    required String quoteId,
    required String text,
    required String author,
  }) async {
    final existing = getCustomQuotes();
    final idx = existing.indexWhere((q) => q.id == quoteId);
    if (idx == -1) return null;

    final updated = Quote(
      id: quoteId,
      text: text.trim(),
      author: author.trim().isEmpty ? 'You' : author.trim(),
      category: 'My Quotes',
    );

    existing[idx] = updated;
    await _prefs.setString(
      _customQuotesKey,
      jsonEncode(existing.map((q) => q.toJson()).toList()),
    );
    return updated;
  }

  /// Returns only valid saved quote IDs ordered from latest to oldest
  static List<String> getSavedQuoteIds() {
    final list = _prefs.getStringList(_savedQuotesKey);
    if (list == null) {
      const defaults = ['wis10', 'cal02', 'foc09'];
      _prefs.setStringList(_savedQuotesKey, defaults);
      return List<String>.from(defaults);
    }

    final validIds = getAllAvailableQuotes().map((q) => q.id).toSet();
    final cleaned = list.where((id) => validIds.contains(id)).toList();

    if (cleaned.length != list.length) {
      _prefs.setStringList(_savedQuotesKey, cleaned);
    }

    return cleaned;
  }

  static Future<List<String>> toggleSaveQuote(String quoteId) async {
    final current = getSavedQuoteIds();
    if (current.contains(quoteId)) {
      current.remove(quoteId);
    } else {
      current.insert(0, quoteId);
    }
    await _prefs.setStringList(_savedQuotesKey, current);
    return current;
  }

  static bool getDarkTheme() {
    return _prefs.getBool(_darkThemeKey) ?? false;
  }

  static Future<void> setDarkTheme(bool isDark) async {
    await _prefs.setBool(_darkThemeKey, isDark);
  }

  static String? getLastQuoteId() {
    return _prefs.getString(_lastQuoteIdKey);
  }

  static Future<void> setLastQuoteId(String id) async {
    await _prefs.setString(_lastQuoteIdKey, id);
  }

  static bool getDailyReminder() {
    return _prefs.getBool(_dailyReminderKey) ?? true;
  }

  static Future<void> setDailyReminder(bool enabled) async {
    await _prefs.setBool(_dailyReminderKey, enabled);
  }
}