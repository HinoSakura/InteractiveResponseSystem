import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class TeacherRecordScreen extends StatelessWidget {
  final String courseID;

  TeacherRecordScreen({required this.courseID});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('查看紀錄'),
          bottom: TabBar(
            tabs: [
              Tab(text: '即時互動作答情況'),
              Tab(text: '出缺席率'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnswerStatisticsList(courseID: courseID),
            AttendanceStatisticsList(courseID: courseID),
          ],
        ),
      ),
    );
  }
}

class AnswerStatisticsList extends StatefulWidget {
  final String courseID;

  AnswerStatisticsList({required this.courseID});

  @override
  _AnswerStatisticsListState createState() => _AnswerStatisticsListState();
}

class _AnswerStatisticsListState extends State<AnswerStatisticsList> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<String, dynamic> _answerStatistics = {};
  Map<String, String> _questionBankNames = {};
  Map<String, String> _activityQuestionBankIDs = {};

  @override
  void initState() {
    super.initState();
    _fetchAnswerStatistics();
    _fetchQuestionBankNames();
    _fetchActivityQuestionBankIDs();
  }

  void _fetchAnswerStatistics() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child(widget.courseID)
        .child('AnswerQuestions')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _answerStatistics = Map<String, dynamic>.from(data);
        });
      } else {
        setState(() {
          _answerStatistics = {};
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
        .child(widget.courseID)
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
        .child(widget.courseID)
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
      itemCount: _answerStatistics.length,
      itemBuilder: (context, index) {
        String date = _answerStatistics.keys.elementAt(index);
        Map<String, dynamic> activities = _answerStatistics[date];
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
              return ListTile(
                title: Text('$questionBankName', style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityStatisticsDetailScreen(
                        date: date,
                        courseID: widget.courseID,
                        activityID: activityID,
                        questionBankID: questionBankID,
                        questionBankName: questionBankName,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class ActivityStatisticsDetailScreen extends StatelessWidget {
  final String date;
  final String courseID;
  final String activityID;
  final String questionBankID;
  final String questionBankName;

  ActivityStatisticsDetailScreen({
    required this.date,
    required this.courseID,
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
      body: ActivityStatisticsDetailList(
        date: date,
        courseID: courseID,
        activityID: activityID,
        questionBankID: questionBankID,
      ),
    );
  }
}

class ActivityStatisticsDetailList extends StatefulWidget {
  final String date;
  final String courseID;
  final String activityID;
  final String questionBankID;

  ActivityStatisticsDetailList({
    required this.date,
    required this.courseID,
    required this.activityID,
    required this.questionBankID,
  });

  @override
  _ActivityStatisticsDetailListState createState() => _ActivityStatisticsDetailListState();
}

class _ActivityStatisticsDetailListState extends State<ActivityStatisticsDetailList> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<String, dynamic> _answerDetails = {};
  Map<String, dynamic> _questions = {};
  final List<String> _optionLabels = ['A', 'B', 'C', 'D', 'E'];
  List<int> _correctCounts = [];
  List<int> _incorrectCounts = [];

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
        .child(widget.courseID)
        .child('AnswerQuestions')
        .child(widget.date)
        .child(widget.activityID)
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
        .child(widget.courseID)
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
        _calculateCorrectIncorrectCounts();
      } else {
        setState(() {
          _questions = {};
        });
      }
    });
  }

  void _calculateCorrectIncorrectCounts() {
    List<int> correctCounts = [];
    List<int> incorrectCounts = [];

    _questions.forEach((questionID, questionDetail) {
      int totalCorrect = 0;
      int totalIncorrect = 0;

      _answerDetails.forEach((studentID, answers) {
        if (answers.containsKey(questionID)) {
          bool isCorrect = answers[questionID]['correct'] ?? false;
          if (isCorrect) {
            totalCorrect++;
          } else {
            totalIncorrect++;
          }
        }
      });

      correctCounts.add(totalCorrect);
      incorrectCounts.add(totalIncorrect);
    });

    setState(() {
      _correctCounts = correctCounts;
      _incorrectCounts = incorrectCounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (_questions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 350,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: 8,
                      child: Text(
                        '各題正確與錯誤人數',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: BarChart(
                        BarChartData(
                          backgroundColor: Colors.white,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  final int index = value.toInt();
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 4,
                                    child: Text(
                                      '題目${index + 1}',
                                      style: const TextStyle(color: Colors.black, fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8,
                                    child: Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: Colors.black, fontSize: 14), // 設置顏色為黑色
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(_correctCounts.length, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: _correctCounts[index].toDouble(),
                                  color: Color(0xFF00E3E3),
                                  width: 15,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                BarChartRodData(
                                  toY: _incorrectCounts[index].toDouble(),
                                  color: Colors.redAccent,
                                  width: 15,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            );
                          }),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ..._questions.entries.map((entry) {
          String questionID = entry.key;
          Map<String, dynamic> questionDetail = entry.value;
          List<dynamic> options = questionDetail['Options'] ?? [];
          Map<int, int> optionCounts = {};
          int totalCorrect = 0;
          int totalIncorrect = 0;

          _answerDetails.forEach((studentID, answers) {
            if (answers.containsKey(questionID)) {
              List<dynamic> selectedOptions = answers[questionID]['answer'] ?? [];
              bool isCorrect = answers[questionID]['correct'] ?? false;
              if (isCorrect) {
                totalCorrect++;
              } else {
                totalIncorrect++;
              }
              selectedOptions.forEach((optionIndex) {
                optionCounts[optionIndex] = (optionCounts[optionIndex] ?? 0) + 1;
              });
            }
          });

          int index = _questions.keys.toList().indexOf(questionID);

          return Card(
            elevation: 5,
            margin: EdgeInsets.all(10.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '題目${index + 1}: ${questionDetail['QuestionContent'] ?? '未知題目'}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8.0),
                  Text('選項:', style: TextStyle(fontSize: 16)),
                  ...options.asMap().entries.map((entry) {
                    int optionIndex = entry.key;
                    Map<String, dynamic> option = entry.value;
                    int count = optionCounts[optionIndex] ?? 0;
                    bool isCorrect = option['YesOrNo'];
                    return Row(
                      children: [
                        Text(
                          '(${_optionLabels[optionIndex]}) ${option['OptionsContent']}: $count 人選擇',
                          style: TextStyle(
                            fontSize: 16,
                            color: count > 0
                                ? (isCorrect ? Colors.green : Colors.red)
                                : Colors.black,
                          ),
                        ),
                        if (count > 0)
                          Icon(
                            isCorrect ? Icons.check : Icons.close,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: 8.0),
                  Text('正確率: ${_answerDetails.length == 0 ? 0 : totalCorrect / _answerDetails.length * 100}%', style: TextStyle(fontSize: 16)),
                  Text('作答正確人數: $totalCorrect', style: TextStyle(fontSize: 16)),
                  Text('作答錯誤人數: $totalIncorrect', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}



class AttendanceStatisticsList extends StatefulWidget {
  final String courseID;

  AttendanceStatisticsList({required this.courseID});

  @override
  _AttendanceStatisticsListState createState() => _AttendanceStatisticsListState();
}

class _AttendanceStatisticsListState extends State<AttendanceStatisticsList> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<String, dynamic> _attendanceRecords = {};
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
    _fetchTotalStudents();
  }

  void _fetchAttendanceRecords() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child(widget.courseID)
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

  void _fetchTotalStudents() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child(widget.courseID)
        .child('Student')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is List) {
        setState(() {
          _totalStudents = data.length;
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
        int totalPresent = 0;
        if (studentAttendance is Map) {
          studentAttendance.forEach((studentID, sessions) {
            if (sessions is List) {
              if (sessions.any((isPresent) => isPresent == true)) {
                totalPresent++;
              }
            }
          });
        }
        int totalAbsent = _totalStudents - totalPresent;
        return Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text('日期: $date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('總人數: $_totalStudents', style: TextStyle(fontSize: 16)),
                Text('出席人數: $totalPresent', style: TextStyle(fontSize: 16)),
                Text('缺席人數: $totalAbsent', style: TextStyle(fontSize: 16)),
                Text('出席率: ${_totalStudents == 0 ? 0 : totalPresent / _totalStudents * 100}%', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
}
