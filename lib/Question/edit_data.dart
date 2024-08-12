import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EditQuestionPage extends StatefulWidget {
  final String questionKey;
  final Map<String, dynamic> questionData;

  EditQuestionPage({required this.questionKey, required this.questionData});

  @override
  _EditQuestionPageState createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<EditQuestionPage> {
  late TextEditingController _questionController;
  late List<Map<String, dynamic>> _options;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.questionData['QuestionContent']);
    _options = List<Map<String, dynamic>>.from(
      widget.questionData['Options'].map((option) {
        return {
          "content": TextEditingController(text: option['OptionsContent']),
          "isCorrect": option['YesOrNo']
        };
      }),
    );
  }

  void _addOption() {
    setState(() {
      _options.add({"content": TextEditingController(), "isCorrect": false});
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _saveQuestion() async {
    String questionContent = _questionController.text;
    List<Map<String, dynamic>> options = _options.map((option) {
      return {
        "OptionsContent": option["content"].text,
        "YesOrNo": option["isCorrect"]
      };
    }).toList();

    DatabaseReference questionRef = FirebaseDatabase.instance
        .ref()
        .child('Affairs/Academic/112/Course/00001/QuestionBank/001/Question')
        .child(widget.questionKey);

    await questionRef.set({
      "QuestionContent": questionContent,
      "Options": options,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("編輯題目"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveQuestion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(labelText: "題目內容"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () => _removeOption(index),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _options[index]["content"],
                          decoration: InputDecoration(
                            labelText: "選項 ${String.fromCharCode(65 + index)}",
                          ),
                        ),
                      ),
                      Checkbox(
                        value: _options[index]["isCorrect"],
                        onChanged: (bool? value) {
                          setState(() {
                            _options[index]["isCorrect"] = value!;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addOption,
              child: Text("新增選項"),
            ),
          ],
        ),
      ),
    );
  }
}