import 'dart:async';
import 'package:flutter/material.dart';

// Define the color palette
final Color primaryColor = const Color(0xFF3A4276);
final Color secondaryColor = const Color(0xFF5C6BC0);
final Color accentColor = const Color(0xFFFF9800);
final Color textDarkColor = const Color(0xFF2E3440);
final Color textLightColor = const Color(0xFF78849E);
final Color bgColor = const Color(0xFFF9FAFC);
final Color cardColor = Colors.white;

class FocusTimer extends StatefulWidget {
  const FocusTimer({super.key});

  @override
  _FocusTimerState createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> with SingleTickerProviderStateMixin {
  static const int _initialMinutes = 25;
  static const int _shortBreakMinutes = 5;
  static const int _longBreakMinutes = 15;
  
  int _remainingTime = _initialMinutes * 60;
  bool _isRunning = false;
  Timer? _timer;
  int _completedSessions = 0;
  String _currentMode = "Focus";
  
  // Animation controller for progress indicator
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _initialMinutes * 60),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  void _startTimer() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        _animationController.value = 1 - (_remainingTime / (_getSessionDuration() * 60));
      } else {
        _completeSession();
      }
    });
  }
  
  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }
  
  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingTime = _getSessionDuration() * 60;
    });
    _animationController.reset();
  }
  
  void _completeSession() {
    _stopTimer();
    _animationController.reset();
    
    if (_currentMode == "Focus") {
      _completedSessions++;
      
      if (_completedSessions % 4 == 0) {
        _switchMode("Long Break");
      } else {
        _switchMode("Short Break");
      }
    } else {
      _switchMode("Focus");
    }
    
    // Play a sound or vibrate here
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentMode == "Focus" 
          ? "Time for a break!" 
          : "Break finished! Time to focus again!"),
        backgroundColor: _currentMode == "Focus" ? secondaryColor : accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _switchMode(String mode) {
    setState(() {
      _currentMode = mode;
      _remainingTime = _getSessionDuration() * 60;
    });
    _animationController.duration = Duration(seconds: _getSessionDuration() * 60);
  }
  
  int _getSessionDuration() {
    switch (_currentMode) {
      case "Short Break":
        return _shortBreakMinutes;
      case "Long Break":
        return _longBreakMinutes;
      default:
        return _initialMinutes;
    }
  }
  
  String get _formattedTime {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  Color _getModeColor() {
    switch (_currentMode) {
      case "Short Break":
        return secondaryColor;
      case "Long Break":
        return accentColor;
      default:
        return primaryColor;
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textDarkColor),
            onPressed: () {
              // Add settings functionality
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Session counter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _completedSessions % 4 
                              ? _getModeColor() 
                              : textLightColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  SizedBox(width: 16),
                  Text(
                    "Session: ${(_completedSessions ~/ 4) + 1}",
                    style: TextStyle(
                      color: textLightColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Timer display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mode indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    SizedBox(height: 20),
                    
                    // Timer circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _animation.value,
                                strokeWidth: 8,
                                backgroundColor: textLightColor.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(_getModeColor()),
                              );
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formattedTime,
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: textDarkColor,
                              ),
                            ),
                            Text(
                              _isRunning ? "Time remaining" : "Ready to start",
                              style: TextStyle(
                                color: textLightColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Control buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.refresh,
                        label: "Reset",
                        onPressed: _resetTimer,
                        backgroundColor: Colors.transparent,
                        foregroundColor: textLightColor,
                      ),
                      _buildControlButton(
                        icon: _isRunning ? Icons.pause : Icons.play_arrow,
                        label: _isRunning ? "Pause" : "Start",
                        onPressed: _isRunning ? _stopTimer : _startTimer,
                        backgroundColor: _getModeColor(),
                        foregroundColor: Colors.white,
                        isMain: true,
                      ),
                      _buildControlButton(
                        icon: Icons.skip_next,
                        label: "Skip",
                        onPressed: _completeSession,
                        backgroundColor: Colors.transparent,
                        foregroundColor: textLightColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isMain = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: isMain ? 4 : 0,
            shape: CircleBorder(),
            padding: EdgeInsets.all(isMain ? 24 : 12),
          ),
          child: Icon(icon, size: isMain ? 32 : 24),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: textLightColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}