import 'package:flutter/material.dart';

buttonCloseBack(BuildContext context) {
  return Column(
    children: [
      MaterialButton(
        minWidth: 29,
        onPressed: () {
          Navigator.pop(context);
        },
        color: const Color(0xFFF5661F),
        textColor: Colors.white,
        shape: const CircleBorder(
            side: BorderSide(
                color: Colors.grey, width: 1.0, style: BorderStyle.solid)),
        child: const Icon(
          Icons.close,
          size: 29,
        ),
      ),
    ],
    // mainAxisAlignment: MainAxisAlignment.center,
    // crossAxisAlignment: CrossAxisAlignment.end,
  );
}
