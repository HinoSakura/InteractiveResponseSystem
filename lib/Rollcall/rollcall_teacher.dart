import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherRollCallScreen extends StatefulWidget {
  final String courseID;

  TeacherRollCallScreen({required this.courseID});

  @override
  _TeacherRollCallScreenState createState() => _TeacherRollCallScreenState();
}

class _TeacherRollCallScreenState extends State<TeacherRollCallScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _students = {};
  Map<String, dynamic> _rollCallData = {};
  int _sessionCount = 0;
  List<String> _courseStudentIDs = [];

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _fetchCourseStudents();
    _fetchSessionCount();
  }

  void _fetchCourseStudents() {
    _database.child('Affairs').child('Academic').child('112').child('Course').child(widget.courseID).child('Student').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is List) {
        setState(() {
          _courseStudentIDs = List<String>.from(data);
        });
        _fetchStudents();
      }
    });
  }

  void _fetchStudents() {
    _database.child('Personnel').child('Student').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        Map<String, dynamic> studentsInCourse = {};
        data.forEach((key, value) {
          if (_courseStudentIDs.contains(key)) {
            studentsInCourse[key] = value;
          }
        });
        setState(() {
          _students = studentsInCourse;
        });
        _fetchRollCallData();
      }
    });
  }

  void _fetchSessionCount() {
    _database.child('Affairs').child('Academic').child('112').child('Course').child(widget.courseID).child('Credit').once().then((DatabaseEvent event) {
      setState(() {
        _sessionCount = int.parse(event.snapshot.value.toString());
      });
    });
  }

  void _fetchRollCallData() {
    String dateKey = formatDate(_selectedDate);
    _database.child('Affairs').child('Academic').child('112').child('Course').child(widget.courseID).child('RollCall').child(dateKey).onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _rollCallData = Map<String, dynamic>.from(data);
        });
      } else {
        setState(() {
          _rollCallData = {};
        });
      }
      _initializeRollCallForAllStudents();
    });
  }

  void _initializeRollCallForAllStudents() {
    String dateKey = formatDate(_selectedDate);
    _courseStudentIDs.forEach((studentID) {
      if (!_rollCallData.containsKey(studentID)) {
        _rollCallData[studentID] = {};
        for (int session = 1; session <= _sessionCount; session++) {
          _rollCallData[studentID][session.toString()] = false;
        }
        _updateRollCallForStudent(studentID);
      }
    });
  }

  void _updateRollCallForStudent(String studentID) {
    String dateKey = formatDate(_selectedDate);
    _rollCallData[studentID].forEach((session, isPresent) {
      _database.child('Affairs').child('Academic').child('112').child('Course').child(widget.courseID).child('RollCall').child(dateKey).child(studentID).child(session).set(isPresent);
    });
  }

  void _updateRollCall(String studentID, int session, bool isPresent) {
    String dateKey = formatDate(_selectedDate);
    _database.child('Affairs').child('Academic').child('112').child('Course').child(widget.courseID).child('RollCall').child(dateKey).child(studentID).child(session.toString()).set(isPresent);
    setState(() {
      _rollCallData[studentID][session] = isPresent;
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fetchRollCallData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("手動點名"),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text("選擇日期: ${formatDate(_selectedDate)}"),
            trailing: Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                String studentID = _students.keys.elementAt(index);
                String studentName = _students[studentID]['StudentName'];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('$studentID - $studentName'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_sessionCount, (session) {
                        int sessionIndex = session + 1;
                        bool isPresent = _rollCallData[studentID]?[sessionIndex] ?? false;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _updateRollCall(studentID, sessionIndex, !isPresent);
                            });
                          },
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text('節次 $sessionIndex'),
                              ),
                              Checkbox(
                                value: isPresent,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _updateRollCall(studentID, sessionIndex, value ?? false);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
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
