import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../models/remainder.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final Box<Reminder> _reminderBox = Hive.box<Reminder>('reminders');
  final _formKey = GlobalKey<FormState>();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // List to hold multiple reminder times
  final List<ReminderTimeSlot> _reminderSlots = [];

  final List<String> _ringtoneList = ['Breeze', 'Daydream', 'Fireflies', 'Morning', 'Sunrise', 'Dewdrops'];
  String _selectedRingtone = 'Breeze';

  bool _isLoading = false;
  bool _titleFocused = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Start with one reminder slot
    _addNewTimeSlot();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  void _addNewTimeSlot() {
    setState(() {
      final DateTime futureDate =
      DateTime.now().add(Duration(minutes: _reminderSlots.length + 1));
      _reminderSlots.add(ReminderTimeSlot(
        date: DateTime(futureDate.year, futureDate.month, futureDate.day),
        time: TimeOfDay.fromDateTime(futureDate),
      ));
    });
  }

  void _removeTimeSlot(int index) {
    if (_reminderSlots.length > 1) {
      setState(() {
        _reminderSlots.removeAt(index);
      });
    } else {
      _showCustomToast(
        'At least one reminder time is required',
        Iconsax.warning_2_copy,
      );
    }
  }

  void _showCustomToast(String message, IconData icon,
      {int durationInSeconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        content: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.inversePrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: durationInSeconds),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _saveReminders() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showCustomToast(
        'Please enter a reminder title',
        Iconsax.warning_2_copy,
        durationInSeconds: 3,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    int successCount = 0;
    int failedCount = 0;
    final DateTime now = DateTime.now().add(const Duration(seconds: 5));

    for (var slot in _reminderSlots) {
      final DateTime scheduledDateTime = DateTime(
        slot.date.year,
        slot.date.month,
        slot.date.day,
        slot.time.hour,
        slot.time.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        failedCount++;
        continue;
      }

      // Create and save reminder
      final newReminder = Reminder(
        id: Reminder.createUniqueId(),
        title: _titleController.text.trim(),
        scheduledTime: scheduledDateTime,
        description: _descriptionController.text.trim().isEmpty
            ? 'You set this reminder for now. Tap to mark as complete.'
            : _descriptionController.text.trim(),
      );

      // Save to Hive
      _reminderBox.put(newReminder.id, newReminder);

      // Schedule the notification
      _notificationService.scheduleSimpleReminder(newReminder);
      successCount++;

      // Small delay to ensure unique IDs
      Future.delayed(const Duration(milliseconds: 10));
    }

    setState(() {
      _isLoading = false;
    });

    if (successCount > 0) {
      _showBatteryOptimizationWarning(context, successCount);
    } else {
      _showCustomToast(
        'Failed to schedule $failedCount reminder(s). Please select times in the future.',
        Iconsax.close_circle_copy,
        durationInSeconds: 3,
      );
    }
  }

  void _showBatteryOptimizationWarning(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reminders Scheduled',
          style: TextStyle(fontSize: 20),
        ),
        content: Text(
          '$count reminder(s) have been scheduled!\n\n'
              'For reliable reminders on devices like Xiaomi, Huawei, and OnePlus, please check:\n\n'
              '1. Autostart is ON for this app.\n'
              '2. Battery Saver is set to No Restrictions.',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.8),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Open Settings',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseSurface
                        .withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              _openSystemSettings();
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _openSystemSettings() async {
    const String generalIntent =
        'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS';
    final Uri uri = Uri.parse('app_settings:$generalIntent');

    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      await launchUrl(Uri.parse('app-settings:'),
          mode: LaunchMode.platformDefault);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.inverseSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    required int maxLines,
    required Function(bool) onFocusChange,
    String? Function(String?)? validator,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextFormField(
        maxLines: maxLines,
        controller: controller,
        validator: validator,
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .inversePrimary
                  .withValues(alpha: 0.7),
            ),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused
                ? Theme.of(context)
                .colorScheme
                .inversePrimary
                .withValues(alpha: 0.7)
                : Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .inversePrimary
                  .withValues(alpha: 0.7),
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: isFocused
              ? Theme.of(context)
              .colorScheme
              .tertiary
              .withValues(alpha: 0.05)
              : Theme.of(context)
              .colorScheme
              .secondary
              .withValues(alpha: 0.05),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'SET REMINDER',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Iconsax.arrow_left_2_copy),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 4,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Reminder Details Section
                        _buildSectionHeader(
                          'Reminder Details',
                          Iconsax.notification_bing_copy,
                          'What would you like to be reminded about?',
                        ),
                        const SizedBox(height: 16),

                        // Title Field
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _titleController,
                                      label: 'Reminder Title',
                                      hint:
                                      'e.g., Take medicine, Submit assignment',
                                      icon: Iconsax.smallcaps_copy,
                                      isFocused: _titleFocused,
                                      onFocusChange: (focused) {
                                        setState(() {
                                          _titleFocused = focused;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Reminder title is required';
                                        }
                                        return null;
                                      },
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _descriptionController,
                                      label: 'Reminder Description (Optional)',
                                      hint:
                                      'e.g., Take medicine, Submit assignment',
                                      icon: Iconsax.note_1_copy,
                                      isFocused: _titleFocused,
                                      onFocusChange: (focused) {
                                        setState(() {
                                          _titleFocused = focused;
                                        });
                                      },
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Schedule Section
                        Row(
                          children: [
                            Expanded(
                              child: _buildSectionHeader(
                                'Reminder Schedule',
                                Iconsax.calendar_1_copy,
                                'When should we remind you?',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Reminder Slots List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reminderSlots.length,
                          itemBuilder: (context, index) {
                            return _buildReminderSlot(index);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveReminders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.inverseSurface,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.timer_start_copy, size: 22),
                const SizedBox(width: 8),
                Text(
                  'SET REMINDER',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSlot(int index) {
    final slot = _reminderSlots[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 24.0, right: 24.0, top: 16.0, bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.timer_start_copy,
                        size: 16,
                        color: Theme.of(context).colorScheme.inverseSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reminder',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                    onPressed: (){
                      showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildSettingBottomSheet()
                      );
                    },
                    icon: Icon(Iconsax.setting)
                ),
                if (_reminderSlots.length > 1)
                  IconButton(
                    icon: Icon(Iconsax.trash_copy,
                        color: Theme.of(context).colorScheme.error, size: 20),
                    onPressed: () => _removeTimeSlot(index),
                    tooltip: 'Remove this reminder',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Easy Date Timeline
            EasyDateTimeLine(
              initialDate: slot.date,
              onDateChange: (selectedDate) {
                setState(() {
                  _reminderSlots[index].date = selectedDate;
                });
              },
              activeColor: Theme.of(context).colorScheme.tertiary,
              headerProps: EasyHeaderProps(
                monthPickerType: MonthPickerType.switcher,
                dateFormatter: const DateFormatter.fullDateDMY(),
                monthStyle: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                selectedDateStyle: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 18,
                ),
              ),
              dayProps: EasyDayProps(
                height: 56,
                width: 56,
                dayStructure: DayStructure.dayStrDayNum,
                activeDayStyle: DayStyle(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  dayNumStyle: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  dayStrStyle: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    fontSize: 12,
                  ),
                ),
                inactiveDayStyle: DayStyle(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                  ),
                  dayNumStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 18,
                  ),
                  dayStrStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                todayStyle: DayStyle(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 2,
                    ),
                  ),
                  dayNumStyle: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  dayStrStyle: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomTimePicker(index)
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimePicker(int index) {
    final slot = _reminderSlots[index];
    final hour = slot.time.hourOfPeriod == 0 ? 12 : slot.time.hourOfPeriod;
    final minute = slot.time.minute;
    final isPM = slot.time.period == DayPeriod.pm;

    return Container(
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hour picker
          _buildTimeUnit(
            value: hour,
            onIncrement: () {
              setState(() {
                int newHour = hour + 1;
                if (newHour > 12) newHour = 1;
                final totalHour = isPM
                    ? (newHour == 12 ? 12 : newHour + 12)
                    : (newHour == 12 ? 0 : newHour);
                _reminderSlots[index].time =
                    TimeOfDay(hour: totalHour, minute: minute);
              });
            },
            onDecrement: () {
              setState(() {
                int newHour = hour - 1;
                if (newHour < 1) newHour = 12;
                final totalHour = isPM
                    ? (newHour == 12 ? 12 : newHour + 12)
                    : (newHour == 12 ? 0 : newHour);
                _reminderSlots[index].time =
                    TimeOfDay(hour: totalHour, minute: minute);
              });
            },
          ),

          // Colon separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),

          // Minute picker
          _buildTimeUnit(
            value: minute,
            onIncrement: () {
              setState(() {
                int newMinute = minute + 1;
                if (newMinute > 59) newMinute = 0;
                _reminderSlots[index].time =
                    TimeOfDay(hour: slot.time.hour, minute: newMinute);
              });
            },
            onDecrement: () {
              setState(() {
                int newMinute = minute - 1;
                if (newMinute < 0) newMinute = 59;
                _reminderSlots[index].time =
                    TimeOfDay(hour: slot.time.hour, minute: newMinute);
              });
            },
          ),

          const SizedBox(width: 16),

          // AM/PM toggle
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isPM) {
                        // Switch to AM
                        int newHour = slot.time.hour - 12;
                        if (newHour < 0) newHour = 0;
                        _reminderSlots[index].time =
                            TimeOfDay(hour: newHour, minute: minute);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !isPM
                          ? Theme.of(context).colorScheme.tertiary
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: !isPM
                            ? Theme.of(context).colorScheme.inverseSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (!isPM) {
                        // Switch to PM
                        int newHour = slot.time.hour + 12;
                        if (newHour >= 24) newHour = 12;
                        _reminderSlots[index].time =
                            TimeOfDay(hour: newHour, minute: minute);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPM
                          ? Theme.of(context).colorScheme.tertiary
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'PM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPM
                            ? Theme.of(context).colorScheme.inverseSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingBottomSheet() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REMINDER SETTINGS',
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Iconsax.close_circle_copy, size: 32)
                )
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Reminder Ringtone',
              style: TextStyle(
                  fontSize: 16
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 140),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedRingtone,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Iconsax.music,
                        color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.secondary,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18.0, horizontal: 20.0),
                    ),
                    items: _ringtoneList.map((String ringtone) {
                      return DropdownMenuItem<String>(
                        value: ringtone,
                        child: Text(ringtone, style: TextStyle(fontFamily: 'JetBrains Mono')),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedRingtone = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.5),
                    child: IconButton(
                        onPressed: () async {
                          await _audioPlayer.stop();
                          String fileName = _selectedRingtone.toLowerCase();
                          await _audioPlayer.play(AssetSource(fileName));
                        },
                        icon: Icon(Iconsax.music_play)
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit({
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onIncrement,
          child: Container(
            padding: const EdgeInsets.all(0),
            child: Icon(
              Iconsax.arrow_up_2_copy,
              size: 20,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onDecrement,
          child: Container(
            padding: const EdgeInsets.all(0),
            child: Icon(
              Iconsax.arrow_down_1_copy,
              size: 20,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// Helper class to store date and time for each reminder
class ReminderTimeSlot {
  DateTime date;
  TimeOfDay time;

  ReminderTimeSlot({required this.date, required this.time});
}