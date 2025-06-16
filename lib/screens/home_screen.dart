import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:study_buddy/screens/group_chat_screen.dart';
import 'package:study_buddy/screens/todo_screen.dart';
import 'dart:convert';
import 'bedtime_tracker.dart';
import 'package:study_buddy/screens/personal_calendar.dart';
import 'package:study_buddy/screens/thoughts_journal.dart';
import 'focus_timer.dart';
import 'notes.dart';
import 'progress.dart';
import 'syllabus.dart';
import 'health.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  
  // User data
  String userName = "";
  final int upcomingTasks = 5;
  // Removed the fixed currentMood display
  final double sleepHours = 7.5;
  final double studyMinutes = 120;
  
  // Minimalist color palette
  final Color primaryColor = const Color(0xFF3A4276);
  final Color secondaryColor = const Color(0xFF5C6BC0);
  final Color accentColor = const Color(0xFFFF9800);
  final Color textDarkColor = const Color(0xFF2E3440);
  final Color textLightColor = const Color(0xFF78849E);
  final Color bgColor = const Color(0xFFF9FAFC);
  final Color cardColor = Colors.white;
  
  // Quotes
  String currentQuote = "Loading quote...";
  String currentAuthor = "";
  bool isLoadingQuote = true;
  
  // Fallback quotes in case API fails
  final List<Map<String, String>> fallbackQuotes = [
    {
      "quote": "Success is not final, failure is not fatal: It is the courage to continue that counts.",
      "author": "Winston Churchill"
    },
    {
      "quote": "The secret of getting ahead is getting started.",
      "author": "Mark Twain"
    },
    {
      "quote": "It always seems impossible until it's done.",
      "author": "Nelson Mandela"
    },
    {
      "quote": "Don't watch the clock; do what it does. Keep going.",
      "author": "Sam Levenson"
    },
    {
      "quote": "Productivity is never an accident. It is always the result of a commitment to excellence, intelligent planning, and focused effort.",
      "author": "Paul J. Meyer"
    }
  ];
  
  // Features data for minimalist grid
  final List<Map<String, dynamic>> features = [
    {
      "title": "Bedtime",
      "icon": Icons.nightlight_round,
      "color": Color(0xFF5E81AC),
      "route": "bedtime"
    },
    {
      "title": "Health",
      "icon": Icons.favorite,
      "color": Color(0xFFBF616A),
      "route": "health"
    },
    {
      "title": "Syllabus",
      "icon": Icons.book,
      "color": Color(0xFF81A1C1),
      "route": "syllabus"
    },
    {
      "title": "Focus Timer",
      "icon": Icons.timer,
      "color": Color(0xFFEBCB8B),
      "route": "focus_timer"
    },

    {
      "title": "Journal",
      "icon": Icons.edit_note,
      "color": Color(0xFFB48EAD),
      "route": "journal"
    },
    {
      "title": "Calendar",
      "icon": Icons.calendar_today,
      "color": Color(0xFF88C0D0),
      "route": "calendar"
    },
    {
      "title": "To-Do",
      "icon": Icons.check_box,
      "color": Color(0xFFA3BE8C),
      "route": "todo"
    },
    {
      "title": "Notes",
      "icon": Icons.sticky_note_2,
      "color": Color(0xFF8FBCBB),
      "route": "notes"
    },
    {
      "title": "Chat",
      "icon": Icons.chat,
      "color": Color(0xFFD08770),
      "route": "chat"
    }
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _loadUserData();
    _fetchRandomQuoteFromInternet();
  }
  
  // Fetch random quote from an API
  Future<void> _fetchRandomQuoteFromInternet() async {
    setState(() {
      isLoadingQuote = true;
    });
    
    try {
      // Using the Quotable API as an example
      final response = await http.get(Uri.parse('https://api.quotable.io/random'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentQuote = data['content'];
          currentAuthor = data['author'];
          isLoadingQuote = false;
        });
      } else {
        // If API fails, use fallback quotes
        _setFallbackQuote();
      }
    } catch (e) {
      // If there's a network error, use fallback quotes
      _setFallbackQuote();
    }
  }
  
  void _setFallbackQuote() {
    final random = Random();
    final randomIndex = random.nextInt(fallbackQuotes.length);
    
    setState(() {
      currentQuote = fallbackQuotes[randomIndex]["quote"]!;
      currentAuthor = fallbackQuotes[randomIndex]["author"]!;
      isLoadingQuote = false;
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        userName = currentUser.displayName ?? 
                  (currentUser.email?.split('@').first ?? "Buddy");
      });
    }
  }
  
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: bgColor,
              elevation: 0,
              leadingWidth: 0,
              leading: const SizedBox(),
              title: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: secondaryColor.withOpacity(0.1),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "B",
                        style: GoogleFonts.poppins(
                          color: primaryColor,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${userName.isNotEmpty ? userName : 'there'}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textDarkColor,
                            ),
                          ),
                          // Removed the currentMood display
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black54),
                  onPressed: () => signOut(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // Reduced bottom padding to fix overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuoteCard(),
                    const SizedBox(height: 28),
                    //_buildStatsSection(),
                    const SizedBox(height: 28),
                    _buildFeaturesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildQuoteCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S FOCUS",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              InkWell(
                onTap: _fetchRandomQuoteFromInternet, // Changed to fetch a new quote from the internet
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: isLoadingQuote
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isLoadingQuote
              ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                )
              : Text(
                  "\"$currentQuote\"",
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
          const SizedBox(height: 12),
          if (!isLoadingQuote)
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "- $currentAuthor",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 600));
  }
  
  /*Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Daily Stats",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textDarkColor,
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .slideX(begin: -0.05, end: 0),
          
        const SizedBox(height: 12),
          
        // Stats cards in horizontal scrollable row
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  physics: const BouncingScrollPhysics(),
  child: Row(
    children: [
      _buildStatCard(
        icon: Icons.event_note,
        value: upcomingTasks.toString(),
        label: "Tasks",
        color: secondaryColor,
        index: 0,
      ),
      _buildStatCard(
        icon: Icons.nightlight_round,
        value: "$sleepHours hrs",
        label: "Sleep",
        color: const Color(0xFF5E81AC),
        index: 1,
      ),
      _buildStatCard(
        icon: Icons.timer,
        value: "${studyMinutes.toInt()} min",
        label: "Focus",
        color: const Color(0xFF8FBCBB),
        index: 2,
      ),
    ],
  ),
),

      ],
    );
  }*/
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int index,
  }) {
    return Container(
      width: 130,
      margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Viewing details for $label'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: color.withOpacity(0.9),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textDarkColor,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: textLightColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(
        duration: const Duration(milliseconds: 500),
        delay: Duration(milliseconds: 300 + (index * 100)),
      )
      .slideX(
        begin: 0.1,
        end: 0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuad,
        delay: Duration(milliseconds: 300 + (index * 100)),
      );
  }
  
  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Features",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDarkColor,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Customize",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .slideY(begin: 0.05, end: 0),
          
        const SizedBox(height: 16),
        
        // Features grid with minimalist design
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _buildFeatureCard(
              icon: features[index]["icon"],
              title: features[index]["title"],
              color: features[index]["color"],
              index: index,
              route: features[index]["route"],
            );
          },
        ),
      ],
    );
  }
  
