import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testfirebase20240311/Start_UI/student_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class IrsStudentSelectionScreen extends StatefulWidget {
  final String studentID;

  IrsStudentSelectionScreen({required this.studentID});

  @override
  _IrsStudentSelectionScreenState createState() => _IrsStudentSelectionScreenState();
}

class _IrsStudentSelectionScreenState extends State<IrsStudentSelectionScreen> {
  List<Map<String, dynamic>> _activities = [];
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  void _fetchActivities() {
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
        var activities = <Map<String, dynamic>>[];
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic> && value['OpenOrClose'] == true) {
            var activityData = Map<String, dynamic>.from(value);
            activityData['id'] = key;
            activities.add(activityData);
          }
        });
        setState(() {
          _activities = activities;
        });
      } else {
        print("Received data is not a Map or is Null.");
      }
    });
  }

  String formatDateTime(String dateTime) {
    DateTime parsedDateTime = DateTime.parse(dateTime);
    return '${parsedDateTime.year}-${parsedDateTime.month.toString().padLeft(2, '0')}-${parsedDateTime.day.toString().padLeft(2, '0')} '
        '${parsedDateTime.hour.toString().padLeft(2, '0')}:${parsedDateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('選擇活動')),
      body: ListView.builder(
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          var activity = _activities[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: FutureBuilder<DataSnapshot>(
                future: _database
                    .child('Affairs')
                    .child('Academic')
                    .child('112')
                    .child('Course')
                    .child('00001')
                    .child('QuestionBank')
                    .child(activity['QuestionBankID'])
                    .child('QuestionBankName')
                    .get(),
                builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('加載中...');
                  }
                  if (snapshot.hasData && snapshot.data!.value != null) {
                    return Text(snapshot.data!.value.toString());
                  }
                  return Text('題庫名稱未找到');
                },
              ),
              subtitle: Text('開始時間: ${formatDateTime(activity['Opentime'])}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaitingForActivityScreen(
                      studentID: widget.studentID,
                      activityID: activity['id'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

//等待介面
class WaitingForActivityScreen extends StatefulWidget {
  final String studentID;
  final String activityID;

  WaitingForActivityScreen({required this.studentID, required this.activityID});

  @override
  _WaitingForActivityScreenState createState() => _WaitingForActivityScreenState();
}

class _WaitingForActivityScreenState extends State<WaitingForActivityScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  bool _isActivityStarted = false;

  @override
  void initState() {
    super.initState();
    _joinActivity();
    _listenToActivityStart();
  }

  void _joinActivity() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('Activity')
        .child(widget.activityID)
        .child('Participants')
        .child(widget.studentID)
        .set(true)
        .catchError((e) => print(e));
  }

  void _listenToActivityStart() {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('Activity')
        .child(widget.activityID)
        .child('IsStart')
        .onValue
        .listen((event) {
      if (event.snapshot.value == true) {
        setState(() {
          _isActivityStarted = true;
        });
        if (_isActivityStarted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => IrsStudent(
                studentID: widget.studentID,
                activityID: widget.activityID,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("等待活動開始")),
      body: Center(
        child: _isActivityStarted
            ? Text("活動已開始，跳轉中...")
            : Text("等待活動開始..."),
      ),
    );
  }
}

//作答介面
class IrsStudent extends StatefulWidget {
  final String studentID;
  final String activityID;

  IrsStudent({required this.studentID, required this.activityID});

  @override
  _IrsStudentState createState() => _IrsStudentState();
}

class _IrsStudentState extends State<IrsStudent> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  Map<dynamic, dynamic>? _currentActivity;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  DateTime? _questionStartTime;
  Timer? _timer;
  int? _remainingTime;
  List<bool> _answersCorrect = [];
  Map<int, Set<int>> _selectedOptions = {};
  bool _hasNavigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _listenToActivity(widget.activityID);
  }

  void _listenToActivity(String activityID) {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('Activity')
        .child(activityID)
        .onValue
        .listen((event) {
      var data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _currentActivity = Map<String, dynamic>.from(data);
          _fetchQuestions(_currentActivity!['QuestionBankID']);
        });
      } else {
        print("No activity data found for the given ID.");
      }
    });
  }

  void _fetchQuestions(String questionBankID) {
    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('QuestionBank')
        .child(questionBankID)
        .child('Question')
        .once()
        .then((DatabaseEvent event) {
      var data = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<Map<String, dynamic>> questions = [];
      data.forEach((key, value) {
        Map<String, dynamic> question = Map<String, dynamic>.from(value);
        question['id'] = key;
        questions.add(question);
      });
      setState(() {
        _questions = questions;
        _currentQuestionIndex = 0;
        _startTimer();
      });
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _questionStartTime = DateTime.now();
    int totalSeconds = _currentActivity!['Closetime'] as int;
    _remainingTime = totalSeconds;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      setState(() {
        if (_remainingTime! > 0) {
          _remainingTime = _remainingTime! - 1;
        } else {
          _timer?.cancel();
          _goToNextQuestion();
        }
      });
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _startTimer();
      });
    } else {
      _timer?.cancel();
      _showResults();
    }
  }

  void _showResults() {
    if (!_hasNavigatedToResult) {
      _hasNavigatedToResult = true;
      saveAnswersToDatabase();
      markAttendance();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(answersCorrect: _answersCorrect,studentID: widget.studentID,),
        ),
      ).then((_) => _hasNavigatedToResult = false);
    }
  }

  void saveAnswersToDatabase() {
    String today = DateTime.now().toString().substring(0, 10);
    String activityID = widget.activityID;
    String studentID = widget.studentID;

    DatabaseReference answersRef = _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('AnswerQuestions')
        .child(today)
        .child(activityID)
        .child(studentID);

    for (int i = 0; i < _questions.length; i++) {
      answersRef.child(_questions[i]['id']).set({
        'answer': _selectedOptions[i]?.toList() ?? [],
        'correct': i < _answersCorrect.length ? _answersCorrect[i] : false
      });
    }
  }

  void markAttendance() {
    String today = DateTime.now().toString().substring(0, 10);
    DatabaseReference rollCallRef = _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('RollCall')
        .child(today)
        .child(widget.studentID);

    _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child('00001')
        .child('Credit')
        .once()
        .then((DatabaseEvent event) {
      int sessionCount = int.parse(event.snapshot.value.toString());
      for (int i = 1; i <= sessionCount; i++) {
        rollCallRef.child(i.toString()).set(true);
      }
    });
  }

  void _toggleSelection(int questionIndex, int optionIndex) {
    setState(() {
      _selectedOptions.putIfAbsent(questionIndex, () => Set<int>());
      if (_selectedOptions[questionIndex]!.contains(optionIndex)) {
        _selectedOptions[questionIndex]!.remove(optionIndex);
      } else {
        if (_questions[questionIndex]['type'] == 'single') {
          _selectedOptions[questionIndex]!.clear();
        }
        _selectedOptions[questionIndex]!.add(optionIndex);
      }
    });
  }

  void _submitAnswers() {
    var currentQuestion = _questions[_currentQuestionIndex];
    var correctOptions = <int>[];
    for (int i = 0; i < currentQuestion['Options'].length; i++) {
      if (currentQuestion['Options'][i]['YesOrNo']) {
        correctOptions.add(i);
      }
    }

    var selectedOptions = _selectedOptions[_currentQuestionIndex] ?? Set<int>();
    var selectedList = selectedOptions.toList()..sort();
    var correctList = correctOptions.toList()..sort();

    bool isCorrect = listEquals(selectedList, correctList);

    if (_answersCorrect.length <= _currentQuestionIndex) {
      _answersCorrect.add(isCorrect);
    } else {
      _answersCorrect[_currentQuestionIndex] = isCorrect;
    }

    _goToNextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text('學生界面')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('學生界面'),
        actions: [
          if (_remainingTime != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: Text('剩餘時間: $_remainingTime 秒')),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentQuestion['QuestionContent'],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ...List<Widget>.generate(currentQuestion['Options'].length, (index) {
              var option = currentQuestion['Options'][index];
              bool isSelected = _selectedOptions[_currentQuestionIndex]?.contains(index) ?? false;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(option['OptionsContent']),
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleSelection(_currentQuestionIndex, index);
                    },
                  ),
                  onTap: () {
                    _toggleSelection(_currentQuestionIndex, index);
                  },
                ),
              );
            }),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitAnswers,
                child: Text('確認答案'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class ResultsScreen extends StatelessWidget {
  final List<bool> answersCorrect;
  final String studentID;

  ResultsScreen({required this.answersCorrect, required this.studentID});


  @override
  Widget build(BuildContext context) {
    int correctCount = answersCorrect.where((x) => x).length;
    int incorrectCount = answersCorrect.length - correctCount;
    double correctPercentage = (correctCount / answersCorrect.length) * 100;

    return Scaffold(
      appBar: AppBar(title: Text('結算結果')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 250,
              child: InteractivePieChart(
                correctCount: correctCount,
                incorrectCount: incorrectCount,
              ),
            ),
            SizedBox(height: 20),
            Text('你的正確率為: ${correctPercentage.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('正確題數: $correctCount',
                style: TextStyle(fontSize: 18, color: Colors.green)),
            Text('錯誤題數: $incorrectCount',
                style: TextStyle(fontSize: 18, color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('完成'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => StudentScreen(
                        courseName: '',studentID: studentID,
                      )),
                      (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InteractivePieChart extends StatefulWidget {
  final int correctCount;
  final int incorrectCount;

  InteractivePieChart({required this.correctCount, required this.incorrectCount});

  @override
  _InteractivePieChartState createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                setState(() {
                  if (event is FlLongPressEnd || event is FlPanEndEvent) {
                    _touchedIndex = -1;
                  } else {
                    _touchedIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                  }
                });
              }),
              sections: showingSections(),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        SizedBox(width: 50),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Indicator(color: Colors.green, text: '正確', isSquare: true),
            SizedBox(height: 4),
            Indicator(color: Colors.red, text: '錯誤', isSquare: true),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    int total = widget.correctCount + widget.incorrectCount;
    double correctPercentage = (widget.correctCount / total) * 100;
    double incorrectPercentage = (widget.incorrectCount / total) * 100;

    return List.generate(2, (i) {
      final isTouched = i == _touchedIndex;
      final double fontSize = isTouched ? 25 : 16;
      final double radius = isTouched ? 60 : 50;
      final double widgetSize = isTouched ? 55 : 40;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: correctPercentage,
            title: '${correctPercentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: isTouched ? _Badge('正確', size: widgetSize) : null,
            badgePositionPercentageOffset: .98,
          );
        case 1:
          return PieChartSectionData(
            color: Colors.red,
            value: incorrectPercentage,
            title: '${incorrectPercentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: isTouched ? _Badge('錯誤', size: widgetSize) : null,
            badgePositionPercentageOffset: .98,
          );
        default:
          throw Error();
      }
    });
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;

  _Badge(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor = const Color(0xff505050),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}