import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';


class SelectQuestionsScreen extends StatefulWidget {
  final String questionBankName;
  final String? questionBankKey;

  SelectQuestionsScreen({required this.questionBankName, this.questionBankKey});

  @override
  _SelectQuestionsScreenState createState() => _SelectQuestionsScreenState();
}

class _SelectQuestionsScreenState extends State<SelectQuestionsScreen> {
  late DatabaseReference _questionsRef;
  late DatabaseReference _existingQuestionsRef;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _questionsMap = {};
  Map<String, bool> _selectedQuestions = {};
  Map<String, dynamic> _existingQuestionsMap = {};

  @override
  void initState() {
    super.initState();
    _questionsRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/001/Question');
    _existingQuestionsRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/${widget.questionBankKey ?? '001'}/Question');

    _questionsRef.once().then((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          _questionsMap = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    });

    _existingQuestionsRef.once().then((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          _existingQuestionsMap = Map<String, dynamic>.from(snapshot.value as Map);
          _updateSelectedQuestions();
        });
      }
    });
  }

  void _updateSelectedQuestions() {
    _questionsMap.forEach((key, question) {
      bool isSelected = _selectedQuestions[key] ?? false;
      if (_existingQuestionsMap.containsKey(key)) {
        isSelected = true;
      }
      _selectedQuestions[key] = isSelected;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('選取題目'),
      ),
      body: Column(
        children: [
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
              DatabaseReference questionBankRef;
              if (widget.questionBankKey != null) {
                questionBankRef = FirebaseDatabase.instance.ref().child('Affairs/Academic/112/Course/00001/QuestionBank/${widget.questionBankKey!}');
              } else {
                questionBankRef = _questionsRef.parent!.push();
              }

              final newQuestionBankKey = questionBankRef.key;

              _selectedQuestions.keys.forEach((selectedKey) async {
                if (_selectedQuestions[selectedKey] == true) {
                  var selectedQuestion = _questionsMap[selectedKey];
                  await questionBankRef.child('Question').child(selectedKey).set(selectedQuestion);
                }
              });
              Navigator.pop(context);
            },
            child: Text('確認'),
          ),
        ],
      ),
    );
  }
}