Widget _buildFeatureCard({  
  required IconData icon,  
  required String title,  
  required Color color,  
  required int index,  
  required String route,  
}) {    
  return GestureDetector(  
    onTap: () {  
      // Navigation logic  
      if (route == "bedtime") {  
        Navigator.push(  
          context,  
          PageRouteBuilder(  
            pageBuilder: (context, animation, secondaryAnimation) => BedtimeTrackerPage(),  
            transitionsBuilder: (context, animation, secondaryAnimation, child) {  
              const begin = Offset(1.0, 0.0);  
              const end = Offset.zero;  
              const curve = Curves.easeInOutCubic;  

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));  
              return SlideTransition(position: animation.drive(tween), child: child);  
            },  
          ),  
        );  
      }  
      else if (route == "chat") {  
        Navigator.push(  
          context,  
          PageRouteBuilder(  
            pageBuilder: (context, animation, secondaryAnimation) => GroupChatScreen(),  
            transitionsBuilder: (context, animation, secondaryAnimation, child) {  
              const begin = Offset(1.0, 0.0);  
              const end = Offset.zero;  
              const curve = Curves.easeInOutCubic;  

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));  
              return SlideTransition(position: animation.drive(tween), child: child);  
            },  
          ),  
        );  
      }  
      else if (route == "todo") {  
        Navigator.push(  
          context,  
          PageRouteBuilder(  
            pageBuilder: (context, animation, secondaryAnimation) => TodoScreen(), // Pass the user ID if needed  
            transitionsBuilder: (context, animation, secondaryAnimation, child) {  
              const begin = Offset(1.0, 0.0);  
              const end = Offset.zero;  
              const curve = Curves.easeInOutCubic;  

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));  
              return SlideTransition(position: animation.drive(tween), child: child);  
            },  
          ),  
        );  
      }

      else if (route == "calendar") {  
      Navigator.push(  
      context,  
      MaterialPageRoute(builder: (context) => PersonalCalendar()),  
      );  
      }

      else if (route == "journal") {
      Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThoughtsJournal()),
       );
      }

      else if (route == "focus_timer") {
  String? userId = FirebaseAuth.instance.currentUser?.uid; // Get user ID

  if (userId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FocusTimer(userId: userId)),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("User not logged in!"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


      else if (route == "notes") {  
  Navigator.push(  
    context,  
    MaterialPageRoute(builder: (context) => NotesPage()),  
  );  
    }

    else if (route == "syllabus") {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SyllabusApp()),
  );
}

  else if (route == "health") {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HealthPage()),
  );
}




  
      else {  
        ScaffoldMessenger.of(context).showSnackBar(  
          SnackBar(  
            content: Text('Opening $title'),  
            duration: const Duration(seconds: 1),  
            behavior: SnackBarBehavior.floating,  
            backgroundColor: color.withOpacity(0.9),  
            shape: RoundedRectangleBorder(  
              borderRadius: BorderRadius.circular(10),  
            ),  
          ),  
        );  
      }  
    },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textDarkColor,
                ),
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 500 + (index * 50)),
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
          delay: Duration(milliseconds: 500 + (index * 50)),
        ),
    );
  }
  
  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          //_buildNavItem(1, Icons.calendar_today_rounded, 'Planner'),
          _buildNavItem(2, Icons.analytics_rounded, 'Progress'),
          //_buildNavItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }
  
Widget _buildNavItem(int index, IconData icon, String label) {
  bool isSelected = _selectedIndex == index;

  return InkWell(
    onTap: () {
      setState(() {
        _selectedIndex = index;
      });

      if (index == 2) { // When "Progress" is clicked
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProgressTracker(userId: userId)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User not logged in!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
    child: SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: isSelected ? 20 : 0,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

}