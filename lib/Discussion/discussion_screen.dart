import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class DiscussionBoardScreen extends StatefulWidget {
  final String courseId;
  final String userType;
  final String userId;

  DiscussionBoardScreen({required this.courseId, required this.userType, required this.userId});

  @override
  _DiscussionBoardScreenState createState() => _DiscussionBoardScreenState();
}

class _DiscussionBoardScreenState extends State<DiscussionBoardScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final Map<String, TextEditingController> _commentControllers = {};
  late StreamSubscription _postsSubscription;
  List<Map<String, dynamic>> _posts = [];
  late Timer _timer;
  final ValueNotifier<int> _timeNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _startTimer();
  }

  void _fetchPosts() {
    _postsSubscription = _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child(widget.courseId)
        .child('DiscussionBoard')
        .child('Posts')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        List<Map<String, dynamic>> posts = [];
        data.forEach((key, value) {
          posts.add({
            'postId': key,
            'posterType': value['PosterType'],
            'content': value['Content'],
            'timestamp': value['Timestamp'],
            'comments': value['Comments'] != null
                ? Map<String, dynamic>.from(value['Comments'])
                : {},
          });
        });
        setState(() {
          _posts = posts;
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _timeNotifier.value = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _addPost(String content) {
    final newPostRef = _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child(widget.courseId)
        .child('DiscussionBoard')
        .child('Posts')
        .push();

    newPostRef.set({
      'PosterType': widget.userType,
      'Content': content,
      'Timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _addComment(String postId, String content) {
    final newCommentRef = _database
        .child('Affairs')
        .child('Academic')
        .child('112')
        .child('Course')
        .child(widget.courseId)
        .child('DiscussionBoard')
        .child('Posts')
        .child(postId)
        .child('Comments')
        .push();

    newCommentRef.set({
      'CommenterType': widget.userType,
      'Content': content,
      'Timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      _commentControllers[postId]?.clear();
    });
  }

  String _formatTimestamp(String timestamp) {
    final postDate = DateTime.parse(timestamp);
    final currentDate = DateTime.now();
    final difference = currentDate.difference(postDate);

    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小時前';
    } else {
      return '${postDate.year}年${postDate.month}月${postDate.day}日';
    }
  }

  @override
  void dispose() {
    _postsSubscription.cancel();
    _timer.cancel();
    _timeNotifier.dispose();
    _commentControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController postController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('討論版'),
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final comments = Map<String, dynamic>.from(post['comments']);
          final postId = post['postId'];

          _commentControllers.putIfAbsent(postId, () => TextEditingController());

          return Card(
            margin: EdgeInsets.all(10.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${post['posterType'] == 'student' ? '學生' : '老師'}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(post['content']),
                  ValueListenableBuilder(
                    valueListenable: _timeNotifier,
                    builder: (context, value, child) {
                      return Text(_formatTimestamp(post['timestamp']));
                    },
                  ),
                  SizedBox(height: 10.0),
                  for (var commentKey in comments.keys)
                    Column(
                      children: [
                        ListTile(
                          title: Text('${comments[commentKey]['CommenterType'] == 'student' ? '學生' : '老師'}: ${comments[commentKey]['Content']}'),
                          subtitle: ValueListenableBuilder(
                            valueListenable: _timeNotifier,
                            builder: (context, value, child) {
                              return Text(_formatTimestamp(comments[commentKey]['Timestamp']));
                            },
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentControllers[postId],
                          decoration: InputDecoration(labelText: '新增留言'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          _addComment(postId, _commentControllers[postId]!.text);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: postController,
                decoration: InputDecoration(labelText: '新增貼文'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _addPost(postController.text);
                postController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}
