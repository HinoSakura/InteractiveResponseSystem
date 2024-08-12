import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class IrsTeacher extends StatefulWidget {
  @override
  _IrsTeacherState createState() => _IrsTeacherState();
}

class _IrsTeacherState extends State<IrsTeacher> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  String? _selectedQuestionBankID;
  int? _timePerQuestion;
  String? _activityID;
  List<String> _questionBankList = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestionBanks();
  }

  Future<DataSnapshot> _fetchQuestionBankData(String questionBankID) {
    return _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('QuestionBank')
        .child(questionBankID)
        .child('QuestionBankName')
        .get();
  }

  void _fetchQuestionBanks() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('QuestionBank')
        .once()
        .then((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          Map<String, dynamic> questionBanks = Map<String, dynamic>.from(snapshot.value as Map);
          _questionBankList = questionBanks.keys.toList();
          _questionBankList.remove(_questionBankList[0]);
        });
      }
    }).catchError((error) {
      print('Error fetching question banks: $error');
    });
  }

  void _startActivity() async {
    DatabaseReference newActivityRef = _database
        .child('Affairs/Academic/112/Course/00001/Activity')
        .push();

    await newActivityRef.set({
      'Closetime': _timePerQuestion,
      'OpenOrClose': true,
      'Opentime': DateTime.now().toIso8601String(),
      'QuestionBankID': _selectedQuestionBankID,
      'Participants': {}
    });

    setState(() {
      _activityID = newActivityRef.key;
    });

    Navigator.push(context, MaterialPageRoute(
        builder: (_) => WaitingForActivityScreen(activityID: _activityID!)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('教師界面'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedQuestionBankID,
              hint: Text('選擇題庫'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedQuestionBankID = newValue!;
                });
              },
              items: _questionBankList.map((String questionBankID) {
                return DropdownMenuItem<String>(
                  value: questionBankID,
                  child: FutureBuilder(
                    future: _fetchQuestionBankData(questionBankID),
                    builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.value == null) {
                        return Text('題庫名稱未找到');
                      }
                      return Text(snapshot.data!.value.toString());
                    },
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '選擇題庫',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() {
                  _timePerQuestion = int.tryParse(value);
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '每題作答時間（秒）',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedQuestionBankID != null && _timePerQuestion != null
                  ? _startActivity
                  : null,
              child: Text('開始活動'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaitingForActivityScreen extends StatefulWidget {
  final String activityID;

  WaitingForActivityScreen({required this.activityID});

  @override
  _WaitingForActivityScreenState createState() => _WaitingForActivityScreenState();
}

class _WaitingForActivityScreenState extends State<WaitingForActivityScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  int studentCount = 0;

  @override
  void initState() {
    super.initState();
    _database.child('Affairs/Academic/112/Course/00001/Activity/${widget.activityID}/Participants')
        .onValue.listen((event) {
      if (event.snapshot.value != null) {
        final participants = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          studentCount = participants.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("等待活動開始"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('當前已加入學生數量: $studentCount',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final activityID = widget.activityID;
                DatabaseReference activityRef = FirebaseDatabase.instance.ref()
                    .child('Affairs')
                    .child('Academic')
                    .child('112')
                    .child('Course')
                    .child('00001')
                    .child('Activity')
                    .child(activityID);

                await activityRef.update({'IsStart': true,'OpenOrClose':false});
                Navigator.pop(context);
              },
              child: Text('開始作答'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
