import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherProfilePage extends StatefulWidget {
  final String teacherID;

  TeacherProfilePage({required this.teacherID});

  @override
  _TeacherProfilePageState createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _fetchTeacherName();
  }

  void _fetchTeacherName() {
    _database
        .child('Personnel')
        .child('Teacher')
        .child(widget.teacherID)
        .child('TeacherName')
        .once()
        .then((event) {
      setState(() {
        _teacherName = event.snapshot.value as String?;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('個人資料'),
        backgroundColor: Colors.blue[600],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 24.0),
              Text(
                '職編: ${widget.teacherID}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              if (_teacherName != null)
                Text(
                  '姓名: $_teacherName',
                  style: TextStyle(fontSize: 20),
                ),
              if (_teacherName == null)
                CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
