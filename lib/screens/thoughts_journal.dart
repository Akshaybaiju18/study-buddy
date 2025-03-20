import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Color palette
final Color primaryColor = const Color(0xFF3A4276);
final Color secondaryColor = const Color(0xFF5C6BC0);
final Color accentColor = const Color(0xFFFF9800);
final Color textDarkColor = const Color(0xFF2E3440);
final Color textLightColor = const Color(0xFF78849E);
final Color bgColor = const Color(0xFFF9FAFC);
final Color cardColor = Colors.white;

class ThoughtsJournal extends StatefulWidget {
  const ThoughtsJournal({super.key});

  @override
  _ThoughtsJournalState createState() => _ThoughtsJournalState();
}

class _ThoughtsJournalState extends State<ThoughtsJournal> {
  final TextEditingController _entryController = TextEditingController();
  final Map<String, List<JournalEntry>> _entriesByDate = {};
  
  @override
  void initState() {
    super.initState();
    // Add some example entries for demonstration
    _addSampleEntries();
  }
  
  void _addSampleEntries() {
    // This is just for demonstration purposes
    // You would remove this in a real app
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    final twoDaysAgo = today.subtract(Duration(days: 2));
    
    _addEntryWithDate("Started my day with meditation. Feeling calm and focused.", today);
    _addEntryWithDate("Work meeting went well. New project looks promising.", today);
    _addEntryWithDate("Feeling a bit stressed about the upcoming deadline.", yesterday);
    _addEntryWithDate("Had a great conversation with an old friend today.", twoDaysAgo);
  }
  
  void _addEntry() {
    if (_entryController.text.isNotEmpty) {
      _addEntryWithDate(_entryController.text, DateTime.now());
      _entryController.clear();
    }
  }
  
  void _addEntryWithDate(String text, DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    setState(() {
      if (_entriesByDate.containsKey(dateKey)) {
        _entriesByDate[dateKey]!.add(
          JournalEntry(
            text: text, 
            timestamp: date,
          ),
        );
      } else {
        _entriesByDate[dateKey] = [
          JournalEntry(
            text: text, 
            timestamp: date,
          ),
        ];
      }
    });
  }
  
  void _deleteEntry(String dateKey, JournalEntry entry) {
    setState(() {
      _entriesByDate[dateKey]!.remove(entry);
      if (_entriesByDate[dateKey]!.isEmpty) {
        _entriesByDate.remove(dateKey);
      }
    });
  }
  
  String _formatDateForDisplay(String dateKey) {
    final date = DateFormat('yyyy-MM-dd').parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return "Today";
    } else if (date.isAtSameMomentAs(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = _entriesByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          "Thoughts Journal",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _entryController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: "Write your thoughts...",
                hintStyle: TextStyle(color: textLightColor),
                fillColor: bgColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: accentColor),
                  onPressed: _addEntry,
                ),
              ),
            ),
          ),
          Expanded(
            child: sortedDates.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDates[index];
                      return _buildDateSection(dateKey);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        elevation: 2,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildAddEntrySheet(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: textLightColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            "Your journal is empty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textLightColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Start writing your thoughts",
            style: TextStyle(
              color: textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(String dateKey) {
    final entries = _entriesByDate[dateKey]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                _formatDateForDisplay(dateKey),
                style: TextStyle(
                  color: textDarkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => _buildEntryCard(dateKey, entry)),
      ],
    );
  }

  Widget _buildEntryCard(String dateKey, JournalEntry entry) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12, left: 8, right: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.text,
              style: TextStyle(
                color: textDarkColor,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('h:mm a').format(entry.timestamp),
                  style: TextStyle(
                    color: textLightColor,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20, color: textLightColor),
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(8),
                      onPressed: () {
                        // Implement edit functionality
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: textLightColor),
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(8),
                      onPressed: () => _deleteEntry(dateKey, entry),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEntrySheet() {
    final textController = TextEditingController();
    
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
              "New Journal Entry",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(color: textLightColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
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
                    if (textController.text.isNotEmpty) {
                      _addEntryWithDate(textController.text, DateTime.now());
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEntry {
  final String text;
  final DateTime timestamp;
  
  JournalEntry({
    required this.text,
    required this.timestamp,
  });
}