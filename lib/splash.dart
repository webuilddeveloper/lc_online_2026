import 'dart:async';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startDelay();
  }

  void _startDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    _callNavigatorPage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            "assets/icons/logo.png",
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Future<void> _callNavigatorPage() async {
    // โหลดจาก UserProfileStore (มี _SafeStorage ป้องกัน OperationError แล้ว)
    await UserProfileStore.instance.load();
    final userType = UserProfileStore.instance.userType;

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MenuPage(userType: userType),
      ),
      (_) => false,
    );
  }
}