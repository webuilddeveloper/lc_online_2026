import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hms_room_kit/hms_room_kit.dart';

class CallRoom extends StatefulWidget {
  const CallRoom({super.key});

  @override
  State<CallRoom> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CallRoom> {
  TextEditingController meetingLinkController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
          body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/welcome.svg',
                width: width * 0.95,
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('Experience the power of 100ms',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        letterSpacing: 0.25,
                        color: themeDefaultColor,
                        height: 1.17,
                        fontSize: 34,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27),
                child: Text('Try out the HMS Prebuilt SDK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        letterSpacing: 0.5,
                        color: themeSubHeadingColor,
                        height: 1.5,
                        fontSize: 16,
                        fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        ),
      )),
    );
  }
}