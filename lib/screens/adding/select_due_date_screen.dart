import 'dart:io';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/adding/warning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:table_calendar/table_calendar.dart'; // Import TableCalendar

class SelectDueDateScreen extends StatefulWidget {
  final Post post;

  const SelectDueDateScreen({
    super.key,
    required this.post,
  });

  @override
  _SelectDueDateScreenState createState() => _SelectDueDateScreenState();
}

class _SelectDueDateScreenState extends State<SelectDueDateScreen> {
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Due Date'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Theme(
                // Wrap TableCalendar with Theme
                data: ThemeData(
                  // Provide custom ThemeData
                  primaryColor: Colors.red, // Set primary color to red
                  hintColor:
                      Colors.red, // Set accent color to red for selection
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
                                        title: Text(
                                            '${DateTime.now().year + index}'),
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16.0),
                        ),
                      );
                    },
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _selectedDate != null
                    ? () {
                        // Create a new Post object with the updated dueDate
                        final updatedPost = Post(
                          key: widget.post.key,
                          title: widget.post.title,
                          contentDelta: widget.post.contentDelta,
                          dueDate: _selectedDate!, // Use the selected date
                          createdAt: widget.post.createdAt,
                          userId: widget.post.userId,
                          location: widget.post.location,
                          imageUrls: widget.post.imageUrls,
                          sharedUser: widget.post.sharedUser,
                        );

                        // Navigate to the next screen, passing the updated Post object along
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WarningScreen(post: updatedPost),
                          ),
                        );
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
