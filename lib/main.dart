// import 'package:LawyerOnline/shared/notification-service.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/services/in_app_notification_service.dart';
import 'package:LawyerOnline/services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:LawyerOnline/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final _secureStorage = FlutterSecureStorage();

Future<Locale> _loadSavedLocale() async {
  final localeCode = await _secureStorage.read(key: 'appLanguage');
  if (localeCode != null && localeCode.isNotEmpty) {
    return Locale(localeCode);
  }
  return const Locale('th');
}

void _handleNotificationNavigation(RemoteMessage message) {
  final page = message.data['page'];
  final code = message.data['code'];

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final state = navigatorKey.currentState;
    if (state == null) return;

    if (page == 'chat') {
      // state.push(
      //   MaterialPageRoute(builder: (_) => ChatPageUser(roomCode: code)),
      // );
    } else if (page == 'appointment_detail') {
      // state.push(
      //   MaterialPageRoute(builder: (_) => AppointmentDetailPage(appointmentId: code)),
      // );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

// ✅ ให้ FCM โชว์ popup ตอนแอปเปิดอยู่บน iOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (!kIsWeb) {
    await NotificationService.init();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await [Permission.camera, Permission.microphone].request();

    // (1) แอปเปิดอยู่ (foreground) — โชว์ local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService.showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      );

      InAppNotificationService.show(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        onTap: () => _handleNotificationNavigation(message),
      );
      // NotificationStore.instance.incrementUnread();
    });

    // 👉 เพิ่ม (2): กด notification ตอนแอป background → foreground
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);

    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('Notification init error: $e');
      // แอปยังทำงานต่อได้ปกติ
    }

    // await LineSDK.instance.setup('2009412792');
    LineSDK.instance.setup('2009412792').then((_) {
      // ignore: avoid_print
      print('LineSDK Prepared');
    });
  }

  await initializeDateFormatting('th', null);
  final startLocale = await _loadSavedLocale();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('th'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('th'),
      startLocale: startLocale,
      saveLocale: true,
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );

  // 👉 เพิ่ม (3): กด notification ตอนแอปถูกปิดสนิท (terminated)
  if (!kIsWeb) {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 👈 เพิ่มตรงนี้
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      title: 'LC Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, primary: Color(0xFF0262EC)),
        useMaterial3: true,
        textTheme: GoogleFonts.promptTextTheme(),
        fontFamily: GoogleFonts.prompt().fontFamily,
      ),
      home: const SplashPage(),
    );
  }
}
