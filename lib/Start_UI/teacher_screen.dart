import 'package:flutter/material.dart';
import 'package:testfirebase20240311/Question/question_list.dart';
import 'package:testfirebase20240311/Question/questionbank_list.dart';
import 'package:testfirebase20240311/Instant_Interaction/irs_teacher.dart';
import 'package:testfirebase20240311/Rollcall/rollcall_teacher.dart';
import 'package:testfirebase20240311/Record/record_teacher.dart';
import 'package:testfirebase20240311/Discussion/discussion_screen.dart';

class TeacherScreen extends StatelessWidget {
  final String courseName;
  final String teacherID;

  TeacherScreen({required this.courseName,required this.teacherID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$courseName 課程管理'),
        backgroundColor: Colors.blue[600],
      ),
      body: Container(
        color: Colors.blue[100], // 藍色背景
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
              child: ListView(
                padding: EdgeInsets.all(8.0),
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.library_add, color: Colors.blue),
                      title: Text('新增題庫', style: TextStyle(fontSize: 18.0)),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QuestionBankListPage()),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.add_circle, color: Colors.grey),
                      title: Text('新增題目', style: TextStyle(fontSize: 18.0)),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QuestionListPage()),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.event, color: Colors.orange),
                      title: Text('開啟活動', style: TextStyle(fontSize: 18.0)),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => IrsTeacher()),
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
                          MaterialPageRoute(builder: (context) => DiscussionBoardScreen(courseId: '00001',userType: 'teacher',userId: teacherID,)),
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
                          MaterialPageRoute(builder: (context) => TeacherRecordScreen(courseID: '00001')),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.event_available, color: Colors.red),
                      title: Text('課程點名', style: TextStyle(fontSize: 18.0)),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TeacherRollCallScreen(courseID: '00001',)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



