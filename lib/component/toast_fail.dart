
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

toastFail(BuildContext context,{String text = 'การเชื่อมต่อผิดพลาด',Color color = Colors.grey,Color fontColor = Colors.white,int duration = 3}) {
  return Fluttertoast.showToast(
      msg: text,
      backgroundColor: color,
      toastLength: duration == 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      textColor: fontColor
  );
}