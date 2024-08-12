import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testfirebase20240311/Start_UI/login_page.dart';
import 'package:testfirebase20240311/Start_UI/teacher_screen.dart';
import 'package:testfirebase20240311/Profile/profile_teacher.dart';

class CourseSelectionScreen extends StatefulWidget {
  final String teacherID;

  CourseSelectionScreen({required this.teacherID});

  @override
  _CourseSelectionScreenState createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  String _selectedYear = '113';
  List<String> _years = ['113', '112', '111'];
  List<String> _courses = ['Flutter', '程式設計', '資料庫設計', '程式語言'];
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _fetchTeacherName();
  }

  void _fetchTeacherName() {
    final DatabaseReference _database = FirebaseDatabase.instance.reference();
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
                        widget.teacherID,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Text(
                        _teacherName ?? 'Loading...',
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
                  MaterialPageRoute(builder: (context) => TeacherProfilePage(teacherID: widget.teacherID)),
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
                          MaterialPageRoute(builder: (context) => TeacherScreen(courseName: _courses[index],teacherID: widget.teacherID,)),
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
