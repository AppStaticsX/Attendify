import 'package:attendify/pages/add_note_page.dart';
import 'package:attendify/pages/add_remainder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendify/components/app_drawer.dart';
import 'package:attendify/components/custom_icon_button.dart';
import 'package:attendify/components/event_tile.dart';
import 'package:attendify/components/heatmap.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/models/event.dart';
import 'package:attendify/pages/settings_page.dart';
import 'package:attendify/pages/create_event_page.dart';
import 'package:attendify/pages/edit_event_page.dart';
import 'package:attendify/util/event_util.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now().add(Duration(days: 105)); // Default 15 weeks
  final TextEditingController textController = TextEditingController();
  final TextEditingController textController2 = TextEditingController();

  // Add current displayed month state
  DateTime _currentDisplayedMonth = DateTime.now();

  String userName = '';

  bool _isFabOpen = false;

  // Add GlobalKey for HeatMapCalendar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
      _loadUserName();
      _checkAndShowTimeDialog();
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('userNAME');

    if (mounted) {
      setState(() {
        userName = username ?? ''; // Handle null case properly
      });
    }
  }

  void _updateUserName() {
    _loadUserName();
  }

  // Check if time dialog has been shown before
  Future<void> _checkAndShowTimeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownDialog = prefs.getBool('has_shown_date_dialog') ?? false;

    if (!hasShownDialog) {
      Future.delayed(Duration(milliseconds: 500), () {
        _showTimePickerDialog();
      });
    }
  }

  // Show time picker dialog
  void _showTimePickerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Schedule Start Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please select your schedule start date for event analysis:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 21,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selectedDate,
                    dateOrder: DatePickerDateOrder.ymd,
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
                      });
                    },
                  ),
                )
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Show end date picker after start date is selected
                _showEndDatePickerDialog();
              },
              child: Text(
                  'Next',
                  style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.inverseSurface
                  )
              ),
            ),
          ],
        );
      },
    );
  }

  // Show end date picker dialog
  void _showEndDatePickerDialog() {
    // Set initial end date to be after start date
    selectedEndDate = selectedDate.add(Duration(days: 120));

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Schedule End Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please select your schedule end date (semester end):',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 21,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selectedEndDate,
                    minimumDate: selectedDate.add(Duration(days: 1)), // Must be after start date
                    dateOrder: DatePickerDateOrder.ymd,
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        selectedEndDate = DateTime(newDate.year, newDate.month, newDate.day);
                      });
                    },
                  ),
                )
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Go back to start date picker
                Navigator.of(context).pop();
                _showTimePickerDialog();
              },
              child: Text(
                  'Back',
                  style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.6)
                  )
              ),
            ),
            TextButton(
              onPressed: () async {
                // Validate that end date is after start date
                if (selectedEndDate.isBefore(selectedDate) || selectedEndDate.isAtSameMomentAs(selectedDate)) {
                  _showCustomToast(
                    'End date must be after start date',
                    Iconsax.warning_2,
                    durationInSeconds: 3,
                  );
                  return;
                }

                final navigator = Navigator.of(context);
                // Save both dates and mark dialog as shown
                await _saveDatePreference();
                navigator.pop();
                _showCustomToast(
                  'Schedule dates saved:\n${DateFormat('yyyy MMM dd').format(selectedDate)} - ${DateFormat('yyyy MMM dd').format(selectedEndDate)}',
                  Iconsax.tick_circle,
                  durationInSeconds: 3,
                );
              },
              child: Text(
                  'Submit',
                  style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.inverseSurface
                  )
              ),
            ),
          ],
        );
      },
    );
  }

  // Save time preference to SharedPreferences
  Future<void> _saveDatePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_date_dialog', true);
    final int startDateInMillis = selectedDate.millisecondsSinceEpoch;
    final int endDateInMillis = selectedEndDate.millisecondsSinceEpoch;
    await prefs.setInt('schedule_start_date', startDateInMillis);
    await prefs.setInt('schedule_end_date', endDateInMillis);
  }

  Future<void> _loadEvents() async {
    try {
      await Provider.of<EventDatabase>(context, listen: false).readEvents();
    } catch (e) {
      _showCustomToast('Error loading events.', Iconsax.close_circle);
    }
  }

  // Modified methods to handle month navigation
  void _goToPreviousMonth() {
    setState(() {
      _currentDisplayedMonth = DateTime(
        _currentDisplayedMonth.year,
        _currentDisplayedMonth.month ,
        _currentDisplayedMonth.day - 30
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentDisplayedMonth = DateTime(
        _currentDisplayedMonth.year,
        _currentDisplayedMonth.month,
          _currentDisplayedMonth.day + 30,
      );
    });
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
            Expanded(child: Text(message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary
              ),)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: durationInSeconds),
      ),
    );
  }

  void createNewEvent() async {
    // Navigate to the create event page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    );

    // Reload events if an event was created
    if (result == true) {
      _loadEvents();
    }
  }

  void checkEventOnOff(bool? value, Event event) {
    if (value != null) {
      context.read<EventDatabase>().updateEventCompletion(event.id, value);
    }
  }

  void markEventNotConducted(Event event) {
    context.read<EventDatabase>().markEventNotConducted(event.id).then((_) {
      _showCustomToast('Event marked as not conducted', Iconsax.close_circle);
    }).catchError((e) {
      _showCustomToast('Failed to mark event as not conducted: $e', Iconsax.warning_2,
          durationInSeconds: 3);
    });
  }

  void editEventBox(Event event) {
    // Navigate to the edit event page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: event),
      ),
    );
  }

  void deleteEventBox(Event event) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Event?'),
            actions: [
              MaterialButton(
                onPressed: () async {
                  try {
                    final navigator = Navigator.of(context);
                    await context.read<EventDatabase>().deleteEvent(event.id);
                    navigator.pop();
                    _showCustomToast(
                        'Event deleted successfully!', Iconsax.tick_circle);
                  } catch (e) {
                    _showCustomToast('Failed to delete event: $e', Iconsax.close_circle,
                        durationInSeconds: 3);
                  }
                },
                child: const Text('Delete'),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  String _getCurrentDate() {
    return DateFormat('dd MMMM yyyy').format(DateTime.now());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                CustomIconButton(
                  toolTip: 'Previous',
                  icon: Icons.arrow_back,
                  onPressed: _goToPreviousMonth,
                  size: 24,
                ),
                const SizedBox(width: 8),
                CustomIconButton(
                  toolTip: 'Next',
                  icon: Icons.arrow_forward,
                  onPressed: _goToNextMonth,
                  size: 24,
                ),
                const SizedBox(width: 8),
                CustomIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                    _updateUserName();
                  },
                  size: 24, toolTip: 'Settings',
                ),
              ],
            ),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCurrentDate(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.inversePrimary
                ),
                children: [
                  const TextSpan(text: "Today is "),
                  TextSpan(
                    text: DateFormat('EEEE').format(DateTime.now()),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, // Example: make the day bold
                      color: Color(0xFF56D364),           // Example: different color
                      fontFamily: 'JetBrains Mono'
                    ),
                  ),
                ],
              ),
            )

          ],
        ),
        backgroundColor: Colors.transparent,
        centerTitle: false,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      // Add this state variable to your widget's state class


