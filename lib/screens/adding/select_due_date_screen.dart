import 'dart:io';
import 'package:eggciting/screens/adding/warning_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:table_calendar/table_calendar.dart'; // Import TableCalendar

class SelectDueDateScreen extends StatefulWidget {
  final String title;
  final String content;
  final List<File> images; // Assuming you're passing a list of File objects
  final LatLng? selectedLocation; // Add this line

  const SelectDueDateScreen({
    super.key,
    required this.title,
    required this.content,
    required this.images,
    this.selectedLocation, // Update this line
  });

  @override
  _SelectDueDateScreenState createState() => _SelectDueDateScreenState();
}

class _SelectDueDateScreenState extends State<SelectDueDateScreen> {
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Due Date'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Theme(
            // Wrap TableCalendar with Theme
            data: ThemeData(
              // Provide custom ThemeData
              primaryColor: Colors.red, // Set primary color to red
              hintColor: Colors.red, // Set accent color to red for selection
              colorScheme: const ColorScheme.light(
                  primary: Colors.red), // For newer versions of Flutter
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2100, 3, 14),
              focusedDay: _focusedDay,
              onHeaderTapped: (focusedDay) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                          title: const Text('Select Year'),
                          content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                itemCount: 31,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title:
                                        Text('${DateTime.now().year + index}'),
                                    onTap: () {
                                      setState(() {
                                        _focusedDay = DateTime(
                                            DateTime.now().year + index,
                                            _focusedDay.month,
                                            _focusedDay.day);
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              )));
                    });
              },
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedDate = selectedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, date, _) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red, // Ensure this is red
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      '${date.day}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _selectedDate != null
                ? () {
                    // Your existing navigation logic
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WarningScreen(
                          title: widget.title,
                          content: widget.content,
                          images: widget.images,
                          dueDate:
                              _selectedDate!, // Ensure _selectedDate is passed correctly
                          selectedLocation: widget.selectedLocation,
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
