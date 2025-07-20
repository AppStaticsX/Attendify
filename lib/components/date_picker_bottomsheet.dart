import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatePickerBottomSheet extends StatefulWidget {

  const DatePickerBottomSheet({
    super.key,
  });

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Text(
              'Date of Events Start',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          const Text(
            'Please select a date for event start',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              height: 150,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ElevatedButton(
              onPressed: () async {
                await _handleOnPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save_outlined,
                      size: 24,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Save Selected Date',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEventStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert DateTime to milliseconds since epoch for storage
    final int dateInMillis = selectedDate.millisecondsSinceEpoch;
    await prefs.setInt('event_start_date', dateInMillis);
  }

  Future<void> _handleOnPressed() async {
    _saveEventStartDate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('datePickerBSShown', true);
  }
}