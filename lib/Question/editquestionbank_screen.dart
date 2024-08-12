import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testfirebase20240311/Start_UI/login_page.dart';

class EditQuestionBankScreen extends StatefulWidget {
  final String questionBankKey;
  final String initialQuestionBankName;

  EditQuestionBankScreen({required this.questionBankKey, required this.initialQuestionBankName});

  @override
  _EditQuestionBankScreenState createState() => _EditQuestionBankScreenState();
}

class _EditQuestionBankScreenState extends State<EditQuestionBankScreen> {
  late DatabaseReference _questionsRef;
  final TextEditingController _questionBankNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _questionsMap = {};
  Map<String, bool> _selectedQuestions = {};

  @override
  void initState() {
    super.initState();
    _questionsRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/001/Question');
    _questionBankNameController.text = widget.initialQuestionBankName; // Initialize with initial name

    _questionsRef.once().then((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          _questionsMap = Map<String, dynamic>.from(snapshot.value as Map);
          for (var questionKey in _questionsMap.keys) {
            _selectedQuestions[questionKey] = false;
          }
          DatabaseReference selectedQuestionsRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/${widget.questionBankKey}/Question');
          selectedQuestionsRef.once().then((DatabaseEvent selectedEvent) {
            final selectedSnapshot = selectedEvent.snapshot;
            if (selectedSnapshot.value != null) {
              final selectedQuestionsList = Map<String, dynamic>.from(selectedSnapshot.value as Map);
              for (var selectedQuestionKey in selectedQuestionsList.keys) {
                if (_selectedQuestions.containsKey(selectedQuestionKey)) {
                  _selectedQuestions[selectedQuestionKey] = true;
                }
              }
              setState(() {});
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('編輯題庫'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _questionBankNameController,
              decoration: InputDecoration(
                labelText: '題庫名稱',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜尋題目',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _questionsMap.length,
              itemBuilder: (context, index) {
                String key = _questionsMap.keys.elementAt(index);
                var question = _questionsMap[key];
                bool isSelected = _selectedQuestions[key] ?? false;
                if (_searchController.text.isNotEmpty && !question['QuestionContent'].toString().contains(_searchController.text)) {
                  return Container();
                }
                return CheckboxListTile(
                  title: Text(question['QuestionContent']),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedQuestions[key] = value ?? false;
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              DatabaseReference questionBankRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/${widget.questionBankKey}');
              await questionBankRef.update({'QuestionBankName': _questionBankNameController.text});
              DatabaseReference selectedQuestionsRef = questionBankRef.child('Question');
              await selectedQuestionsRef.remove();
              _selectedQuestions.forEach((key, value) async {
                if (_selectedQuestions[key] == true) {
                  var selectedQuestion = _questionsMap[key];
                  await questionBankRef.child('Question').child(key).set(selectedQuestion);
                }
              });

              Navigator.pop(context);
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }
}
