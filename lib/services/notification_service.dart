import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../models/remainder.dart';

// Callback for when notification is received in foreground
typedef OnNotificationReceived = void Function(int reminderId, DateTime scheduledTime, String description);

// Background task callback - MUST be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Hive for background task
      await Hive.initFlutter();
      Hive.registerAdapter(ReminderAdapter());
      await Hive.openBox<Reminder>('reminders');

      final Box<Reminder> reminderBox = Hive.box<Reminder>('reminders');
      final now = DateTime.now();

      // Check for reminders that should trigger in the next 15 minutes
      for (var reminder in reminderBox.values) {
        if (!reminder.isCompleted &&
            reminder.scheduledTime.isAfter(now) &&
            reminder.scheduledTime.isBefore(now.add(const Duration(minutes: 15)))) {

          // Reschedule notification if needed (in case it was missed)
          final notificationService = NotificationService();
          await notificationService.init();
          await notificationService.scheduleSimpleReminder(reminder);
        }
      }

      print('Background task completed successfully');
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String PERIODIC_TASK_TAG = "reminder_check_task";
  static const String UNIQUE_TASK_NAME = "reminder_periodic_check";

  // Callback for foreground notifications
  OnNotificationReceived? onNotificationReceived;

  // --- 1. INITIALIZATION ---
  Future<void> init({OnNotificationReceived? onNotificationReceived}) async {
    // Store the callback
    this.onNotificationReceived = onNotificationReceived;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    // 2. Platform-Specific Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _handleNotificationTap(response);
      },
      // THIS IS THE KEY: Handle foreground notifications
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 3. Request permissions
    await requestNotificationPermissions();

    // 4. Initialize background tasks
    await initializeBackgroundTasks();
  }

  // --- 2. INITIALIZE BACKGROUND TASKS ---
  Future<void> initializeBackgroundTasks() async {
    if (Platform.isAndroid) {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: false,
        );

        await Workmanager().registerPeriodicTask(
          UNIQUE_TASK_NAME,
          PERIODIC_TASK_TAG,
          frequency: const Duration(minutes: 15),
          initialDelay: const Duration(minutes: 1),
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(minutes: 5),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        );

        print('WorkManager initialized successfully');
      } catch (e) {
        print('Error initializing WorkManager: $e');
      }
    } else if (Platform.isIOS) {
      print('iOS background fetch should be configured in native code');
    }
  }

  // --- 3. CANCEL BACKGROUND TASKS ---
  Future<void> cancelBackgroundTasks() async {
    if (Platform.isAndroid) {
      await Workmanager().cancelByUniqueName(UNIQUE_TASK_NAME);
      print('Background tasks cancelled');
    }
  }

  // --- 4. HANDLE NOTIFICATION TAP ---
  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload != null) {
      final int reminderId = int.parse(response.payload!);

      // Fetch reminder details from Hive
      final Box<Reminder> reminderBox = Hive.box<Reminder>('reminders');
      final reminder = reminderBox.get(reminderId);

      if (reminder != null && onNotificationReceived != null) {
        // Call the callback to show AlarmOverlayPage
        onNotificationReceived!(
          reminder.id,
          reminder.scheduledTime,
          reminder.description,
        );

        // Mark reminder as completed
        reminder.isCompleted = true;
        await reminder.save();
        print('Reminder marked as completed: $reminderId');
      }
    }
  }

  // --- 5. REQUEST ALL NECESSARY PERMISSIONS ---
  Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        print('Notification permission granted: $granted');

        final bool? exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
        print('Exact alarm permission granted: $exactAlarmGranted');

        return granted == true && exactAlarmGranted == true;
      }
    } else if (Platform.isIOS) {
      final bool? granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted == true;
    }
    return false;
  }

  // --- 6. CHECK IF PERMISSIONS ARE GRANTED ---
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
    }
    return true;
  }

  // --- 7. SCHEDULING A GENERAL REMINDER ---
  Future<void> scheduleSimpleReminder(Reminder reminder) async {
    final bool enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('Notifications are not enabled. Please enable them in settings.');
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      reminder.scheduledTime,
      tz.local,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    if (scheduledDate.isBefore(now)) {
      print('Cannot schedule reminder in the past. Scheduled: $scheduledDate, Now: $now');
      return;
    }

    print('Scheduling notification for: $scheduledDate (Current time: $now)');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminder Channel',
      channelDescription: 'Channel for all time-based reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      ongoing: false,
      autoCancel: true,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('morning'),
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        reminder.id,
        'Reminder: ${reminder.title}',
        reminder.description,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: reminder.id.toString(),
      );
      print('Successfully scheduled reminder ID: ${reminder.id} for $scheduledDate');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // --- 8. SCHEDULE REPEATING REMINDER ---
  Future<void> scheduleRepeatingReminder(
      Reminder reminder,
      RepeatInterval interval,
      ) async {
    final bool enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('Notifications are not enabled.');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'repeating_reminder_channel',
      'Repeating Reminders',
      channelDescription: 'Channel for repeating reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        reminder.id,
        'Reminder: ${reminder.title}',
        'Recurring: ${reminder.description}',
        interval,
        platformDetails,
        payload: reminder.id.toString(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Successfully scheduled repeating reminder');
    } catch (e) {
      print('Error scheduling repeating notification: $e');
    }
  }

  // --- 9. SHOW IMMEDIATE TEST NOTIFICATION ---
  Future<void> showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel_id',
      'Test Channel',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  // --- 10. CANCELLATION ---
  Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Cancelled reminder ID: $id');
  }

  // --- 11. CANCEL ALL ---
  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('Cancelled all reminders');
  }

  // --- 12. GET PENDING NOTIFICATIONS ---
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // --- 13. GET ACTIVE NOTIFICATIONS ---
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        return await androidPlugin.getActiveNotifications();
      }
    } else if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        return await iosPlugin.getActiveNotifications();
      }
    }
    return [];
  }
}

// Background notification handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
}