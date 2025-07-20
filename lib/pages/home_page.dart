import 'dart:math' as math;
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
import 'package:attendify/util/habit_util.dart';
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
  final TextEditingController textController = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // Add current displayed month state
  DateTime _currentDisplayedMonth = DateTime.now();

  // Add time picker related variables
  bool _hasShownTimeDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabits();
      _checkAndShowTimeDialog();
    });
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
      barrierDismissible: true, // Prevent dismissing by tapping outside
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
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save the selected time and mark dialog as shown
                await _saveDatePreference();
                Navigator.of(context).pop();
                _showCustomToast(
                  'Date preference saved: ${DateFormat('yyyy MMM dd').format(selectedDate)}',
                  Iconsax.clock,
                  durationInSeconds: 3,
                );
              },
              child: const Text('Submit'),
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
    final int dateInMillis = selectedDate.millisecondsSinceEpoch;
    await prefs.setInt('schedule_start_date', dateInMillis);
  }

  Future<void> _loadHabits() async {
    try {
      await Provider.of<HabitDatabase>(context, listen: false).readHabits();
    } catch (e) {
      debugPrint('Error loading habits: $e');
      _showCustomToast('Error loading habits', Iconsax.close_circle);
    }
  }

  // Add methods to handle month navigation
  void _goToPreviousMonth() {
    setState(() {
      _currentDisplayedMonth = DateTime(
        _currentDisplayedMonth.year,
        _currentDisplayedMonth.month - 1,
        1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentDisplayedMonth = DateTime(
        _currentDisplayedMonth.year,
        _currentDisplayedMonth.month + 1,
        1,
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

  void createNewHabit() {
    // Reset selected days
    _selectedDays.fillRange(0, _selectedDays.length, false);

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: const Text('New Event'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.calendar_copy,
                            color: Theme.of(context).colorScheme.inversePrimary,),
                          label: Text('Create a New Event'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textController2,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.user_copy,
                            color: Theme.of(context).colorScheme.inversePrimary,),
                          label: Text('Conductor'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Days:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: List.generate(_weekdays.length, (index) {
                          return ChoiceChip(
                            label: Text(_weekdays[index].substring(0, 3), style: TextStyle(
                                color: Theme.of(context).colorScheme.inversePrimary
                            ),),
                            selected: _selectedDays[index],
                            checkmarkColor: Theme.of(context).colorScheme.inversePrimary,
                            onSelected: (selected) {
                              setDialogState(() {
                                _selectedDays[index] = selected;
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () async {
                        String newHabitName = textController.text.trim();
                        String conductorName = textController2.text.trim();
                        List<String> selectedDays = [];
                        for (int i = 0; i < _selectedDays.length; i++) {
                          if (_selectedDays[i]) {
                            selectedDays.add(_weekdays[i]);
                          }
                        }
                        debugPrint(
                            'Creating habit: $newHabitName, selectedDays: $selectedDays, Conducted_by: $conductorName');
                        if (newHabitName.isNotEmpty &&
                            selectedDays.isNotEmpty && conductorName.isNotEmpty) {
                          try {
                            await context.read<HabitDatabase>().addHabit(
                                newHabitName, selectedDays, conductorName);
                            Navigator.pop(context);
                            textController.clear();
                            textController2.clear();
                            _showCustomToast('Habit added successfully!',
                                Iconsax.tick_circle);
                          } catch (e) {
                            debugPrint('Error adding habit: $e');
                            _showCustomToast(
                                'Failed to add habit: $e', Iconsax.close_circle,
                                durationInSeconds: 3);
                          }
                        } else {
                          _showCustomToast(
                            'Please enter habit name and select day(s)',
                            Iconsax.warning_2,
                            durationInSeconds: 3,
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                        textController.clear();
                        textController2.clear();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
          ),
    );
  }

  void checkHabitOnOff(bool? value, Habit habit) {
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  void markHabitNotConducted(Habit habit) {
    context.read<HabitDatabase>().markHabitNotConducted(habit.id).then((_) {
      _showCustomToast('Habit marked as not conducted', Iconsax.close_circle);
    }).catchError((e) {
      debugPrint('Error marking habit as not conducted: $e');
      _showCustomToast('Failed to mark habit as not conducted: $e', Iconsax.warning_2,
          durationInSeconds: 3);
    });
  }

  void editHabitBox(Habit habit) {
    textController.text = habit.name;
    textController2.text = habit.conductorName;
    _selectedDays.fillRange(0, _selectedDays.length, false);
    for (int i = 0; i < _weekdays.length; i++) {
      _selectedDays[i] = habit.assignedDays.contains(_weekdays[i]);
    }

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: const Text('Edit Event'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.calendar_copy,
                            color: Theme.of(context).colorScheme.inversePrimary,),
                          label: Text('Edit Event Name'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textController2,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Iconsax.user_copy,
                            color: Theme.of(context).colorScheme.inversePrimary,),
                          label: Text('Conductor'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Days:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: List.generate(_weekdays.length, (index) {
                          return ChoiceChip(
                            label: Text(_weekdays[index].substring(0, 3), style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
                            selected: _selectedDays[index],
                            checkmarkColor: Theme.of(context).colorScheme.inversePrimary,
                            onSelected: (selected) {
                              setDialogState(() {
                                _selectedDays[index] = selected;
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () async {
                        String newHabitName = textController.text.trim();
                        String conductorName = textController2.text.trim();
                        List<String> selectedDays = [];
                        for (int i = 0; i < _selectedDays.length; i++) {
                          if (_selectedDays[i]) {
                            selectedDays.add(_weekdays[i]);
                          }
                        }
                        debugPrint(
                            'Updating habit: $newHabitName, selectedDays: $selectedDays, Conducted_by: $conductorName');
                        if (newHabitName.isNotEmpty &&
                            selectedDays.isNotEmpty && conductorName.isNotEmpty) {
                          try {
                            await context.read<HabitDatabase>().updateHabit(
                                habit.id, newHabitName, selectedDays, conductorName);
                            Navigator.pop(context);
                            textController.clear();
                            textController2.clear();
                            _showCustomToast('Habit updated successfully!',
                                Iconsax.tick_circle);
                          } catch (e) {
                            debugPrint('Error updating habit: $e');
                            _showCustomToast(
                                'Failed to update habit: $e', Iconsax.close_circle,
                                durationInSeconds: 3);
                          }
                        } else {
                          _showCustomToast(
                            'Please enter a habit name and select at least one day',
                            Iconsax.warning_2,
                            durationInSeconds: 3,
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                        textController.clear();
                        textController2.clear();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
          ),
    );
  }

  void deleteHabitBox(Habit habit) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Habit?'),
            actions: [
              MaterialButton(
                onPressed: () async {
                  try {
                    await context.read<HabitDatabase>().deleteHabit(habit.id);
                    Navigator.pop(context);
                    _showCustomToast(
                        'Habit deleted successfully!', Iconsax.tick_circle);
                  } catch (e) {
                    debugPrint('Error deleting habit: $e');
                    _showCustomToast('Failed to delete habit: $e', Iconsax.close_circle,
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

  // Add method to get displayed month string
  String _getDisplayedMonth() {
    return DateFormat('MMMM yyyy').format(_currentDisplayedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      appBar: AppBar(
        actions: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CustomIconButton(
                      icon: Icons.arrow_back,
                      onPressed: _goToPreviousMonth,
                      size: 24),
                  const SizedBox(width: 8),
                  CustomIconButton(
                      icon: Icons.arrow_forward,
                      onPressed: _goToNextMonth,
                      size: 24),
                  const SizedBox(width: 8),
                  CustomIconButton(
                      icon: Icons.settings_outlined,
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                      size: 24),
                ],
              )
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCurrentDate(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _getDisplayedMonth(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        centerTitle: false,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 10,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .tertiary,
        child: Icon(
          Icons.add,
          color: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadHabits,
        child: ListView(
          children: [
            const SizedBox(height: 16),
            _buildHeatMap(),
            const SizedBox(height: 16),
            _buildHabitList(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatMap() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    int totalHabits = currentHabits.length;
    totalHabits = totalHabits > 0 ? totalHabits : 1;

    return FutureBuilder(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Heatmap(
            datasets: prepMapDataset(currentHabits),
            startDate: snapshot.data!,
            totalHabits: totalHabits,
            currentDisplayedMonth: _currentDisplayedMonth,
            currentHabits: currentHabits, // Pass the current habits
          );
        } else {
          return Container();
        }
      },
    );
  }

  // Add this helper method to calculate habits per day
  Map<DateTime, int> calculateHabitsPerDay(List<Habit> habits, DateTime currentDisplayedMonth) {
    Map<DateTime, int> habitsPerDay = {};

    // Calculate first day of displayed month
    final DateTime firstDayOfMonth = DateTime(currentDisplayedMonth.year, currentDisplayedMonth.month, 6);

    // Calculate last day of displayed month
    final DateTime lastDayOfMonth = DateTime(currentDisplayedMonth.year, currentDisplayedMonth.month + 2, 0);

    // For each day in the displayed month range
    for (DateTime date = firstDayOfMonth; date.isBefore(lastDayOfMonth.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      String dayOfWeek = DateFormat('EEEE').format(date); // e.g., "Monday"

      // Count habits assigned to this day
      int habitsForDay = habits.where((habit) =>
      habit.assignedDays != null && habit.assignedDays!.contains(dayOfWeek)
      ).length;

      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      habitsPerDay[normalizedDate] = habitsForDay;
    }

    return habitsPerDay;
  }

  Widget _buildHabitList() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;
    final today = DateFormat('EEEE').format(DateTime.now());

    return FutureBuilder<bool>(
      future: habitDatabase.isHoliday(DateTime.now()),
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
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Take a break from your events today",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    "Tap on the heatmap to toggle holidays",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<Habit> todayHabits = currentHabits.where((habit) =>
            habit.assignedDays.contains(today)).toList();

        if (todayHabits.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.calendar_add_copy, size: 120, color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2)),
                  /*SvgPicture.asset(
                      'assets/icon/calendar-add-svgrepo-com.svg',
                  height: 120,
                  width: 120),*/
                  const SizedBox(height: 8),
                  Text(
                    "No Events for $today",
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    "Create an event for $today to get started",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap + button to add an Event.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  Transform.rotate(
                    angle: -45 * (math.pi / 180), // Convert degrees to radians
                    child: Padding(
                      padding: const EdgeInsets.only(left: 80.0),
                      child: Lottie.asset(
                        'assets/lottie/arrow-anim.json',
                        repeat: false,
                        height: 180,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: todayHabits.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final habit = todayHabits[index];
            bool isCompletedToday = isHabitCompletedToday(habit);

            return HabitTile(
              isCompleted: isCompletedToday,
              eventName: habit.name,
              conductorName: habit.conductorName,
              habit: habit, // Pass the Habit object
              onChanged: (value) => checkHabitOnOff(value, habit),
              editHabit: (context) => editHabitBox(habit),
              deleteHabit: (context) => deleteHabitBox(habit),
              markNotConducted: (context) => markHabitNotConducted(habit),
            );
          },
        );
      },
    );
  }
}