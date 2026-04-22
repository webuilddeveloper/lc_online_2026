import 'dart:ui';

import 'package:LawyerOnline/map-card.dart';
import 'package:LawyerOnline/post-list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:LawyerOnline/calendar.dart';
import 'package:LawyerOnline/home.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/message.dart';
import 'package:LawyerOnline/my-appointment.dart';
import 'package:LawyerOnline/profile.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuPage extends StatefulWidget {
  MenuPage({Key? key, this.pageIndex, this.modelprofile, this.userType})
      : super(key: key);

  final int? pageIndex;
  final modelprofile;
  String? userType;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<Widget> pages = <Widget>[];
  int _currentPage = 0;
  DateTime? currentBackPressTime;

  final TextEditingController chatController = TextEditingController();
  final storage = FlutterSecureStorage();
  String userType = "";
  String name = "";
  String imageUrl = '';

  @override
  void initState() {
    callRead();
    super.initState();
    Future.delayed(Duration.zero, () {
      requestPermissions();
    });
    // _loadUserProfile();
  }

  Future requestPermissions() async {
    var cameraStatus = await Permission.camera.request();
    var micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      print("Permission granted");
    } else {
      print("Permission denied");
    }
  }

  callRead() async {
    var userType = await storage.read(key: 'userType');
    var imageProfile = await storage.read(key: 'imageUrlSocial');
    var nameProfile = await storage.read(key: 'name');
    setState(() {
      userType = widget.userType ?? userType.toString();
      name = nameProfile.toString();
      imageUrl = imageProfile.toString();

      pages = <Widget>[
        HomePage(),
        MessagePage(),
        CommunityPage(),
        // PostList(),
        // LawyerOnlineList(),
        // MapCardPage(),
        userType == "user" ? AppointmentListPage() : CalendarPage(),
        ProfilePage(),
      ];
      _currentPage = widget.pageIndex ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawerScrimColor: Colors.transparent,
      // body: GestureDetector(
      //   onTap: () => FocusScope.of(context).unfocus(),
      //   child: WillPopScope(
      //     onWillPop: confirmExit,
      //     child: IndexedStack(index: _currentPage, children: pages),
      //   ),
      // ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: WillPopScope(
          onWillPop: confirmExit,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              // Fade + slide up เบาๆ
              final offsetAnim = Tween<Offset>(
                begin: const Offset(0, 0.02), // slide up นิดเดียว
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.bounceIn,
              ));
              // easeOutCubic
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnim,
                  child: child,
                ),
              );
            },
            // key สำคัญมาก — บอก AnimatedSwitcher ว่า widget เปลี่ยนแล้ว
            child: KeyedSubtree(
              key: ValueKey<int>(_currentPage),
              child: pages.isNotEmpty ? pages[_currentPage] : const SizedBox(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15), // ระยะลอยจากขอบ
        child: ClipRRect(
          // padding: const EdgeInsets.all(20),
          // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          borderRadius: BorderRadius.circular(30),
          // decoration: BoxDecoration(
          //   color: const Color(0xFF010101),
          //   borderRadius: BorderRadius.circular(67),
          // ),
          // height: 70,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                color: Color(0xFF010101).withOpacity(0.50),
                borderRadius: BorderRadius.circular(67),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: _bottomItem("assets/icons/home.png", 0,
                        title: 'หนัาหลัก'),
                  ),
                  Flexible(
                    flex: _currentPage == 1 ? 1 : 1,
                    child: _bottomItem("assets/icons/message.png", 1,
                        title: 'ข้อความ', showBadge: true),
                  ),
                  Flexible(
                    flex: _currentPage == 2 ? 1 : 1,
                    child: _bottomItem("assets/icons/logo.png", 2,
                        title: 'social', showBadge: false),
                  ),
                  Flexible(
                    flex: _currentPage == 3 ? 1 : 1,
                    child: _bottomItem("assets/icons/appointment.png", 3,
                        title: 'นัดหมาย', showBadge: true),
                  ),
                  Flexible(
                    flex: _currentPage == 4 ? 1 : 1,
                    child: _bottomItem("assets/icons/profile.png", 4,
                        title: 'โปรไฟล์'),
                  )

                  // _bottomItem(
                  //   Icons.person,
                  //   3,
                  //   isImageUrl: true,
                  //   title: 'โปรไฟล์',
                  // ),
                ],
              ),
            ),
          ),
        ),
        //   ),
        // ),
      ),
    );
  }

  Future<bool> confirmExit() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: 'กดอีกครั้งเพื่อออก',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  Widget _bottomItem(
    String icon,
    int index, {
    bool isImageUrl = false,
    required String title,
    bool showBadge = false,
  }) {
    final isSelected = _currentPage == index;
    // return GestureDetector(
    //   onTap: () {
    //     // if (index == 2) {
    //     //   postTrackClick("แจ้งเตือน");
    //     // }
    //     setState(() {
    //       _currentPage = index;
    //     });
    //     // _loadUserProfile();
    //   },
    //   // borderRadius: BorderRadius.circular(50),
    //   child: AnimatedContainer(
    //     duration: Duration(milliseconds: 500),
    //     curve: Curves.linearToEaseOut,
    //     padding: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
    //     child: Container(
    //       height: double.infinity,
    //       // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    //       decoration: BoxDecoration(
    //         color: isSelected
    //             ? Theme.of(context).primaryColor
    //             : Colors.transparent,
    //         borderRadius: BorderRadius.circular(45),
    //         boxShadow: [
    //           BoxShadow(
    //             color: isSelected
    //                 ? Colors.black.withOpacity(0.2)
    //                 : Colors.transparent,
    //             blurRadius: 20,
    //             offset: Offset(0, 10),
    //           ),
    //         ],
    //         // shape: BoxShape.circle,
    //       ),
    //       child: Row(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         crossAxisAlignment: CrossAxisAlignment.center,
    //         children: [
    //           Image.asset(
    //             icon,
    //             width: 24,
    //             height: 24,
    //             color: isSelected ? Colors.white : Color(0xFF666666),
    //           ),

    //           isSelected
    //               ? Row(
    //                   children: [
    //                     const SizedBox(
    //                       width: 10,
    //                     ),
    //                     Text(
    //                       title,
    //                       style: TextStyle(
    //                         fontSize: 14,
    //                         color: isSelected
    //                             ? Colors.white
    //                             : const Color(0xFF666666),
    //                       ),
    //                     ),
    //                   ],
    //                 )
    //               : const SizedBox()
    //         ],
    //       ),
    //     ),
    //   ),
    // );
    return GestureDetector(
      onTap: () => setState(() {
        _currentPage = index;
      }),
      child: AnimatedContainer(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // color: isSelected ? Color.fromARGB(255, 8, 93, 211) : Colors.transparent,
          color: isSelected
              ? Color.fromARGB(255, 248, 249, 253).withOpacity(0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          // border: Border.all(
          //   color: isSelected ? Color.fromARGB(255, 8, 93, 211) : Colors.transparent,
          // ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Color.fromARGB(255, 8, 93, 211).withOpacity(0.3)
                  : Colors.transparent,
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Image.asset(
                  icon,
                  color: index == 2 ? null :
                      isSelected ? Color.fromARGB(255, 8, 93, 211) : Colors.white70,
                  width: 24,
                  height: 24,
                  // size: 26,
                ),
                if (showBadge)
                  Positioned(
                    top: -1,
                    right: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 247, 12, 12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            // isSelected
            //     ? Row(
            //         children: [
            //           const SizedBox(
            //             width: 10,
            //           ),
            //           Text(
            //             title,
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: isSelected
            //                   ? Color(0xFF085DD3)
            //                   : const Color(0xFF666666),
            //             ),
            //           ),
            //         ],
            //       )
            //     : const SizedBox()
          ],
        ),
      ),
    );
  }
}

class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(Icons.home_rounded, 0),
                _item(Icons.search_rounded, 1),
                _item(Icons.person_rounded, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, int index) {
    final selected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: selected ? Colors.white : Colors.white70,
          size: 26,
        ),
      ),
    );
  }
}
