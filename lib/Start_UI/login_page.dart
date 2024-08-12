import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:testfirebase20240311/Firebase/validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testfirebase20240311/Course/elective_teacher_courses.dart';
import 'package:testfirebase20240311/Course/elective_student_courses.dart';

User? user;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();
  bool _isProcessing = false;

  Future<FirebaseApp> _initializeFirebase() async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    user = FirebaseAuth.instance.currentUser;
    return firebaseApp;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('InteractiveResponseSystem'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
        ),
        body: FutureBuilder(
          future: _initializeFirebase(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _emailTextController,
                              focusNode: _focusEmail,
                              validator: (value) => Validator.validateEmail(email: value),
                              decoration: InputDecoration(
                                labelText: "電子郵件",
                                hintText: "請輸入您的電子郵件",
                                labelStyle: TextStyle(color: Colors.blueAccent),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              cursorColor: Colors.blueAccent,
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _passwordTextController,
                              focusNode: _focusPassword,
                              obscureText: true,
                              validator: (value) => Validator.validatePassword(password: value),
                              decoration: InputDecoration(
                                labelText: "密碼",
                                hintText: "請輸入您的密碼",
                                labelStyle: TextStyle(color: Colors.blueAccent),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              cursorColor: Colors.blueAccent,
                            ),
                            SizedBox(height: 24.0),
                            _isProcessing
                                ? CircularProgressIndicator()
                                : ElevatedButton(
                              onPressed: () async {
                                _focusEmail.unfocus();
                                _focusPassword.unfocus();

                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isProcessing = true;
                                  });

                                  try {
                                    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                                      email: _emailTextController.text,
                                      password: _passwordTextController.text,
                                    );

                                    final email = userCredential.user!.email!;
                                    final id = email.split('@')[0];

                                    final studentSnapshot = await FirebaseDatabase.instance
                                        .reference()
                                        .child('Personnel')
                                        .child('Student')
                                        .child(id.toUpperCase())
                                        .once();

                                    if (studentSnapshot.snapshot.value != null) {
                                      print('student');
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => StudentCourseSelectionScreen(studentID: id.toUpperCase()),
                                        ),
                                      );
                                    } else {
                                      final teacherSnapshot = await FirebaseDatabase.instance
                                          .reference()
                                          .child('Personnel')
                                          .child('Teacher')
                                          .child(id.toUpperCase())
                                          .once();

                                      if (teacherSnapshot.snapshot.value != null) {
                                        print('teacher');
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) => CourseSelectionScreen(teacherID: id.toUpperCase()),
                                          ),
                                        );
                                      } else {
                                        print('身份未知');
                                      }
                                    }

                                    setState(() {
                                      _isProcessing = false;
                                    });
                                  } catch (e) {
                                    print('登入失敗：$e');
                                    setState(() {
                                      _isProcessing = false;
                                    });
                                  }
                                }
                              },
                              child: Text(
                                '登入',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(vertical: 16.0)),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
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

            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
