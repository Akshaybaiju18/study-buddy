import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Color palette
final Color primaryColor = const Color(0xFF3A4276);
final Color secondaryColor = const Color(0xFF5C6BC0);
final Color accentColor = const Color(0xFFFF9800);
final Color textDarkColor = const Color(0xFF2E3440);
final Color textLightColor = const Color(0xFF78849E);
final Color bgColor = const Color(0xFFF9FAFC);
final Color cardColor = Colors.white;

class PersonalCalendar extends StatefulWidget {
  const PersonalCalendar({super.key});

  @override
  _PersonalCalendarState createState() => _PersonalCalendarState();
}

class _PersonalCalendarState extends State<PersonalCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final Map<DateTime, List<Event>> _events = {};
  
  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent() {
    if (_selectedDay != null && _eventController.text.isNotEmpty) {
      final eventText = _eventController.text;
      final eventTime = _eventTimeController.text.isEmpty 
          ? null 
          : _eventTimeController.text;
      
      final event = Event(
        title: eventText,
        time: eventTime,
      );
      
      setState(() {
        final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
        if (_events[selectedDate] != null) {
          _events[selectedDate]!.add(event);
        } else {
          _events[selectedDate] = [event];
        }
      });
      
      _eventController.clear();
      _eventTimeController.clear();
    }
  }
  
  void _deleteEvent(Event event, DateTime date) {
    setState(() {
      final selectedDate = DateTime(date.year, date.month, date.day);
      _events[selectedDate]?.remove(event);
      if (_events[selectedDate]?.isEmpty ?? false) {
        _events.remove(selectedDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          "Calendar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(8.0),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(color: textLightColor),
                  outsideTextStyle: TextStyle(color: textLightColor.withOpacity(0.5)),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                  rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
                  titleTextStyle: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat('MMMM d, yyyy').format(_selectedDay!)
                      : "No date selected",
                  style: TextStyle(
                    color: textDarkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  icon: Icon(Icons.add, color: accentColor),
                  label: Text(
                    "Add Event",
                    style: TextStyle(color: accentColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: accentColor.withOpacity(0.3)),
                    ),
                    backgroundColor: accentColor.withOpacity(0.1),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildAddEventSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDay != null && _getEventsForDay(_selectedDay!).isNotEmpty
                ? ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay!)[index];
                      return _buildEventCard(event);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: textLightColor.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No events scheduled",
                          style: TextStyle(
                            color: textLightColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: cardColor,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 8,
          height: double.infinity,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: event.time != null
            ? Text(
                event.time!,
                style: TextStyle(color: textLightColor),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: textLightColor),
          onPressed: () => _deleteEvent(event, _selectedDay!),
        ),
      ),
    );
  }

  Widget _buildAddEventSheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add New Event",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _eventController,
              decoration: InputDecoration(
                hintText: "Event title",
                hintStyle: TextStyle(color: textLightColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.event, color: secondaryColor),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _eventTimeController,
              decoration: InputDecoration(
                hintText: "Event time (optional)",
                hintStyle: TextStyle(color: textLightColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.access_time, color: secondaryColor),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: textLightColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _addEvent();
                    Navigator.pop(context);
                  },
                  child: Text("Add"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String title;
  final String? time;
  
  Event({required this.title, this.time});
}