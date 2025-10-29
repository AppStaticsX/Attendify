import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/models/event.dart';

class EditEventPage extends StatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController textController = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  final TextEditingController courseCodeController = TextEditingController();
  final TextEditingController creditHoursController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController semesterController = TextEditingController();
  final TextEditingController minAttendanceController = TextEditingController();
  final TextEditingController totalLecturesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> _weekdaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;
  bool _courseNameFocused = false;
  bool _professorFocused = false;
  bool _courseCodeFocused = false;
  bool _creditHoursFocused = false;
  bool _startTimeFocused = false;
  bool _endTimeFocused = false;
  bool _locationFocused = false;
  bool _semesterFocused = false;
  bool _minAttendanceFocused = false;
  bool _totalLecturesFocused = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _semesterOptions = ['SEM-1', 'SEM-2', 'SEM-3', 'SEM-4'];
  late String _selectedSemester;

  @override
  void initState() {
    super.initState();

    _selectedSemester = _semesterOptions.contains(widget.event.semester)
        ? widget.event.semester
        : _semesterOptions.first;

    // Load existing event data
    _loadEventData();

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

  void _loadEventData() {
    // Load course information
    textController.text = widget.event.name;
    textController2.text = widget.event.conductorName;
    courseCodeController.text = widget.event.courseCode;
    creditHoursController.text = widget.event.creditHours.toString();
    locationController.text = widget.event.location;
    semesterController.text = _selectedSemester;
    minAttendanceController.text = widget.event.minAttendanceRequired.toString();
    totalLecturesController.text = widget.event.totalLecturesPlanned.toString();

    // Load lecture time
    if (widget.event.lectureTime.isNotEmpty) {
      final timeParts = widget.event.lectureTime.split(' - ');
      if (timeParts.length == 2) {
        startTimeController.text = timeParts[0].trim();
        endTimeController.text = timeParts[1].trim();

        // Parse TimeOfDay from string
        _startTime = _parseTimeOfDay(timeParts[0].trim());
        _endTime = _parseTimeOfDay(timeParts[1].trim());
      }
    }

    // Load selected days
    for (int i = 0; i < _weekdays.length; i++) {
      _selectedDays[i] = widget.event.assignedDays.contains(_weekdays[i]);
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minuteParts = parts[1].split(' ');
        final minute = int.parse(minuteParts[0]);
        final period = minuteParts.length > 1 ? minuteParts[1].toUpperCase() : 'AM';

        int adjustedHour = hour;
        if (period == 'PM' && hour != 12) {
          adjustedHour = hour + 12;
        } else if (period == 'AM' && hour == 12) {
          adjustedHour = 0;
        }

        return TimeOfDay(hour: adjustedHour, minute: minute);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  String _getCurrentSemester() {
    final now = DateTime.now();
    final year = now.year;
    return now.month <= 6 ? 'Spring $year' : 'Fall $year';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _updateLectureTimeDisplay() {
    if (_startTime != null && _endTime != null) {
      startTimeController.text = _formatTimeOfDay(_startTime!);
      endTimeController.text = _formatTimeOfDay(_endTime!);
    } else if (_startTime != null) {
      startTimeController.text = _formatTimeOfDay(_startTime!);
      endTimeController.text = '';
    } else {
      startTimeController.text = '';
      endTimeController.text = '';
    }
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.inversePrimary,
              dialHandColor: Theme.of(context).colorScheme.tertiary,
              dialBackgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              dayPeriodTextColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        _updateLectureTimeDisplay();
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.inversePrimary,
              dialHandColor: Theme.of(context).colorScheme.tertiary,
              dialBackgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              dayPeriodTextColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _updateLectureTimeDisplay();
      });
    }
  }

  @override
  void dispose() {
    textController.dispose();
    textController2.dispose();
    courseCodeController.dispose();
    creditHoursController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    locationController.dispose();
    semesterController.dispose();
    minAttendanceController.dispose();
    totalLecturesController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String courseName = textController.text.trim();
    String professorName = textController2.text.trim();
    String courseCode = courseCodeController.text.trim();
    int creditHours = int.tryParse(creditHoursController.text.trim()) ?? 3;
    String lectureTime = '${startTimeController.text.trim()} - ${endTimeController.text.trim()}';
    String location = locationController.text.trim();
    String semester = semesterController.text.trim();
    double minAttendance = double.tryParse(minAttendanceController.text.trim()) ?? 75.0;
    int totalLectures = int.tryParse(totalLecturesController.text.trim()) ?? 0;

    List<String> selectedDays = [];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDays.add(_weekdays[i]);
      }
    }

    if (courseName.isEmpty) {
      _showCustomToast(
        'Please enter course name',
        Iconsax.warning_2,
        durationInSeconds: 3,
      );
      return;
    }

    if (professorName.isEmpty) {
      _showCustomToast(
        'Please enter professor name',
        Iconsax.warning_2,
        durationInSeconds: 3,
      );
      return;
    }

    if (selectedDays.isEmpty) {
      _showCustomToast(
        'Please select at least one day',
        Iconsax.warning_2,
        durationInSeconds: 3,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update event with basic info
      await context.read<EventDatabase>().updateEvent(
        widget.event.id,
        courseName,
        selectedDays,
        professorName,
      );

      // Update additional fields
      widget.event.courseCode = courseCode;
      widget.event.creditHours = creditHours;
      widget.event.lectureTime = lectureTime;
      widget.event.location = location;
      widget.event.semester = semester;
      widget.event.minAttendanceRequired = minAttendance;
      widget.event.totalLecturesPlanned = totalLectures;
      await widget.event.save();

      if (mounted) {
        _showCustomToast('Course updated successfully!', Iconsax.tick_circle);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showCustomToast('Failed to update course: $e', Iconsax.close_circle,
            durationInSeconds: 3);
      }
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
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.4),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
    required Function(bool) onFocusChange,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextFormField(
        controller: controller,
        validator: validator,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7),
            ),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused
                ? Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7),
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
              ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 18.0, horizontal: 20.0),
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
          'EDIT COURSE',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Iconsax.arrow_left_2_copy)
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Course Details Section
                  _buildSectionHeader(
                    'Course Information',
                    Iconsax.book_1_copy,
                    'Basic details about the course',
                  ),
                  const SizedBox(height: 16),

                  // Course Name Field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildTextField(
                        controller: textController,
                        label: 'Course Name',
                        hint: 'e.g., Data Structures, Calculus I',
                        icon: Iconsax.book_copy,
                        isFocused: _courseNameFocused,
                        onFocusChange: (focused) {
                          setState(() {
                            _courseNameFocused = focused;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Course name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Course Code and Credit Hours Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: _buildTextField(
                              controller: courseCodeController,
                              label: 'Course Code',
                              hint: 'e.g., IT2401',
                              icon: Iconsax.code_copy,
                              isFocused: _courseCodeFocused,
                              onFocusChange: (focused) {
                                setState(() {
                                  _courseCodeFocused = focused;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: _buildTextField(
                              controller: creditHoursController,
                              label: 'Credits',
                              hint: '3',
                              icon: Iconsax.medal_star_copy,
                              isFocused: _creditHoursFocused,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              keyboardType: TextInputType.number,
                              onFocusChange: (focused) {
                                setState(() {
                                  _creditHoursFocused = focused;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Professor Name Field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildTextField(
                        controller: textController2,
                        label: 'Professor / Instructor',
                        hint: 'e.g., Dr. John Smith',
                        icon: Iconsax.teacher_copy,
                        isFocused: _professorFocused,
                        onFocusChange: (focused) {
                          setState(() {
                            _professorFocused = focused;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Professor name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Schedule Section
                  _buildSectionHeader(
                    'Schedule & Location',
                    Iconsax.calendar_1_copy,
                    'When and where the lectures happen',
                  ),
                  const SizedBox(height: 16),

                  // Lecture Time Field
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickStartTime,
                          child: AbsorbPointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: _buildTextField(
                                  controller: startTimeController,
                                  label: 'Start Time',
                                  hint: 'Tap to select start time',
                                  icon: Iconsax.clock_copy,
                                  isFocused: _startTimeFocused,
                                  onFocusChange: (focused) {
                                    setState(() {
                                      _startTimeFocused = focused;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickEndTime,
                          child: AbsorbPointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: _buildTextField(
                                  controller: endTimeController,
                                  label: 'End Time',
                                  hint: 'Tap to select end time',
                                  icon: Iconsax.clock_copy,
                                  isFocused: _endTimeFocused,
                                  onFocusChange: (focused) {
                                    setState(() {
                                      _endTimeFocused = focused;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildTextField(
                        controller: locationController,
                        label: 'Location / Room',
                        hint: 'e.g., Room 204, Lab A',
                        icon: Iconsax.location_copy,
                        isFocused: _locationFocused,
                        onFocusChange: (focused) {
                          setState(() {
                            _locationFocused = focused;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Days Selection Card
                  Container(
                    padding: const EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lecture Days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _weekdays.length,
                          itemBuilder: (context, index) {
                            return _buildDayChip(index);
                          },
                        ),
                        const SizedBox(height: 16)
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Attendance Settings Section
                  _buildSectionHeader(
                    'Attendance Settings',
                    Iconsax.chart_21_copy,
                    'Configure attendance tracking parameters',
                  ),
                  const SizedBox(height: 16),

                  // Semester and Min Attendance Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: DropdownButtonFormField<String>(
                              value: _selectedSemester,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Iconsax.calendar_2_copy,
                                  color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7),
                                ),
                                labelText: 'Semester',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7),
                                    width: 2.0,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18.0, horizontal: 20.0),
                              ),
                              dropdownColor: Theme.of(context).colorScheme.surface,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.inversePrimary,
                                fontSize: 16,
                              ),
                              items: _semesterOptions.map((String semester) {
                                return DropdownMenuItem<String>(
                                  value: semester,
                                  child: Text(semester, style: TextStyle(fontFamily: 'JetBrains Mono')),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSemester = newValue;
                                    semesterController.text = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: _buildTextField(
                              controller: minAttendanceController,
                              label: 'Min % Required',
                              hint: '75',
                              icon: Iconsax.percentage_circle_copy,
                              isFocused: _minAttendanceFocused,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              keyboardType: TextInputType.number,
                              onFocusChange: (focused) {
                                setState(() {
                                  _minAttendanceFocused = focused;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total Lectures Planned Field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildTextField(
                        controller: totalLecturesController,
                        label: 'Total Lectures Planned (Optional)',
                        hint: 'e.g., 40 lectures in semester',
                        icon: Iconsax.data_copy,
                        isFocused: _totalLecturesFocused,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        keyboardType: TextInputType.number,
                        onFocusChange: (focused) {
                          setState(() {
                            _totalLecturesFocused = focused;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateEvent,
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
                Icon(Iconsax.tick_circle_copy, size: 22),
                const SizedBox(width: 8),
                Text(
                  'UPDATE COURSE',
                  style: TextStyle(
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

  Widget _buildDayChip(int index) {
    final isSelected = _selectedDays[index];
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDays[index] = !_selectedDays[index];
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.inverseSurface
              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.inverseSurface
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdaysShort[index],
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
