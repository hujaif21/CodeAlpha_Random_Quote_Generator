import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/quotes_data.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'pocket_wisdom_daily_v2';
  static const String _channelName = 'Daily Wisdom Quotes';
  static bool _initialized = false;

  static final StreamController<String> onQuoteTapped =
  StreamController<String>.broadcast();
  static String? initialQuoteId;

  static Future<void> init() async {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }

    const androidInit =
    AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('NOTIFICATION TAPPED PAYLOAD: ${response.payload}');
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          initialQuoteId = payload;
          onQuoteTapped.add(payload);
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      initialQuoteId = launchDetails?.notificationResponse?.payload;
      debugPrint('COLD START PAYLOAD: $initialQuoteId');
    }
  }

  static Future<bool> ensurePermission() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;

    final alreadyGranted = await androidImpl.areNotificationsEnabled() ?? false;
    if (alreadyGranted) return true;

    final granted = await androidImpl.requestNotificationsPermission() ?? false;
    return granted;
  }

  static Future<bool> showInstantQuoteNotification() async {
    final allowed = await ensurePermission();
    if (!allowed) return false;

    final quote = allQuotes[Random().nextInt(allQuotes.length)];

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Mindful daily quotes from Pocket Wisdom',
      icon: '@drawable/ic_notification',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        '"${quote.text}"\n— ${quote.author}',
        contentTitle: 'Pocket Wisdom · ${quote.category}',
      ),
    );

    await _plugin.show(
      Random().nextInt(100000),
      'Pocket Wisdom · ${quote.category}',
      '"${quote.text}" — ${quote.author}',
      NotificationDetails(android: androidDetails),
      payload: quote.id,
    );
    return true;
  }

  static Future<bool> scheduleDailyQuote({int hour = 8, int minute = 30}) async {
    final allowed = await ensurePermission();
    if (!allowed) return false;

    await _plugin.cancel(1002);
    final quote = allQuotes[Random().nextInt(allQuotes.length)];

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily morning quote reminder',
      icon: '@drawable/ic_notification',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        '"${quote.text}"\n— ${quote.author}',
        contentTitle: 'Morning Wisdom · ${quote.category}',
      ),
    );

    await _plugin.zonedSchedule(
      1002,
      'Morning Wisdom · ${quote.category}',
      '"${quote.text}" — ${quote.author}',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      payload: quote.id,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  static Future<void> cancelDailyQuote() async {
    await init();
    await _plugin.cancel(1002);
  }
}