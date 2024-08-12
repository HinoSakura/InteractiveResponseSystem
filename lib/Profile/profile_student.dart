import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfilePage extends StatefulWidget {
  final String studentID;

  ProfilePage({required this.studentID});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  void _fetchStudentName() {
    _database
        .child('Personnel')
        .child('Student')
        .child(widget.studentID)
        .child('StudentName')
        .once()
        .then((event) {
      setState(() {
        _studentName = event.snapshot.value as String?;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '學號: ${widget.studentID}',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 16.0),
                  if (_studentName != null)
                    Text(
                      '姓名: $_studentName',
                      style: TextStyle(fontSize: 20),
                    ),
                  if (_studentName == null)
                    CircularProgressIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
