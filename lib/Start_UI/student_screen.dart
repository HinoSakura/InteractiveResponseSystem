import 'package:flutter/material.dart';
import 'package:testfirebase20240311/Instant_Interaction/irs_student.dart';
import 'package:testfirebase20240311/Record/record_student.dart';
import 'package:testfirebase20240311/Discussion/discussion_screen.dart';

class StudentScreen extends StatelessWidget {
  final String studentID;
  final String courseName;

  StudentScreen({required this.courseName,required this.studentID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$courseName 課程介面'),
        backgroundColor: Colors.blue[600],
      ),
      body: Container(
        color: Colors.blue[100],
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '功能選擇 : ',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child:ListView(
                  padding: EdgeInsets.all(8.0),
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.library_books, color: Colors.blue),
                        title: Text('即時互動', style: TextStyle(fontSize: 18.0)),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => IrsStudentSelectionScreen(studentID: studentID)),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.question_answer, color: Colors.green),
                        title: Text('回饋討論', style: TextStyle(fontSize: 18.0)),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DiscussionBoardScreen(courseId: '00001',userType: 'student',userId: studentID,)),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.history, color: Colors.purple),
                        title: Text('課程紀錄', style: TextStyle(fontSize: 18.0)),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StudentRecordScreen(studentID: studentID)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            ]
        )
      ),
    );
  }
}
