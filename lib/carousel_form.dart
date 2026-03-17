import 'package:LawyerOnline/button_close_back.dart';
import 'package:LawyerOnline/comment.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/content_carousel.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// ignore: must_be_immutable
class CarouselForm extends StatefulWidget {
  const CarouselForm({
    super.key,
    this.url,
    this.code,
    this.model,
    this.urlGallery,
  });

  final String? url;
  final String? code;
  // ignore: unnecessary_question_mark
  final dynamic? model;
  final String? urlGallery;

  @override
  _CarouselForm createState() => _CarouselForm();
}

class _CarouselForm extends State<CarouselForm> {
  late Comment comment;
  late int _limit;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onLoading() async {
    setState(() {
      _limit = _limit + 10;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    _refreshController.loadComplete();
  }

  @override
  void initState() {
    setState(() {
      _limit = 10;
    });

    // comment = Comment(
    //   code: widget.code,
    //   url: widget.urlComment,
    //   model: post('${newsCommentApi}read',
    //       {'skip': 0, 'limit': _limit, 'code': widget.code}),
    //   limit: _limit,
    // );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "รายละเอียด",
        backBtn: true,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overScroll) {
          overScroll.disallowIndicator();
          return false;
        },
        child: SmartRefresher(
          enablePullDown: false,
          enablePullUp: true,
          footer: const ClassicFooter(
            loadingText: ' ',
            canLoadingText: ' ',
            idleText: ' ',
            idleIcon: Icon(Icons.arrow_upward, color: Colors.transparent),
          ),
          controller: _refreshController,
          onLoading: _onLoading,
          child: ListView(
            shrinkWrap: true,
            children: [
              Stack(
                // fit: StackFit.expand,
                // alignment: AlignmentDirectional.bottomCenter,
                // shrinkWrap: true,
                // physics: ClampingScrollPhysics(),
                children: [
                  ContentCarousel(
                    code: widget.code!,
                    url: widget.url!,
                    model: widget.model,
                    urlGallery: widget.urlGallery!,
                  ),
                ],
                // overflow: Overflow.clip,
              ),
              // widget.urlComment != '' ? comment : Container(),
            ],
          ),
        ),
      ),
    );
  }

  void goBack() {
    Navigator.pop(context, false);
  }
}
