import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:testfirebase20240311/Question/insert_question.dart';
import 'package:testfirebase20240311/Question/edit_data.dart';

class QuestionListPage extends StatefulWidget {
  @override
  _QuestionListPageState createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  final DatabaseReference _questionsRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/001/Question');

  Future<void> _deleteQuestion(String questionKey) async {
    await _questionsRef.child(questionKey).remove();
  }

  Future<bool?> _showDeleteConfirmationDialog(String questionKey) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('刪除題目'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('你確定要刪除這個題目嗎？'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('刪除'),
              onPressed: () async {
                await _deleteQuestion(questionKey);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("所有題目"),
      ),
      body: StreamBuilder(
        stream: _questionsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("沒有題目"));
          }
          final questionsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final questions = questionsMap.entries.toList();
          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              var questionKey = questions[index].key;
              var question = questions[index].value;
              return Dismissible(
                key: Key(questionKey),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmationDialog(questionKey);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(question['QuestionContent']),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditQuestionPage(questionKey: questionKey, questionData: question)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddQuestionPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
