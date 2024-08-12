import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testfirebase20240311/Question/questionbank_screen.dart';
import 'package:testfirebase20240311/Question/editquestionbank_screen.dart';

class QuestionBankListPage extends StatefulWidget {
  @override
  _QuestionBankListPageState createState() => _QuestionBankListPageState();
}

class _QuestionBankListPageState extends State<QuestionBankListPage> {
  final DatabaseReference _questionBanksParentRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("所有題庫"),
      ),
      body: StreamBuilder(
        stream: _questionBanksParentRef.child('QuestionBank').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("沒有題庫"));
          }
          final questionBanksMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final questionBanks = questionBanksMap.entries.toList();
          questionBanks.remove(questionBanks[0]);
          return ListView.builder(
            itemCount: questionBanks.length,
            itemBuilder: (context, index) {
              var questionBankEntry = questionBanks[index];
              var questionBankKey = questionBankEntry.key;
              var questionBank = questionBankEntry.value;
              return Dismissible(
                key: Key(questionBankKey),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmationDialog(context);
                },
                onDismissed: (direction) {
                  _deleteQuestionBank(questionBankKey);
                },
                child: ListTile(
                  title: Text(questionBank['QuestionBankName']), // 使用 QuestionBankName 展示題庫名稱
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditQuestionBankScreen(questionBankKey: questionBankKey, initialQuestionBankName: questionBank['QuestionBankName'])),
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
          String? questionBankName = await _showAddQuestionBankDialog(context);
          if (questionBankName != null && questionBankName.isNotEmpty) {
            DatabaseReference newQuestionBankRef = _questionBanksParentRef.child('QuestionBank').push();
            await newQuestionBankRef.set({
              'QuestionBankName': questionBankName,
            });
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SelectQuestionsScreen(questionBankName: questionBankName, questionBankKey: newQuestionBankRef.key)),
            );
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('刪除確認'),
          content: Text('您確定要刪除此題庫嗎？'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('確認'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteQuestionBank(String questionBankKey) async {
    await _questionBanksParentRef.child('QuestionBank/$questionBankKey').remove();
  }

  Future<String?> _showAddQuestionBankDialog(BuildContext context) {
    final TextEditingController _questionBankNameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新增題庫'),
          content: TextField(
            controller: _questionBankNameController,
            decoration: InputDecoration(labelText: '題庫名稱'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('確認'),
              onPressed: () {
                Navigator.of(context).pop(_questionBankNameController.text);
              },
            ),
          ],
        );
      },
    );
  }
}
