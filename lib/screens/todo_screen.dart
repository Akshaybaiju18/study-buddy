import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _dueDate;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _todoCollection = FirebaseFirestore.instance.collection('todo');

  // Define the color palette
  final Color primaryColor = const Color(0xFF3A4276);
  final Color secondaryColor = const Color(0xFF5C6BC0);
  final Color accentColor = const Color(0xFFFF9800);
  final Color textDarkColor = const Color(0xFF2E3440);
  final Color textLightColor = const Color(0xFF78849E);
  final Color bgColor = const Color(0xFFF9FAFC);
  final Color cardColor = Colors.white;

  void _addTodo() async {
    if (_titleController.text.isNotEmpty && _dueDate != null) {
      await _todoCollection.add({
        'title': _titleController.text,
        'isDone': false,
        'dueDate': _dueDate,
        'userId': _auth.currentUser?.uid,
      });
      _titleController.clear();
      _dueDate = null;
      setState(() {});
    }
  }

  void _toggleDone(String id, bool currentStatus) async {
    await _todoCollection.doc(id).update({'isDone': !currentStatus});
  }

  void _deleteTodo(String id) async {
    await _todoCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'My Todo List',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Task input field
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter a task',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: secondaryColor.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.task, color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date and Add Task row
                Row(
                  children: [
                    // Date picker button
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: secondaryColor.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    onSurface: textDarkColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _dueDate = pickedDate;
                            });
                          }
                        },
                        label: Text(
                          _dueDate == null
                              ? 'Due Date'
                              : DateFormat('MMM dd').format(_dueDate!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Add task button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addTodo,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Tasks heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDarkColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks list
          Expanded(
            child: StreamBuilder(
              stream: _todoCollection
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: secondaryColor),
                  );
                }
                
                final todos = snapshot.data!.docs;
                
                if (todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: textLightColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            color: textLightColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      final isDone = todo['isDone'] as bool;
                      final title = todo['title'] as String;
                      final dueDate = (todo['dueDate'] as Timestamp).toDate();
                      
                      // Check if task is overdue
                      final isOverdue = !isDone && dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? textLightColor : textDarkColor,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('EEEE, MMM d').format(dueDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: isOverdue ? Colors.red : textLightColor,
                              ),
                            ),
                          ),
                          leading: Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              value: isDone,
                              onChanged: (_) => _toggleDone(todo.id, isDone),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: secondaryColor,
                              checkColor: Colors.white,
                              side: BorderSide(color: textLightColor, width: 1.5),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: textLightColor,
                            ),
                            onPressed: () => _deleteTodo(todo.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}