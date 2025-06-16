import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class SyllabusApp extends StatelessWidget {
  const SyllabusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Resources',
      theme: ThemeData(
        primaryColor: const Color(0xFF3F51B5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F51B5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        fontFamily: 'Poppins',
      ),
      home: const SemesterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Semester selection screen
class SemesterScreen extends StatelessWidget {
  const SemesterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Resources',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BranchScreen(
                      semester: 'S${index + 1}',
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Semester ${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Branch selection screen
class BranchScreen extends StatelessWidget {
  final String semester;

  const BranchScreen({
    Key? key,
    required this.semester,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define branches with their icons and colors
    final branches = [
      {
        'name': 'Mechanical',
        'icon': Icons.precision_manufacturing,
        'color': Colors.indigo
      },
      {'name': 'Civil', 'icon': Icons.domain, 'color': Colors.teal},
      {
        'name': 'IT',
        'icon': Icons.devices,
        'color': Colors.deepPurple
      },
      {'name': 'CSE', 'icon': Icons.computer, 'color': Colors.blue},
      {'name': 'Electronics', 'icon': Icons.memory, 'color': Colors.amber},
      {'name': 'Electrical', 'icon': Icons.electric_bolt, 'color': Colors.red},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$semester | Select Branch',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: branches.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContentOptionsScreen(
                        semester: semester,
                        branch: branches[index]['name'] as String,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              branches[index]['color'] as Color,
                              (branches[index]['color'] as Color).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          branches[index]['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          branches[index]['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Content options screen (Syllabus, Question Papers, Important Topics)
class ContentOptionsScreen extends StatelessWidget {
  final String semester;
  final String branch;

  const ContentOptionsScreen({
    Key? key,
    required this.semester,
    required this.branch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define options with their icons and titles
    final options = [
      {
        'title': 'Syllabus',
        'icon': Icons.menu_book,
        'color': Colors.blue,
        'description': 'View course syllabus',
      },
      {
        'title': 'Previous Question Papers',
        'icon': Icons.quiz,
        'color': Colors.orange,
        'description': 'View previous exam papers',
      },
      {
        'title': 'Important Topics',
        'icon': Icons.star,
        'color': Colors.green,
        'description': 'Focus on key exam topics',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$semester | $branch',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  switch (index) {
                    case 0: // Syllabus
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SyllabusContentScreen(
                            semester: semester,
                            branch: branch,
                            contentType: 'syllabus',
                          ),
                        ),
                      );
                      break;
                    case 1: // Question Papers
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SyllabusContentScreen(
                            semester: semester,
                            branch: branch,
                            contentType: 'questionpaper',
                          ),
                        ),
                      );
                      break;
                    case 2: // Important Topics
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SyllabusContentScreen(
                            semester: semester,
                            branch: branch,
                            contentType: 'importanttopics',
                          ),
                        ),
                      );
                      break;
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              options[index]['color'] as Color,
                              (options[index]['color'] as Color).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (options[index]['color'] as Color).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          options[index]['icon'] as IconData,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              options[index]['title'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              options[index]['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Modified Syllabus content screen with improved UI
class SyllabusContentScreen extends StatelessWidget {
  final String semester;
  final String branch;
  final String contentType; // 'syllabus', 'questionpaper', or 'importanttopics'

  const SyllabusContentScreen({
    Key? key,
    required this.semester,
    required this.branch,
    required this.contentType,
  }) : super(key: key);

  String getTitle() {
    switch (contentType) {
      case 'questionpaper':
        return 'Previous Papers';
      case 'importanttopics':
        return 'Important Topics';
      case 'syllabus':
      default:
        return 'Syllabus';
    }
  }

  IconData getIcon() {
    switch (contentType) {
      case 'questionpaper':
        return Icons.quiz;
      case 'importanttopics':
        return Icons.star;
      case 'syllabus':
      default:
        return Icons.menu_book;
    }
  }

  Color getColor() {
    switch (contentType) {
      case 'questionpaper':
        return Colors.orange;
      case 'importanttopics':
        return Colors.green;
      case 'syllabus':
      default:
        return Colors.blue;
    }
  }

  String getUrlField() {
    switch (contentType) {
      case 'questionpaper':
        return 'qurl';
      case 'importanttopics':
        return 'iurl';
      case 'syllabus':
      default:
        return 'fileurl';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract the semester number from the semester string (e.g., "S6" -> 6)
    final semesterNumber = int.tryParse(semester.substring(1)) ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTitle(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('syllabus')
              .where('semester', isEqualTo: semesterNumber)
              .where('branch', isEqualTo: branch)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final documents = snapshot.data?.docs ?? [];

            if (documents.isEmpty) {
              return _buildEmptyState(context);
            }

            // Filter documents that have the required URL field
            final filteredDocs = documents.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey(getUrlField()) && data[getUrlField()] != null;
            }).toList();

            if (filteredDocs.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _downloadAndOpenPdf(context, data),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  getColor(),
                                  getColor().withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              getIcon(),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              data['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.download,
                            color: getColor().withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No content available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We couldn\'t find any ${contentType} for $semester $branch',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _downloadAndOpenPdf(BuildContext context, Map<String, dynamic> data) async {
    try {
      final fileUrl = data[getUrlField()] as String;
      final fileName = data['title'] as String;
      
      // Show modern loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: getColor(),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Downloading PDF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we prepare your document',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Download the PDF file
      final response = await http.get(Uri.parse(fileUrl));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName-${contentType}.pdf');
      await file.writeAsBytes(bytes);

      // Close the dialog
      Navigator.pop(context);

      // Open PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScreen(path: file.path, title: fileName),
        ),
      );
    } catch (e) {
      // Close dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('Error opening PDF: $e')),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

// Enhanced PDF viewer screen
class PDFScreen extends StatelessWidget {
  final String path;
  final String title;

  const PDFScreen({Key? key, required this.path, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Add share functionality
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        onError: (error) {
          print(error.toString());
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
      ),
    );
  }
}