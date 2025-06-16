import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Define your color palette
final Color primaryColor = const Color(0xFF3A4276);
final Color secondaryColor = const Color(0xFF5C6BC0);
final Color accentColor = const Color(0xFFFF9800);
final Color textDarkColor = const Color(0xFF2E3440);
final Color textLightColor = const Color(0xFF78849E);
final Color bgColor = const Color(0xFFF9FAFC);
final Color cardColor = Colors.white;

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final List<String> _filterOptions = ['All Notes', 'PDF', 'PPT'];
  String _currentFilter = 'All Notes';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get notes from Firestore
  Stream<QuerySnapshot> _getNotesStream() {
    if (_currentFilter == 'All Notes') {
      return _firestore
          .collection('notes')
          .orderBy('uploadDate', descending: true)
          .snapshots();
    } else {
      String fileType = _currentFilter.toLowerCase();
      if (fileType == 'ppt') {
        // Handle both ppt and pptx
        return _firestore
            .collection('notes')
            .where('fileType', whereIn: ['ppt', 'pptx'])
            .orderBy('uploadDate', descending: true)
            .snapshots();
      } else {
        return _firestore
            .collection('notes')
            .where('fileType', isEqualTo: fileType)
            .orderBy('uploadDate', descending: true)
            .snapshots();
      }
    }
  }

  // Get user's notes from Firestore
  Stream<QuerySnapshot> _getUserNotesStream() {
    if (currentUser == null) {
      return Stream.empty();
    }
    
    if (_currentFilter == 'All Notes') {
      return _firestore
          .collection('notes')
          .where('uploadedBy', isEqualTo: currentUser!.uid)
          .orderBy('uploadDate', descending: true)
          .snapshots();
    } else {
      String fileType = _currentFilter.toLowerCase();
      if (fileType == 'ppt') {
        // Handle both ppt and pptx
        return _firestore
            .collection('notes')
            .where('uploadedBy', isEqualTo: currentUser!.uid)
            .where('fileType', whereIn: ['ppt', 'pptx'])
            .orderBy('uploadDate', descending: true)
            .snapshots();
      } else {
        return _firestore
            .collection('notes')
            .where('uploadedBy', isEqualTo: currentUser!.uid)
            .where('fileType', isEqualTo: fileType)
            .orderBy('uploadDate', descending: true)
            .snapshots();
      }
    }
  }

  // Filter notes based on search query
  List<QueryDocumentSnapshot> _filterNotes(List<QueryDocumentSnapshot> notes) {
    if (_searchQuery.isEmpty) {
      return notes;
    }
    
    final query = _searchQuery.toLowerCase();
    return notes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title'].toString().toLowerCase();
      final description = data['description'].toString().toLowerCase();
      final tags = (data['tags'] as List<dynamic>).map((tag) => tag.toString().toLowerCase());
      
      return title.contains(query) || 
             description.contains(query) || 
             tags.any((tag) => tag.contains(query));
    }).toList();
  }

  // Upload file to Firebase
  Future<void> _uploadNote({
    required File file,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final String fileName = path.basename(file.path);
      final String extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      
      // Check if file type is supported
      if (extension != 'pdf' && extension != 'ppt' && extension != 'pptx') {
        throw Exception('Only PDF and PPT files are supported');
      }

      // Upload file to Firebase Storage
      final Reference storageRef = _storage.ref()
          .child('notes')
          .child(currentUser!.uid)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(file);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create note in Firestore
      await _firestore.collection('notes').add({
        'title': title,
        'description': description,
        'uploadedBy': currentUser!.uid,
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'fileType': extension,
        'fileSize': await file.length(),
        'uploadDate': FieldValue.serverTimestamp(),
        'tags': tags,
        'downloads': 0,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note uploaded successfully!'),
          backgroundColor: secondaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading note: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _viewNote(Map<String, dynamic> note) async {
    try {
      final url = note['fileUrl'];
      final fileType = note['fileType'];

      // Update download count
      _firestore.collection('notes').doc(note['id']).update({
        'downloads': FieldValue.increment(1),
      });

      if (fileType == 'pdf') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                  ),
                  SizedBox(height: 16),
                  Text('Downloading file...', style: TextStyle(color: textDarkColor)),
                ],
              ),
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          },
        );

        final response = await http.get(Uri.parse(url));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${note['fileName']}');
        await file.writeAsBytes(bytes);

        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFScreen(path: file.path, title: note['title']),
          ),
        );
      } else {
        final Uri uri = Uri.parse(Uri.encodeFull(url));

        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          final response = await http.get(uri);
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${note['fileName']}');
          await file.writeAsBytes(bytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File downloaded to: ${file.path}'),
              backgroundColor: secondaryColor,
            ),
          );
        }
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Delete a note
  Future<void> _deleteNote(String noteId, String fileUrl) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Note', style: TextStyle(color: textDarkColor)),
          content: Text('Are you sure you want to delete this note?', style: TextStyle(color: textLightColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: textLightColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: accentColor)),
            ),
          ],
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ) ?? false;
      
      if (!confirm) return;
      
      // Delete file from storage
      await _storage.refFromURL(fileUrl).delete();
      
      // Delete note from Firestore
      await _firestore.collection('notes').doc(noteId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note deleted successfully'),
          backgroundColor: secondaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting note: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      File file = File(result.files.single.path!);
      
      // Show upload dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildUploadDialog(file),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUploadDialog(File file) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController();
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Upload Note', style: TextStyle(color: textDarkColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selected file: ${file.path.split('/').last}',
                  style: TextStyle(color: textLightColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: textLightColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textDarkColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: textLightColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                  ),
                  maxLines: 3,
                  style: TextStyle(color: textDarkColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma separated)',
                    labelStyle: TextStyle(color: textLightColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textDarkColor),
                ),
                const SizedBox(height: 16),
                if (_isUploading)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: textLightColor),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: textLightColor)),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      List<String> tags = tagsController.text
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList();
                      
                      _uploadNote(
                        file: file,
                        title: titleController.text,
                        description: descriptionController.text,
                        tags: tags,
                      );
                    },
              child: Text('Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      selected: isSelected,
      label: Text(filter),
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
        });
      },
      selectedColor: secondaryColor.withOpacity(0.2),
      backgroundColor: bgColor,
      checkmarkColor: secondaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : textLightColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? secondaryColor : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, bool canDelete) {
    final fileType = note['fileType'];
    IconData iconData;
    Color iconColor;
    
    if (fileType == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else {
      iconData = Icons.slideshow;
      iconColor = accentColor;
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: iconColor, size: 32),
        ),
        title: Text(
          note['title'],
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note['description'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textLightColor),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(note['uploadDate'].toDate()),
              style: TextStyle(fontSize: 12, color: textLightColor),
            ),
            if (note['tags'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: (note['tags'] as List<dynamic>).map((tag) => Chip(
                    label: Text(
                      tag,
                      style: TextStyle(fontSize: 10, color: primaryColor),
                    ),
                    backgroundColor: secondaryColor.withOpacity(0.1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade300),
                onPressed: () => _deleteNote(note['id'], note['fileUrl']),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 16, color: secondaryColor),
                  Text(
                    '${note['downloads']}',
                    style: TextStyle(fontSize: 12, color: textLightColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _viewNote(note),
      ),
    );
  }

  Widget _buildNotesList(Stream<QuerySnapshot> stream, bool canDelete) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textLightColor)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final filteredDocs = _filterNotes(docs);
        
        if (filteredDocs.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: textLightColor),
                  const SizedBox(height: 16),
                  Text(
                    'No results found for "$_searchQuery"',
                    style: TextStyle(fontSize: 16, color: textLightColor),
                  ),
                ],
              ),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notes_outlined, size: 64, color: textLightColor),
                const SizedBox(height: 16),
                Text(
                  canDelete 
                      ? 'You haven\'t uploaded any notes yet'
                      : 'No notes available',
                  style: TextStyle(fontSize: 16, color: textLightColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Add document ID to data
            return _buildNoteCard(data, canDelete);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notes', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Notes'),
            Tab(text: 'My Uploads'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: accentColor,
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(color: textLightColor),
                prefixIcon: Icon(Icons.search, color: secondaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textLightColor),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: secondaryColor, width: 1),
                ),
              ),
              style: TextStyle(color: textDarkColor),
            ),
          ),
          
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: _filterOptions.map(_buildFilterChip).toList(),
            ),
          ),
          
          // Notes list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Notes tab
                _buildNotesList(_getNotesStream(), false),
                
                // My Uploads tab
                _buildNotesList(_getUserNotesStream(), true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        tooltip: 'Upload Note',
        child: const Icon(Icons.upload_file, color: Colors.white),
        backgroundColor: accentColor,
        elevation: 4,
      ),
    );
  }
}

class PDFScreen extends StatelessWidget {
  final String path;
  final String title;

  const PDFScreen({Key? key, required this.path, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
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