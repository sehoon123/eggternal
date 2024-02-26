import 'dart:io';
import 'package:eggciting/screens/warning_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:table_calendar/table_calendar.dart'; // Import TableCalendar

class SelectDueDateScreen extends StatefulWidget {
  final String title;
  final String content;
  final List<File> images; // Assuming you're passing a list of File objects
  final LatLng? selectedLocation; // Add this line

  const SelectDueDateScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.images,
    this.selectedLocation, // Update this line
  }) : super(key: key);

  @override
  _SelectDueDateScreenState createState() => _SelectDueDateScreenState();
}

class _SelectDueDateScreenState extends State<SelectDueDateScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Due Date'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push the button to the bottom
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010,   10,   16),
            lastDay: DateTime.utc(2030,   3,   14),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  padding: const EdgeInsets.only(top:   5.0, left:   6.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle().copyWith(fontSize:   16.0),
                  ),
                );
              },
              // Remove the markersBuilder property if you're not using markers
            ),
          ),
          ElevatedButton(
            onPressed: _selectedDate != null ? () {
              // Navigate to the next screen with the title, content, selected images, due date, and selected location
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WarningScreen(
                    title: widget.title,
                    content: widget.content,
                    images: widget.images, // Pass the images to the next screen
                    dueDate: _selectedDate!,
                    selectedLocation: widget.selectedLocation, // Pass the selected location
                  ),
                ),
              );
            } : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
