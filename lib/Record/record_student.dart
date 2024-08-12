import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentRecordScreen extends StatelessWidget {
  final String studentID;

  StudentRecordScreen({required this.studentID});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('查看紀錄'),
          bottom: TabBar(
            tabs: [
              Tab(text: '即時互動作答紀錄'),
              Tab(text: '出缺席紀錄'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnswerRecordList(studentID: studentID),
            AttendanceRecordList(studentID: studentID),
          ],
        ),
      ),
    );
  }
}

class AnswerRecordList extends StatefulWidget {
  final String studentID;

  AnswerRecordList({required this.studentID});

  @override
  _AnswerRecordListState createState() => _AnswerRecordListState();
}

class _AnswerRecordListState extends State<AnswerRecordList> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<String, dynamic> _answerRecords = {};
  Map<String, String> _questionBankNames = {};
  Map<String, String> _activityQuestionBankIDs = {};

  @override
  void initState() {
    super.initState();
    _fetchAnswerRecords();
    _fetchQuestionBankNames();
    _fetchActivityQuestionBankIDs();
  }

  void _fetchAnswerRecords() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('AnswerQuestions')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _answerRecords = Map<String, dynamic>.from(data);
        });
      } else {
        setState(() {
          _answerRecords = {};
        });
      }
    });
  }

  void _fetchQuestionBankNames() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('QuestionBank')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _questionBankNames = data.map<String, String>((key, value) {
            return MapEntry(key, value['QuestionBankName'] ?? '無名稱題庫');
          });
        });
      }
    });
  }

  void _fetchActivityQuestionBankIDs() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('Activity')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _activityQuestionBankIDs = data.map<String, String>((key, value) {
            return MapEntry(key, value['QuestionBankID'] ?? '未知題庫ID');
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _answerRecords.length,
      itemBuilder: (context, index) {
        String date = _answerRecords.keys.elementAt(index);
        Map<String, dynamic> activities = _answerRecords[date];
        return Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            title: Text('日期: $date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: activities.entries.map<Widget>((entry) {
              String activityID = entry.key;
              String questionBankID = _activityQuestionBankIDs[activityID] ?? '未知題庫ID';
              String questionBankName = _questionBankNames[questionBankID] ?? '未知題庫';
              Map<String, dynamic> studentRecords = entry.value;
              if (studentRecords.containsKey(widget.studentID)) {
                return ListTile(
                  title: Text('$questionBankName', style: TextStyle(fontSize: 16)),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityDetailScreen(
                          date: date,
                          studentID: widget.studentID,
                          activityID: activityID,
                          questionBankID: questionBankID,
                          questionBankName: questionBankName,
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Container();
              }
            }).toList(),
          ),
        );
      },
    );
  }
}

class ActivityDetailScreen extends StatelessWidget {
  final String date;
  final String studentID;
  final String activityID;
  final String questionBankID;
  final String questionBankName;

  ActivityDetailScreen({
    required this.date,
    required this.studentID,
    required this.activityID,
    required this.questionBankID,
    required this.questionBankName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(questionBankName),
      ),
      body: ActivityDetailList(
        date: date,
        studentID: studentID,
        activityID: activityID,
        questionBankID: questionBankID,
      ),
    );
  }
}

class ActivityDetailList extends StatefulWidget {
  final String date;
  final String studentID;
  final String activityID;
  final String questionBankID;

  ActivityDetailList({
    required this.date,
    required this.studentID,
    required this.activityID,
    required this.questionBankID,
  });

  @override
  _ActivityDetailListState createState() => _ActivityDetailListState();
}

class _ActivityDetailListState extends State<ActivityDetailList> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<String, dynamic> _answerDetails = {};
  Map<String, dynamic> _questions = {};
  final List<String> _optionLabels = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _fetchAnswerDetails();
    _fetchQuestions();
  }

  void _fetchAnswerDetails() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('AnswerQuestions')
        .child(widget.date)
        .child(widget.activityID)
        .child(widget.studentID)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _answerDetails = Map<String, dynamic>.from(data);
        });
      } else {
        setState(() {
          _answerDetails = {};
        });
      }
    });
  }

  void _fetchQuestions() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('QuestionBank')
        .child(widget.questionBankID)
        .child('Question')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _questions = Map<String, dynamic>.from(data);
        });
      } else {
        setState(() {
          _questions = {};
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _answerDetails.length,
      itemBuilder: (context, index) {
        String questionID = _answerDetails.keys.elementAt(index);
        Map<String, dynamic> answerDetail = _answerDetails[questionID];
        Map<String, dynamic> questionDetail = _questions[questionID] ?? {};
        List<dynamic> options = questionDetail['Options'] ?? [];
        List<dynamic> correctOptions = options.where((option) => option['YesOrNo'] == true).toList();
        List<dynamic> selectedOptions = answerDetail['answer'] ?? [];

        return Card(
          elevation: 5,
          margin: EdgeInsets.all(10.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('題目: ${questionDetail['QuestionContent'] ?? '未知題目'}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8.0),
                Text('選項:', style: TextStyle(fontSize: 16)),
                ...options.asMap().entries.map((entry) {
                  int optionIndex = entry.key;
                  Map<String, dynamic> option = entry.value;
                  bool isSelected = selectedOptions.contains(optionIndex);
                  bool isCorrect = option['YesOrNo'] == true;
                  return Row(
                    children: [
                      Text(
                        '(${_optionLabels[optionIndex]}) ${option['OptionsContent']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Colors.black,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                    ],
                  );
                }).toList(),
                SizedBox(height: 8.0),
                Text('是否正確: ${answerDetail['correct'] ? '是' : '否'}', style: TextStyle(fontSize: 16)),
                if (!answerDetail['correct']) ...[
                  SizedBox(height: 8.0),
                  Text('正確答案:', style: TextStyle(fontSize: 16)),
                  ...correctOptions.map((option) => Text('(${_optionLabels[options.indexOf(option)]}) ${option['OptionsContent']}',
                      style: TextStyle(fontSize: 16, color: Colors.green))).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class AttendanceRecordScreen extends StatelessWidget {
  final String studentID;

  AttendanceRecordScreen({required this.studentID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('出缺席紀錄'),
      ),
      body: AttendanceRecordList(studentID: studentID),
    );
  }
}

class AttendanceRecordList extends StatefulWidget {
  final String studentID;

  AttendanceRecordList({required this.studentID});

  @override
  _AttendanceRecordListState createState() => _AttendanceRecordListState();
}

class _AttendanceRecordListState extends State<AttendanceRecordList> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<String, dynamic> _attendanceRecords = {};

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  void _fetchAttendanceRecords() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('RollCall')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _attendanceRecords = Map<String, dynamic>.from(data);
        });
      } else {
        setState(() {
          _attendanceRecords = {};
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        String date = _attendanceRecords.keys.elementAt(index);
        dynamic studentAttendance = _attendanceRecords[date];
        if (studentAttendance is Map && studentAttendance.containsKey(widget.studentID)) {
          List<dynamic> attendanceData = List<dynamic>.from(studentAttendance[widget.studentID] ?? []);
          return Card(
            elevation: 5,
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ExpansionTile(
              title: Text('日期: $date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              children: attendanceData.asMap().entries.where((entry) => entry.value != null).map<Widget>((entry) {
                int session = entry.key;
                bool isPresent = entry.value;
                return ListTile(
                  title: Text('第 ${session} 堂', style: TextStyle(fontSize: 16)),
                  subtitle: Text(isPresent ? '出席' : '缺席', style: TextStyle(fontSize: 16, color: isPresent ? Colors.green : Colors.red)),
                );
              }).toList(),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
