import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
//import 'package:intl/intl.dart';

class ProgressTracker extends StatefulWidget {
  final String userId;
  
  const ProgressTracker({super.key, required this.userId});

  @override
  _ProgressTrackerState createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Sample data to use when Firebase data isn't available
  final List<Map<String, dynamic>> _sampleData = [
    {'date': '2025-03-28', 'totalMinutes': 50},
    {'date': '2025-03-29', 'totalMinutes': 100},
    {'date': '2025-03-30', 'totalMinutes': 100},
    {'date': '2025-03-31', 'totalMinutes': 125},
    {'date': '2025-04-01', 'totalMinutes': 75},
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchStudyData() async {
    try {
      // Fetch study sessions for the specific user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('study_sessions')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();

      // Convert documents to list of maps
      List<Map<String, dynamic>> sessions = snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id
              })
          .toList();

      // Print detailed debugging information
      print("Fetched study sessions for user ${widget.userId}:");
      print("Total sessions: ${sessions.length}");
      sessions.forEach((session) {
        print("Session details: $session");
      });
      
      // If no data is available, use sample data
      if (sessions.isEmpty) {
        return _sampleData;
      }

      return sessions;
    } catch (e) {
      print("Error fetching study data for user ${widget.userId}: $e");
      // Return sample data if there's an error
      return _sampleData;
    }
  }

  // Calculate tree growth level based on total study minutes
  int _calculateTreeLevel(List<Map<String, dynamic>> sessions) {
    int totalMinutes = 0;
    for (var session in sessions) {
      totalMinutes += (session['totalMinutes'] as num).toInt();
    }
    
    // Tree grows in stages based on total study time
    if (totalMinutes < 60) return 1; // Seedling
    if (totalMinutes < 180) return 2; // Small tree
    if (totalMinutes < 300) return 3; // Medium tree
    if (totalMinutes < 500) return 4; // Large tree
    return 5; // Fully grown tree with fruits
  }

  // Build the growing tree widget
  Widget _buildTree(int level, double animationValue) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Ground/soil
          Container(
            height: 40,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF8B4513),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ),
          
          // Tree trunk
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 30 + (level * 30 * animationValue),
            width: 20,
            margin: const EdgeInsets.only(bottom: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          // Tree leaves/crown - grows with level
          if (level >= 1)
            Positioned(
              bottom: 70 + (level * 25 * animationValue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 40 * animationValue,
                width: 40 * animationValue,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
          if (level >= 2)
            Positioned(
              bottom: 90 + (level * 20 * animationValue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 60 * animationValue,
                width: 60 * animationValue,
                decoration: const BoxDecoration(
                  color: Color(0xFF388E3C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
          if (level >= 3)
            Positioned(
              bottom: 110 + (level * 15 * animationValue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 80 * animationValue,
                width: 80 * animationValue,
                decoration: const BoxDecoration(
                  color: Color(0xFF43A047),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
          if (level >= 4)
            Positioned(
              bottom: 130 + (level * 10 * animationValue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 100 * animationValue,
                width: 100 * animationValue,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          
          // Fruits appear at max level
          if (level >= 5)
            ...List.generate(6, (index) {
              final angle = index * (3.14 / 3); // Distribute fruits in a circle
              final xOffset = cos(angle) * 40;
              final yOffset = sin(angle) * 40;
              
              return Positioned(
                bottom: 160 + yOffset,
                left: MediaQuery.of(context).size.width / 2 - 5 + xOffset,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 15 * animationValue,
                  width: 15 * animationValue,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            
          // Tree growth level indicator
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Level $level",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          
          // Growth tip
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                level < 5 
                ? "Study ${(5 - level) * 60} more minutes to reach next level!"
                : "Congratulations! Your tree is fully grown!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: level < 5 ? Colors.orange : Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Growth Tracker"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStudyData(),
        builder: (context, snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ));
          }

          // Use sample data if no data is available
          final List<Map<String, dynamic>> sessions = 
              snapshot.hasData && snapshot.data!.isNotEmpty 
              ? snapshot.data!
              : _sampleData;
          
          // Calculate tree growth level
          final treeLevel = _calculateTreeLevel(sessions);
          
          // Restart animation when data is loaded
          if (_animationController.status == AnimationStatus.completed) {
            _animationController.reset();
            _animationController.forward();
          }
          
          // Prepare data for chart
          List<FlSpot> studyData = sessions
              .asMap()
              .entries
              .map((entry) => FlSpot(
                    entry.key.toDouble(), 
                    (entry.value['totalMinutes'] as num).toDouble(),
                  ))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Study Growth",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total Sessions: ${sessions.length}",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          "Total Minutes: ${sessions.fold(0, (sum, session) => sum + (session['totalMinutes'] as num).toInt())}",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Virtual growing tree
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Knowledge Tree",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return _buildTree(treeLevel, _animation.value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Chart
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Study Time Trend",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}m');
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < sessions.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            sessions[index]['date'].toString().substring(5),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: studyData,
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                              ],
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Detailed session list
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recent Study Sessions",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sessions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            var session = sessions[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text(
                                  "${session['totalMinutes']}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                "Date: ${session['date']}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                session.containsKey('subject') 
                                    ? "Subject: ${session['subject']}" 
                                    : "Study Session",
                              ),
                              trailing: Text(
                                "${session['totalMinutes']} minutes",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}