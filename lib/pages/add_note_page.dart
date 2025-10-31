import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Notes',
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
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        elevation: 10,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
