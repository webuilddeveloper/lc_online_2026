import 'dart:convert';

import 'package:LawyerOnline/comment_loading.dart';
import 'package:LawyerOnline/component/toast_fail.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ignore: must_be_immutable
class Comment extends StatefulWidget {
  Comment({super.key, this.code, this.url, this.model, this.limit});

  final String? code;
  final String? url;
  Future<dynamic>? model;
  final int? limit;

  @override
  _Comment createState() => _Comment();
}

class _Comment extends State<Comment> {
  final txtDescription = TextEditingController();
  late FlutterSecureStorage storage;
  String username = '';
  String imageUrlCreateBy = '';
  bool hideDialog = true;

  // Future<dynamic> _futureModel;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    txtDescription.dispose();
    super.dispose();
  }

  @override
  void initState() {
    storage = const FlutterSecureStorage();

    getUser();
    super.initState();
  }

  setDelayShowDialog() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        hideDialog = true;
        // Here you can write your code for open new view
      });
      return showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () {
              return Future.value(false);
            },
            child: CupertinoAlertDialog(
              title: const Text(
                'ขอบคุณสำหรับความคิดเห็น',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Kanit',
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
              content: const Text(" "),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(
                    "ยกเลิก",
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Kanit',
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }

  getUser() async {
    var value = await storage.read(key: 'dataUserLoginLC');
    var data = json.decode(value!);

    setState(() {
      imageUrlCreateBy = data['imageUrl'];
      // username = data['firstName'] + ' ' + data['lastName'];
      username = data['username'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
          alignment: Alignment.centerLeft,
          child: const Text(
            'แสดงความคิดเห็น',
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Kanit',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
          child: TextField(
            controller: txtDescription,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            maxLength: 100,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Kanit',
            ),
            // decoration: new InputDecoration(hintText: "Enter Something", contentPadding: const EdgeInsets.all(20.0)),
            decoration: InputDecoration(
              fillColor: Colors.white,
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.black.withAlpha(50), width: 1.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), gapPadding: 1),
              hintText: 'แสดงความคิดเห็น',
              contentPadding: const EdgeInsets.all(10.0),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7514),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text(
              'ส่ง',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Kanit',
              ),
            ),
            onPressed: () {
              sendComment();
            },
          ),
        ),
        FutureBuilder<dynamic>(
          // future: widget.model,
          future: widget.model,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return myComment(snapshot.data);
            } else {
              return const CommentLoading();
            }
          },
        ),
      ],
    );
  }

  myComment(dynamic model) {
    return ListView.builder(
      shrinkWrap: true, // 1st add
      physics: const ClampingScrollPhysics(), // 2nd
      // scrollDirection: Axis.horizontal,
      itemCount: model.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            padding: EdgeInsets.all(
                '${model[index]['imageUrlCreateBy']}' != '' ? 0.0 : 5.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17.5),
                color: Colors.black12),
            width: 35.0,
            height: 35.0,
            child: '${model[index]['imageUrlCreateBy']}' != ''
                ? CircleAvatar(
                    backgroundImage: model[index]['imageUrlCreateBy'] != null
                        ? NetworkImage('${model[index]['imageUrlCreateBy']}')
                        : null,
                  )
                : Image.asset(
                    'assets/images/user_not_found.png',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        top: 5, bottom: 5, left: 15, right: 15),
                    margin: const EdgeInsets.only(
                        left: 1, right: 15, top: 5, bottom: 1),
                    decoration: BoxDecoration(
                        color: Colors.black.withAlpha(10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(50))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${model[index]['createBy']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Kanit',
                          ),
                        ),
                        Text(
                          '${model[index]['description']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Kanit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  dateStringToDate(model[index]['createDate']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black.withAlpha(80),
                    fontFamily: 'Kanit',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  sendComment() async {
    if (txtDescription.text != '') {
      postAny('${widget.url}create', {
        'createBy': username,
        'imageUrlCreateBy': imageUrlCreateBy,
        'reference': widget.code,
        'description': txtDescription.text
      }).then((response) {
        if (response == 'S') {
          txtDescription.text = '';

          // ignore: use_build_context_synchronously
          unfocus(context);

          setState(() {
            widget.model = post('${widget.url}read',
                {'skip': 0, 'limit': widget.limit, 'code': widget.code});
          });
          // helloWorld();
          // ignore: use_build_context_synchronously
          toastFail(context, text: 'ขอบคุณสำหรับความคิดเห็น', duration: 4);
        } else {
          return showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () {
                  return Future.value(false);
                },
                child: CupertinoAlertDialog(
                  title: const Text(
                    'ไม่สามารถแสดงความคิดเห็นได้',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Kanit',
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  content: const Text(" "),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text(
                        "ตกลง",
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Kanit',
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      }).catchError(
        (onError) {
          return showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () {
                  return Future.value(false);
                },
                child: CupertinoAlertDialog(
                  title: const Text(
                    'การเชื่อมต่อมีปัญหากรุณาลองใหม่อีกครั้ง',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Kanit',
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  content: const Text(" "),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text(
                        "ตกลง",
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Kanit',
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }
}