// Replace your floatingActionButton with this:
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Add Event button
          if (_isFabOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                tooltip: 'Add Reminders',
                onPressed: () {
                  setState(() {
                    _isFabOpen = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddReminderScreen()),
                  );
                },
                elevation: 6,
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                child: Icon(
                  Iconsax.timer_start_copy,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),

          if (_isFabOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                tooltip: 'Add New Course',
                onPressed: () {
                  setState(() {
                    _isFabOpen = false;
                  });
                  createNewEvent();
                },
                elevation: 6,
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                child: Icon(
                  Iconsax.book_1_copy,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),

          // Add Notes button
          if (_isFabOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                tooltip: 'Add Notes',
                onPressed: () {
                  setState(() {
                    _isFabOpen = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddNotePage()),
                  );
                },
                elevation: 6,
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                child: Icon(
                  Iconsax.note_1_copy,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),

          // Main FAB
          FloatingActionButton(
            tooltip: _isFabOpen? 'Collapse' : 'Expand',
            onPressed: () {
              setState(() {
                _isFabOpen = !_isFabOpen;
              });
            },
            elevation: 10,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: AnimatedRotation(
              turns: _isFabOpen ? 0.250 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFabOpen ? Icons.close : Icons.add,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          children: [
            const SizedBox(height: 16),
            _buildHeatMap(),
            const SizedBox(height: 16),
            _buildEventsList(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatMap() {
    final eventDatabase = context.watch<EventDatabase>();
    List<Event> currentEvents = eventDatabase.currentEvents;

    int totalEvents = currentEvents.length;
    totalEvents = totalEvents > 0 ? totalEvents : 1;

    return FutureBuilder(
      future: eventDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Heatmap(
            datasets: prepMapDataset(currentEvents),
            startDate: snapshot.data!,
            totalEvents: totalEvents,
            currentDisplayedMonth: _currentDisplayedMonth,
            currentEvents: currentEvents, // Pass the GlobalKey
          );
        } else {
          return Container();
        }
      },
    );
  }

  // Add this helper method to calculate habits per day
  Map<DateTime, int> calculateEventsPerDay(List<Event> events, DateTime currentDisplayedMonth) {
    Map<DateTime, int> eventsPerDay = {};

    // Calculate first day of displayed month
    final DateTime firstDayOfMonth = DateTime(currentDisplayedMonth.year, currentDisplayedMonth.month, 6);

    // Calculate last day of displayed month
    final DateTime lastDayOfMonth = DateTime(currentDisplayedMonth.year, currentDisplayedMonth.month + 2, 0);

    // For each day in the displayed month range
    for (DateTime date = firstDayOfMonth; date.isBefore(lastDayOfMonth.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      String dayOfWeek = DateFormat('EEEE').format(date); // e.g., "Monday"

      // Count habits assigned to this day
      int eventsForDay = events.where((event) =>
          event.assignedDays.contains(dayOfWeek)
      ).length;

      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      eventsPerDay[normalizedDate] = eventsForDay;
    }

    return eventsPerDay;
  }

  Widget _buildEventsList() {
    final eventDatabase = context.watch<EventDatabase>();
    List<Event> currentEvents = eventDatabase.currentEvents;
    final today = DateFormat('EEEE').format(DateTime.now());

    return FutureBuilder<bool>(
      future: eventDatabase.isHoliday(DateTime.now()),
      builder: (context, snapshot) {
        final isHoliday = snapshot.data ?? false;

        if (isHoliday) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                      'assets/lottie/Confetti.json',
                      height: 150,
                      width: 150,
                      repeat: true
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "It's a Holiday! 🎉",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Take a break from your courses today",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    "Tap on the heatmap to toggle holidays",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter only today's lectures
        List<Event> todayEvents = currentEvents.where((event) =>
            event.assignedDays.contains(today)).toList();

        if (currentEvents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.dropbox_copy, size: 120, color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text(
                    "No Courses Added Yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    "Start tracking your attendance",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap + button to add a course",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show only today's lectures
        if (todayEvents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.calendar_tick_copy,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No Lectures Today",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Enjoy your free day! 🎉",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate completed and remaining lectures for today
        int completedCount = todayEvents.where((event) => isEventCompletedToday(event)).length;
        int remainingCount = todayEvents.length - completedCount;

        String statusText;
        if (remainingCount == 0) {
          statusText = "All lectures completed!";
        } else if (completedCount == 0) {
          statusText = "$remainingCount lecture${remainingCount > 1 ? 's' : ''} pending";
        } else {
          statusText = "$completedCount completed • $remainingCount remaining";
        }

        // Display today's lectures
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.calendar_1_copy,
                        size: 30,
                        color: Theme.of(context).colorScheme.inverseSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Lectures",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inverseSurface,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.5),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                itemCount: todayEvents.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final event = todayEvents[index];
                  bool isCompletedToday = isEventCompletedToday(event);

                  return EventTile(
                    isCompleted: isCompletedToday,
                    eventName: event.name,
                    conductorName: event.conductorName,
                    event: event,
                    onChanged: (value) => checkEventOnOff(value, event),
                    editEvent: (context) => editEventBox(event),
                    deleteEvent: (context) => deleteEventBox(event),
                    markNotConducted: (context) => markEventNotConducted(event),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}