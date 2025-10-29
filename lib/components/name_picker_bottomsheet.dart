import 'package:attendify/components/custom_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NamePickerBottomsheet extends StatefulWidget {
  final VoidCallback? onNameUpdated; // Add callback parameter

  const NamePickerBottomsheet({
    super.key,
    this.onNameUpdated, // Optional callback
  });

  @override
  State<NamePickerBottomsheet> createState() => _NamePickerBottomSheetState();
}

class _NamePickerBottomSheetState extends State<NamePickerBottomsheet> {
  TextEditingController textEditingController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  // Load current name when bottomsheet opens
  Future<void> _loadCurrentName() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentName = prefs.getString('userNAME');
    if (currentName != null && currentName.isNotEmpty) {
      setState(() {
        textEditingController.text = currentName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24.0, left: 24.0),
            child: Text(
              'Edit Name',
              style: TextStyle(
                fontSize: 22,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: TextField(
              controller: textEditingController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 34
              ),
              onSubmitted: (value) {
                // Allow saving with Enter key
                _handleOnPressed();
                Navigator.pop(context);
              },
            ),
          ),

          Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomIconButton(
                    icon: Iconsax.close_circle_copy,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    size: 32,
                    iconColor: Colors.white,
                    color: const Color(0xFF2A2A2A),
                    toolTip: 'Close',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleOnPressed();
                    Navigator.pop(context);
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
                          Iconsax.import_2,
                          size: 24,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Save',
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
        ],
      ),
    );
  }

  Future<void> _handleOnPressed() async {
    final userName = textEditingController.text.trim();
    if (userName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userNAME', userName);

      // Call the callback to update the parent widget
      if (widget.onNameUpdated != null) {
        widget.onNameUpdated!();
      }
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}