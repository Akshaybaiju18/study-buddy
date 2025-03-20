import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedBranch = "CS"; // Default branch
  int selectedSemester = 1; // Default semester

  // Get Current User's Name from Firestore
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      print("Error fetching user name: $e");
      return 'Unknown';
    }
  }

  // Send Message
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = await getUserName(user.uid);

    try {
      await _firestore
          .collection('group_chats')
          .doc("${selectedBranch}_sem$selectedSemester")
          .collection("messages")
          .add({
        'senderId': user.uid,
        'senderName': userName,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "$selectedBranch - Semester $selectedSemester",
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${selectedBranch == 'CS' ? 'Computer Science' : 
                selectedBranch == 'EC' ? 'Electronics & Communication' :
                selectedBranch == 'EEE' ? 'Electrical Engineering' : 'Mechanical Engineering'} Group",
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text("Change Group"),
                onTap: () => _showGroupSelectionDialog(),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Branch & Semester Selection Card
          Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBranch,
                      icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                      items: ["CS", "EC", "EEE", "ME"].map((branch) {
                        return DropdownMenuItem(
                          value: branch, 
                          child: Text(
                            branch,
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBranch = value!;
                        });
                      },
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedSemester,
                      icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                      items: List.generate(8, (index) => index + 1).map((sem) {
                        return DropdownMenuItem(
                          value: sem, 
                          child: Text(
                            "Semester $sem",
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSemester = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages Display
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: StreamBuilder(
                stream: _firestore
                    .collection('group_chats')
                    .doc("${selectedBranch}_sem$selectedSemester")
                    .collection("messages")
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_outlined,
                              color: Color(0xFF3B82F6),
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No messages yet",
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Be the first to send a message!",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var msg = snapshot.data!.docs[index];
                      bool isMe = msg['senderId'] == _auth.currentUser?.uid;
                      
                      // Format timestamp
                      String timeText = "";
                      if (msg['timestamp'] != null) {
                        DateTime time = (msg['timestamp'] as Timestamp).toDate();
                        timeText = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFFEFF6FF),
                                child: Text(
                                  msg['senderName'].substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe 
                                    ? CrossAxisAlignment.end 
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                                      child: Text(
                                        msg['senderName'],
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe ? Color(0xFF3B82F6) : Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(isMe ? 16 : 4),
                                        topRight: Radius.circular(isMe ? 4 : 16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          msg['message'],
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Color(0xFF1F2937),
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (timeText.isNotEmpty) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            timeText,
                                            style: TextStyle(
                                              color: isMe ? Colors.white.withOpacity(0.7) : Color(0xFF9CA3AF),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Message Input Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Material(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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

  // Group Selection Dialog
  void _showGroupSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              "Select Group",
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Branch",
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["CS", "EC", "EEE", "ME"].map((branch) {
                      bool isSelected = branch == selectedBranch;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedBranch = branch;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF3B82F6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            branch,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Semester",
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GridView.count(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    padding: EdgeInsets.all(8),
                    children: List.generate(8, (index) {
                      int sem = index + 1;
                      bool isSelected = sem == selectedSemester;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedSemester = sem;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF3B82F6) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              "$sem",
                              style: TextStyle(
                                color: isSelected ? Colors.white : Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Update the main screen state with selected values
                    // selectedBranch and selectedSemester are already updated inside the dialog
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Apply"),
              ),
            ],
          );
        },
      ),
    );
  }
}