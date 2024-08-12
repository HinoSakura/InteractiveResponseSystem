import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testfirebase20240311/Start_UI/login_page.dart';
import 'package:testfirebase20240311/Start_UI/student_screen.dart';
import 'package:testfirebase20240311/Profile/profile_student.dart';

class StudentCourseSelectionScreen extends StatefulWidget {
  final String studentID;

  StudentCourseSelectionScreen({required this.studentID});

  @override
  _StudentCourseSelectionScreenState createState() => _StudentCourseSelectionScreenState();
}

class _StudentCourseSelectionScreenState extends State<StudentCourseSelectionScreen> {
  String _selectedYear = '113';
  List<String> _years = ['113', '112', '111'];
  List<String> _courses = ['Flutter', '程式設計', '資料庫設計', '程式語言'];
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  void _fetchStudentName() {
    final DatabaseReference _database = FirebaseDatabase.instance.reference();
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
        backgroundColor: Colors.blue[600],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '學年度',
              style: TextStyle(color: Colors.white, fontSize: 18.0),
            ),
            SizedBox(width: 8.0),
            DropdownButton<String>(
              value: _selectedYear,
              dropdownColor: Colors.blue[600],
              style: TextStyle(color: Colors.white, fontSize: 18.0),
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedYear = newValue!;
                });
              },
              items: _years.map<DropdownMenuItem<String>>((String year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        widget.studentID,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Text(
                        _studentName ?? 'Loading...',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('個人資料'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(studentID: widget.studentID)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('登出'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.blue[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '課程選擇 : ',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.book, color: Colors.blue),
                      title: Text(_courses[index], style: TextStyle(fontSize: 18.0)),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentScreen(courseName: _courses[index], studentID: widget.studentID)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
