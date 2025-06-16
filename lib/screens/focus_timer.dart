import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FocusTimer extends StatefulWidget {
  final String userId;
  const FocusTimer({super.key, required this.userId});

  @override
  _FocusTimerState createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> with SingleTickerProviderStateMixin {
  static const int _initialMinutes = 25;
  static const int _shortBreakMinutes = 5;
  static const int _longBreakMinutes = 15;

  // Color palette
  final Color primaryColor = const Color(0xFF3A4276);
  final Color secondaryColor = const Color(0xFF5C6BC0);
  final Color accentColor = const Color(0xFFFF9800);
  final Color textDarkColor = const Color(0xFF2E3440);
  final Color textLightColor = const Color(0xFF78849E);
  final Color bgColor = const Color(0xFFF9FAFC);
  final Color cardColor = Colors.white;

  int _remainingTime = _initialMinutes * 60;
  bool _isRunning = false;
  Timer? _timer;
  int _completedSessions = 0;
  String _currentMode = "Focus";
  DateTime? _sessionStart;
  int _totalSeconds = _initialMinutes * 60;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _getSessionDuration() * 60;
    _remainingTime = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void enableDND() async {
    const platform = MethodChannel('dnd_channel');
    try {
      await platform.invokeMethod('enableDND');
    } on PlatformException catch (e) {
      print("Failed to enable DND: '${e.message}'.");
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    
    enableDND(); // Enable DND before starting the timer
    
    // Only set the session start time if we're starting a new session
    if (_sessionStart == null) {
      _sessionStart = DateTime.now();
    }
    
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _completeSession();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingTime = _totalSeconds;
      _sessionStart = null; // Reset session start time
    });
  }

  void _completeSession() async {
    _stopTimer();
    
    // Only save to Firestore if we were in a Focus session
    if (_currentMode == "Focus" && _sessionStart != null) {
      DateTime endTime = DateTime.now();
      int sessionDuration = endTime.difference(_sessionStart!).inMinutes;
      
      if (sessionDuration > 0) {
        // Show a brief success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Focus session completed! $sessionDuration minutes saved."),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Save the completed session to Firestore
        await _saveSessionToFirestore(sessionDuration);
      }
    }

    // Update the session count and mode
    if (_currentMode == "Focus") {
      setState(() {
        _completedSessions++;
        _currentMode = (_completedSessions % 4 == 0) ? "Long Break" : "Short Break";
      });
    } else {
      setState(() {
        _currentMode = "Focus";
      });
    }

    // Reset for the next session
    setState(() {
      _totalSeconds = _getSessionDuration() * 60;
      _remainingTime = _totalSeconds;
      _sessionStart = null; // Reset session start time for the next session
    });
  }

 Future<void> _saveSessionToFirestore(int duration) async {
    try {
      if (duration <= 0 || widget.userId.isEmpty) {
        print("Invalid save attempt - Duration: $duration, UserID: ${widget.userId}");
        return;
      }
      
      // Use current date as the document key
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Create a unique document reference
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('study_sessions')
          .doc();
      
      // Prepare session data
      Map<String, dynamic> sessionData = {
        'userId': widget.userId,
        'date': dateKey,
        'totalMinutes': duration,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      // Set the document
      await docRef.set(sessionData);
      
      print("Session saved successfully to Firestore!");
      print("User ID: ${widget.userId}, Duration: $duration, Date: $dateKey");
    } catch (e) {
      print("Error saving session to Firestore: $e");
    }
  }

  int _getSessionDuration() {
    switch (_currentMode) {
      case "Short Break": return _shortBreakMinutes;
      case "Long Break": return _longBreakMinutes;
      default: return _initialMinutes;
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getModeColor() {
    switch (_currentMode) {
      case "Short Break": return secondaryColor;
      case "Long Break": return primaryColor;
      default: return accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _remainingTime / _totalSeconds;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: Text(
          "Focus Timer",
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sessions indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  bool isCompleted = index < (_completedSessions % 4);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCompleted ? secondaryColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
            
            // Main timer display
            Expanded(
              child: Center(
                child: Card(
                  elevation: 0,
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mode indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getModeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentMode,
                            style: TextStyle(
                              color: _getModeColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Custom Timer circle
                        SizedBox(
                          height: 260,
                          width: 260,
                          child: CustomPaint(
                            painter: TimerPainter(
                              progress: progress,
                              progressColor: _getModeColor(),
                              backgroundColor: Colors.grey.shade200,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(_remainingTime),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w700,
                                      color: textDarkColor,
                                    ),
                                  ),
                                  Text(
                                    "remaining",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reset button
                            if (_isRunning || _remainingTime < _totalSeconds)
                              IconButton(
                                onPressed: _resetTimer,
                                icon: Icon(
                                  Icons.refresh,
                                  color: textLightColor,
                                  size: 28,
                                ),
                              ),
                            
                            const SizedBox(width: 16),
                            
                            // Play/Pause button
                            Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                color: _isRunning ? primaryColor : accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isRunning ? _stopTimer : _startTimer,
                                icon: Icon(
                                  _isRunning ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Skip button
                            IconButton(
                              onPressed: _completeSession,
                              icon: Icon(
                                Icons.skip_next,
                                color: textLightColor,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Session info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    "Sessions completed today: $_completedSessions",
                    style: TextStyle(
                      color: textLightColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Next: ${_currentMode == "Focus" ? "Break" : "Focus"} session",
                    style: TextStyle(
                      color: textLightColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the timer circle
class TimerPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  
  TimerPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    final strokeWidth = 12.0;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
      
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final progressAngle = 2 * pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from the top
      progressAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}