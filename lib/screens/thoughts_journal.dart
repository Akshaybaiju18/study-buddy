import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _entriesCollection = FirebaseFirestore.instance.collection('journal_entries');
  
  Map<String, List<JournalEntry>> _entriesByDate = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEntries();
  }
  
  // Load entries from Firestore
  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all entries ordered by timestamp
      QuerySnapshot querySnapshot = await _entriesCollection
          .orderBy('timestamp', descending: true)
          .get();
      
      Map<String, List<JournalEntry>> tempEntries = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final entry = JournalEntry(
          id: doc.id,
          text: data['text'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
        
        final dateKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);
        
        if (tempEntries.containsKey(dateKey)) {
          tempEntries[dateKey]!.add(entry);
        } else {
          tempEntries[dateKey] = [entry];
        }
      }
      
      setState(() {
        _entriesByDate = tempEntries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading entries: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Add entry to Firestore
  Future<void> _addEntry() async {
    if (_entryController.text.isNotEmpty) {
      try {
        final now = DateTime.now();
        
        // Add entry to Firestore
        await _entriesCollection.add({
          'text': _entryController.text,
          'timestamp': Timestamp.fromDate(now),
        });
        
        // Reload entries to get the updated list including the new entry
        await _loadEntries();
        
        // Clear the text field
        _entryController.clear();
      } catch (e) {
        print('Error adding entry: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add entry. Please try again.')),
        );
      }
    }
  }
  
  // Delete entry from Firestore
  Future<void> _deleteEntry(String dateKey, JournalEntry entry) async {
    try {
      // Delete from Firestore
      await _entriesCollection.doc(entry.id).delete();
      
      // Update local state
      setState(() {
        _entriesByDate[dateKey]!.remove(entry);
        if (_entriesByDate[dateKey]!.isEmpty) {
          _entriesByDate.remove(dateKey);
        }
      });
    } catch (e) {
      print('Error deleting entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete entry. Please try again.')),
      );
    }
  }

  // Update an entry in Firestore
  Future<void> _updateEntry(String id, String newText) async {
    try {
      await _entriesCollection.doc(id).update({
        'text': newText,
      });
      
      // Reload entries to reflect changes
      await _loadEntries();
    } catch (e) {
      print('Error updating entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update entry. Please try again.')),
      );
    }
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
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEntries,
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : sortedDates.isEmpty
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
                        _showEditEntryDialog(entry);
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

  void _showEditEntryDialog(JournalEntry entry) {
    final textController = TextEditingController(text: entry.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Entry"),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: InputDecoration(
            fillColor: bgColor,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _updateEntry(entry.id, textController.text);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
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
                  onPressed: () async {
                    if (textController.text.isNotEmpty) {
                      try {
                        final now = DateTime.now();
                        
                        // Add entry to Firestore
                        await _entriesCollection.add({
                          'text': textController.text,
                          'timestamp': Timestamp.fromDate(now),
                        });
                        
                        // Reload entries
                        await _loadEntries();
                        
                        Navigator.pop(context);
                      } catch (e) {
                        print('Error adding entry: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add entry. Please try again.')),
                        );
                      }
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
  final String id;
  final String text;
  final DateTime timestamp;
  
  JournalEntry({
    required this.id,
    required this.text,
    required this.timestamp,
  });
}