import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BedtimeTrackerPage extends StatefulWidget {
  const BedtimeTrackerPage({super.key});

  @override
  _BedtimeTrackerPageState createState() => _BedtimeTrackerPageState();
}

class _BedtimeTrackerPageState extends State<BedtimeTrackerPage> {
  // Firebase references
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  
  // Time variables
  TimeOfDay _bedtime = TimeOfDay(hour: 22, minute: 0); // Default: 10:00 PM
  TimeOfDay _wakeupTime = TimeOfDay(hour: 6, minute: 0); // Default: 6:00 AM
  bool _alarmSet = false;
  bool _isLoading = true;
  
  // Sleep stats
  List<double> _weekSleepData = [7.5, 6.8, 7.2, 8.0, 7.5, 6.5, 7.0];
  double _averageSleepTime = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeUser();
  }
  
  Future<void> _initializeUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      await _loadUserData();
      _calculateAverageSleep();
    } else {
      // Handle case where user is not logged in
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your sleep data'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the user's bedtime settings
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sleepData')
          .doc('settings')
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        
        setState(() {
          // Load bedtime
          int bedtimeHour = data['bedtimeHour'] ?? 22;
          int bedtimeMinute = data['bedtimeMinute'] ?? 0;
          _bedtime = TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute);
          
          // Load wakeup time
          int wakeupHour = data['wakeupHour'] ?? 6;
          int wakeupMinute = data['wakeupMinute'] ?? 0;
          _wakeupTime = TimeOfDay(hour: wakeupHour, minute: wakeupMinute);
          
          // Load alarm state
          _alarmSet = data['alarmSet'] ?? false;
        });
      }
      
      // Get the user's weekly sleep data
      QuerySnapshot sleepHistorySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sleepData')
          .doc('history')
          .collection('days')
          .orderBy('date', descending: true)
          .limit(7)
          .get();
          
      if (sleepHistorySnapshot.docs.isNotEmpty) {
        List<double> weekData = [];
        for (var doc in sleepHistorySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          weekData.add(data['hoursSlept'] ?? 7.0);
        }
        
        // If we have less than 7 days of data, fill with defaults
        while (weekData.length < 7) {
          weekData.add(7.0);
        }
        
        setState(() {
          _weekSleepData = weekData;
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sleep data: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _saveUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;
      
      // Save bedtime settings
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sleepData')
          .doc('settings')
          .set({
        'bedtimeHour': _bedtime.hour,
        'bedtimeMinute': _bedtime.minute,
        'wakeupHour': _wakeupTime.hour,
        'wakeupMinute': _wakeupTime.minute,
        'alarmSet': _alarmSet,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Calculate and save today's sleep data
      double sleepHours = _calculateSleepHours();
      DateTime now = DateTime.now();
      String dateString = DateFormat('yyyy-MM-dd').format(now);
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sleepData')
          .doc('history')
          .collection('days')
          .doc(dateString)
          .set({
        'date': dateString,
        'bedtimeHour': _bedtime.hour,
        'bedtimeMinute': _bedtime.minute,
        'wakeupHour': _wakeupTime.hour,
        'wakeupMinute': _wakeupTime.minute,
        'hoursSlept': sleepHours,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving sleep data'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _calculateAverageSleep() {
    double sum = 0;
    for (var hours in _weekSleepData) {
      sum += hours;
    }
    _averageSleepTime = sum / _weekSleepData.length;
  }
  
  double _calculateSleepHours() {
    // Convert to minutes for calculation
    int bedtimeMinutes = _bedtime.hour * 60 + _bedtime.minute;
    int wakeupMinutes = _wakeupTime.hour * 60 + _wakeupTime.minute;
    
    // Adjust if wakeup is earlier in the day than bedtime
    if (wakeupMinutes < bedtimeMinutes) {
      wakeupMinutes += 24 * 60; // Add a day
    }
    
    // Calculate difference and convert to hours
    double hours = (wakeupMinutes - bedtimeMinutes) / 60.0;
    return double.parse(hours.toStringAsFixed(1));
  }
  
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }
  
  Future<void> _selectBedtime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      helpText: 'Select your bedtime',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              surface: Color(0xFF303F9F), // indigo.shade800
              onSurface: Colors.white,
            ), 
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A237E)), // indigo.shade900
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _bedtime = picked;
      });
      await _saveUserData();
    }
  }
  
  Future<void> _selectWakeupTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeupTime,
      helpText: 'Select your wake-up time',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              surface: Color(0xFF303F9F), // indigo.shade800
              onSurface: Colors.white,
            ), 
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A237E)), // indigo.shade900
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _wakeupTime = picked;
      });
      await _saveUserData();
    }
  }
  
  void _toggleAlarm() async {
    setState(() {
      _alarmSet = !_alarmSet;
    });
    await _saveUserData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_alarmSet 
          ? 'Alarm set for ${_formatTimeOfDay(_wakeupTime)}' 
          : 'Alarm turned off'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _alarmSet ? Colors.indigo : Colors.grey.shade700,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final sleepHours = _calculateSleepHours();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF283593), // indigo.shade800
        elevation: 0,
        title: const Text('Bedtime Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to sleep history
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sleep history coming soon'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(sleepHours),
                _buildTimePickers(),
                const SizedBox(height: 8),
                _buildSleepStats(),
                const SizedBox(height: 8),
                _buildTips(),
              ],
            ),
          ),
    );
  }
  
  Widget _buildHeader(double sleepHours) {
    // Determine sleep quality based on hours
    String sleepQuality = "Poor";
    Color qualityColor = Colors.red;
    
    if (sleepHours >= 7 && sleepHours <= 9) {
      sleepQuality = "Optimal";
      qualityColor = Colors.green;
    } else if (sleepHours >= 6 && sleepHours < 7) {
      sleepQuality = "Fair";
      qualityColor = Colors.orange;
    } else if (sleepHours > 9) {
      sleepQuality = "Excessive";
      qualityColor = Colors.orange;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF283593), // indigo.shade800
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            "${sleepHours.toString()} Hours",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "of sleep scheduled",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: qualityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "$sleepQuality Sleep Duration",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: qualityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimePickers() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sleep Schedule",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectBedtime,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.indigo.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Bedtime",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            Icon(
                              Icons.nightlight,
                              color: Colors.indigo.shade800,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimeOfDay(_bedtime),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap to change",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectWakeupTime,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Wake up",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            Icon(
                              Icons.wb_sunny,
                              color: Colors.amber.shade800,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimeOfDay(_wakeupTime),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap to change",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggleAlarm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _alarmSet 
                  ? const Color(0xFF3949AB) // indigo.shade700
                  : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm,
                    color: _alarmSet ? Colors.white : Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _alarmSet 
                      ? "Alarm set for ${_formatTimeOfDay(_wakeupTime)}" 
                      : "Set Alarm",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _alarmSet ? Colors.white : Colors.grey.shade600,
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
  
  Widget _buildSleepStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sleep Insights",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInsightCard(
                title: "Weekly Avg",
                value: "${_averageSleepTime.toStringAsFixed(1)}h",
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _buildInsightCard(
                title: "Consistency",
                value: "Good",
                icon: Icons.repeat,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInsightCard(
                title: "Optimal",
                value: "7-9h",
                icon: Icons.check_circle,
                color: Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "This Week",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Row(
              children: List.generate(7, (index) {
                final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                double barHeight = (_weekSleepData[index] / 10) * 80;
                // Cap the bar height to avoid overflow
                barHeight = barHeight.clamp(0, 80);
                
                Color barColor = Colors.red;
                if (_weekSleepData[index] >= 7 && _weekSleepData[index] <= 9) {
                  barColor = Colors.green;
                } else if (_weekSleepData[index] >= 6) {
                  barColor = Colors.orange;
                }
                
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: barColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekSleepData[index].toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabels[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Sleep Better Tips",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            "Avoid screens before bed",
            "Blue light can disrupt melatonin production.",
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            "Keep a consistent schedule",
            "Go to bed and wake up at the same time daily.",
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            "Create a relaxing routine",
            "Read, take a warm bath, or meditate.",
          ),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.indigo,
            size: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}