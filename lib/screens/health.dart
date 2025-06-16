import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({Key? key}) : super(key: key);

  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  
  // Theme colors
  final Color secondaryColor = const Color(0xFF5C6BC0);
  final Color waterColor = const Color(0xFF42A5F5);
  final Color exerciseColor = const Color(0xFF66BB6A);
  final Color moodColor = const Color(0xFFFFB74D);
  
  // Form controllers
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _exerciseController = TextEditingController();
  
  // Date selection
  DateTime _selectedDate = DateTime.now();
  
  // Selected mood
  String _selectedMood = 'neutral';
  
  // Health data
  Map<String, dynamic> _healthData = {
    'water': 0,
    'exercise': 0,
    'mood': 'neutral',
  };
  
  // Weekly data for charts
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;
  
  // Mood options with emojis
  final List<Map<String, dynamic>> _moods = [
    {'value': 'very_happy', 'emoji': '😄', 'label': 'Very Happy'},
    {'value': 'happy', 'emoji': '🙂', 'label': 'Happy'},
    {'value': 'neutral', 'emoji': '😐', 'label': 'Neutral'},
    {'value': 'sad', 'emoji': '🙁', 'label': 'Sad'},
    {'value': 'very_sad', 'emoji': '😢', 'label': 'Very Sad'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTodayData();
    _fetchWeeklyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waterController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  // Fetch today's health data
  Future<void> _fetchTodayData() async {
    setState(() => _isLoading = true);
    
    try {
      String userId = _auth.currentUser!.uid;
      String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      DocumentSnapshot doc = await _firestore
          .collection('health')
          .doc('$userId-$dateString')
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _healthData = data;
          _waterController.text = data['water'].toString();
          _exerciseController.text = data['exercise'].toString();
          _selectedMood = data['mood'] ?? 'neutral';
        });
      } else {
        setState(() {
          _healthData = {
            'water': 0,
            'exercise': 0,
            'mood': 'neutral',
          };
          _waterController.text = "0";
          _exerciseController.text = "0";
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fetch weekly health data for charts
  Future<void> _fetchWeeklyData() async {
    try {
      String userId = _auth.currentUser!.uid;
      DateTime now = DateTime.now();
      
      List<Map<String, dynamic>> weekData = [];
      
      // Create default values for past 7 days
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String dateStr = DateFormat('yyyy-MM-dd').format(date);
        weekData.add({
          'date': dateStr,
          'water': 0,
          'exercise': 0,
          'mood': 'neutral',
        });
      }
      
      // Fetch actual data for each day
      for (int i = 0; i < weekData.length; i++) {
        String dateStr = weekData[i]['date'];
        DocumentSnapshot doc = await _firestore
            .collection('health')
            .doc('$userId-$dateStr')
            .get();
            
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          weekData[i] = {
            'date': dateStr,
            'water': data['water'] ?? 0,
            'exercise': data['exercise'] ?? 0,
            'mood': data['mood'] ?? 'neutral',
          };
        }
      }
      
      setState(() {
        _weeklyData = weekData;
      });
    } catch (e) {
      print('Error fetching weekly data: $e');
    }
  }

  // Save health data
  Future<void> _saveHealthData() async {
    try {
      String userId = _auth.currentUser!.uid;
      String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      Map<String, dynamic> healthData = {
        'userId': userId,
        'date': dateString,
        'water': int.tryParse(_waterController.text) ?? 0,
        'exercise': int.tryParse(_exerciseController.text) ?? 0,
        'mood': _selectedMood,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('health')
          .doc('$userId-$dateString')
          .set(healthData);
      
      _showSnackBar('Health data saved successfully!');
      _fetchWeeklyData(); // Refresh charts after saving
    } catch (e) {
      _showSnackBar('Error saving data: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Pick a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: secondaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchTodayData();
    }
  }
  
  // Get mood emoji by value
  String _getMoodEmoji(String moodValue) {
    final mood = _moods.firstWhere(
      (m) => m['value'] == moodValue,
      orElse: () => _moods[2], // Default to neutral
    );
    return mood['emoji'];
  }
  
  // Get mood label by value
  String _getMoodLabel(String moodValue) {
    final mood = _moods.firstWhere(
      (m) => m['value'] == moodValue,
      orElse: () => _moods[2], // Default to neutral
    );
    return mood['label'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
  backgroundColor: secondaryColor,
  elevation: 0,
  title: const Text(
    'Health Tracker',
    style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.calendar_today, size: 22),
      onPressed: () => _selectDate(context),
      tooltip: 'Select Date',
    ),
  ],
  bottom: TabBar(
    controller: _tabController,
    indicatorColor: Colors.white,
    indicatorWeight: 3,
    labelColor: Colors.white, // Added this line to set selected tab text color
    unselectedLabelColor: Colors.white70, // Added this line for unselected tabs
    labelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
    tabs: const [
      Tab(text: 'Daily Entry', icon: Icon(Icons.edit_note, size: 22)),
      Tab(text: 'Weekly Stats', icon: Icon(Icons.insights, size: 22)),
    ],
  ),
),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: secondaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyEntryTab(),
                _buildWeeklyStatsTab(),
              ],
            ),
    );
  }

  Widget _buildDailyEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(),
          const SizedBox(height: 24),
          
          // Water intake
          _buildHealthMetricCard(
            title: 'Water Intake',
            icon: Icons.water_drop_rounded,
            color: waterColor,
            controller: _waterController,
            suffix: 'glasses',
            hint: 'Enter number of glasses',
          ),
          
          // Exercise minutes
          _buildHealthMetricCard(
            title: 'Exercise Duration',
            icon: Icons.fitness_center_rounded,
            color: exerciseColor,
            controller: _exerciseController,
            suffix: 'minutes',
            hint: 'Enter minutes of exercise',
          ),
          
          // Mood selection
          _buildMoodCard(),
          
          const SizedBox(height: 24),
          
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(_selectedDate),
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: secondaryColor, size: 28),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHealthMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String suffix,
    required String hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixText: suffix,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMoodCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.mood, color: moodColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Today\'s Mood',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.map((mood) {
                bool isSelected = _selectedMood == mood['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood['value'];
                    });
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? secondaryColor.withOpacity(0.1) : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? secondaryColor : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: secondaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Text(
                          mood['emoji'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mood['label'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? secondaryColor : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _saveHealthData,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline),
            SizedBox(width: 8),
            Text(
              'Save Health Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.insights, color: secondaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Weekly Health Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last 7 days (${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 6)))} - ${DateFormat('MMM d').format(DateTime.now())})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Water intake chart
          _buildChartCard(
            title: 'Water Intake (glasses)',
            color: waterColor,
            dataKey: 'water',
          ),
          
          // Exercise chart
          _buildChartCard(
            title: 'Exercise Duration (minutes)',
            color: exerciseColor,
            dataKey: 'exercise',
          ),
          
          // Mood summary
          _buildMoodSummaryCard(),
        ],
      ),
    );
  }
  
  Widget _buildChartCard({
    required String title,
    required Color color,
    required String dataKey,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  dataKey == 'water' ? Icons.water_drop_rounded : Icons.fitness_center_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _weeklyData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxValue(dataKey) * 1.2,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= _weeklyData.length) {
                                  return const SizedBox();
                                }
                                final date = DateTime.parse(_weeklyData[value.toInt()]['date']);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(DateFormat('E').format(date)),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return const SizedBox();
                                }
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          _weeklyData.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _weeklyData[index][dataKey].toDouble(),
                                color: color,
                                width: 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMoodSummaryCard() {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood, color: moodColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Mood Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120, // Increased height from 100 to 120
            child: _weeklyData.isEmpty
                ? const Center(child: Text('No data available'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weeklyData.length,
                    itemBuilder: (context, index) {
                      final data = _weeklyData[index];
                      final date = DateTime.parse(data['date']);
                      final bool isToday = DateFormat('yyyy-MM-dd').format(date) == 
                                          DateFormat('yyyy-MM-dd').format(DateTime.now());
                      
                      return Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: isToday ? BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: secondaryColor.withOpacity(0.1),
                        ) : null,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), // Reduced padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? secondaryColor : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 6), // Reduced spacing
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday ? secondaryColor.withOpacity(0.2) : Colors.grey[100],
                              ),
                              child: Text(
                                _getMoodEmoji(data['mood']),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible( // Added Flexible to handle overflow
                              child: Text(
                                _getMoodLabel(data['mood']),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? secondaryColor : Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
  
  double _getMaxValue(String dataKey) {
    if (_weeklyData.isEmpty) return 10;
    double maxValue = 0;
    for (var data in _weeklyData) {
      double value = data[dataKey].toDouble();
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue == 0 ? 10 : maxValue;
  }
}