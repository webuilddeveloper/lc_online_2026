// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

const kTranslucentBlackColor = Color(0x66000000);
const _kMaxDragSpeed = 400.0;

class GalleryView extends StatefulWidget {
  const GalleryView(
      {super.key, required this.imageUrl, required this.imageProvider});

  final List imageUrl;
  final List<ImageProvider> imageProvider;

  @override
  _GalleryViewState createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  @override
  void initState() {
    super.initState();
  }

  dataImage(index) {
    return ImageViewer(
      initialIndex: index,
      imageProviders: widget.imageProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (widget.imageUrl.isNotEmpty)
          Material(
            child: InkWell(
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return dataImage(0);
                  },
                );
              },
              child: ClipRRect(
                child: widget.imageUrl[0] != null
                    ? Image.network(
                        '${widget.imageUrl[0]}',
                        width: MediaQuery.of(context).size.width,
                        height: 360.0,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(
          height: 5.0,
        ),
        if (widget.imageUrl.length > 1)
          SizedBox(
            width: double.infinity,
            child: Row(
              children: <Widget>[
                if (widget.imageUrl.length > 1)
                  Material(
                    child: InkWell(
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return dataImage(1);
                          },
                        );
                      },
                      child: ClipRRect(
                        child: widget.imageUrl[1] != null
                            ? Image.network(
                                '${widget.imageUrl[1]}',
                                width:
                                    MediaQuery.of(context).size.width / 3.035,
                                height:
                                    MediaQuery.of(context).size.width / 3.035,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                  ),
                if (widget.imageUrl.length > 2)
                  Material(
                    child: InkWell(
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return dataImage(2);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                        child: ClipRRect(
                          child: widget.imageUrl[2] != null
                              ? Image.network(
                                  '${widget.imageUrl[2]}',
                                  width:
                                      MediaQuery.of(context).size.width / 3.035,
                                  height:
                                      MediaQuery.of(context).size.width / 3.035,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                if (widget.imageUrl.length > 3)
                  Material(
                    child: InkWell(
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return dataImage(3);
                          },
                        );
                      },
                      // child: Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            child: widget.imageUrl[3] != null
                                ? Image.network(
                                    '${widget.imageUrl[3]}',
                                    width: MediaQuery.of(context).size.width /
                                        3.035,
                                    height: MediaQuery.of(context).size.width /
                                        3.035,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          if (widget.imageUrl.length > 4)
                            Positioned(
                              // right: 50,
                              // top: 50,
                              child: Container(
                                color: const Color.fromRGBO(0, 0, 0, 0.5),
                                width:
                                    MediaQuery.of(context).size.width / 3.035,
                                height:
                                    MediaQuery.of(context).size.width / 3.035,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '+ ${widget.imageUrl.length - 4}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Kanit',
                                          color: Colors.white),
                                    ),
                                    const Text(
                                      'รูปภาพ',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Kanit',
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // ),
              ],
            ),
          ),
      ],
    );
  }
}

class ImageViewer extends StatefulWidget {
  const ImageViewer({
    super.key,
    required this.initialIndex,
    required this.imageProviders,
  });

  final int initialIndex;
  final List<ImageProvider> imageProviders;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentPageIndex;
  final bool _isLocked = false;

  late double _start;
  late AnimationController _offsetController;
  late Animation<Offset> _offsetAnimation;
  late Tween<Offset> _offsetTween;
  bool _isDragging = false;

  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;
  late Tween<double> _opacityTween;

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentPageIndex = widget.initialIndex;

    _offsetController =
        AnimationController(vsync: this, duration: Duration.zero);
    _offsetTween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);
    _offsetAnimation = _offsetTween.animate(
      CurvedAnimation(
        parent: _offsetController,
        curve: Curves.easeOut,
      ),
    );

    _opacityController =
        AnimationController(vsync: this, duration: Duration.zero);
    _opacityTween = Tween<double>(begin: 1.0, end: 0.0);
    _opacityAnimation = _opacityTween.animate(_opacityController);

    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _offsetController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  // void _onScaleStateChanged(PhotoViewScaleState scaleState) {
  //   setState(() => _isLocked = scaleState != PhotoViewScaleState.initial);
  // }

  void _onPageChanged(int index) {
    setState(() => _currentPageIndex =
        mapToRange(index, 0, widget.imageProviders.length - 1));
  }

  void _onDragStart(DragStartDetails details) {
    _start = details.globalPosition.dy;

    setState(() => _isDragging = true);
  }

  void _onDragEnd(double velocity) {
    _start = 0.0;

    if (velocity > _kMaxDragSpeed ||
        _offsetTween.end!.dy >= MediaQuery.of(context).size.height / 2) {
      Navigator.of(context).pop();
    } else {
      _opacityTween.begin = _opacityTween.end;
      _opacityTween.end = 1.0;
      _opacityController.duration = const Duration(milliseconds: 200);
      _opacityController.reset();
      _opacityController.forward();

      _offsetTween.begin = Offset(0, _offsetTween.end!.dy);
      _offsetTween.end = Offset.zero;
      _offsetController.duration = const Duration(milliseconds: 200);
      _offsetController.reset();
      _offsetController.forward();
    }

    setState(() => _isDragging = false);
  }

  void _onDrag(double dy) {
    if (dy < 0) {
      return;
    }
    _offsetTween.begin = Offset.zero;
    _offsetTween.end = Offset(0, dy);

    _offsetController.duration = Duration.zero;
    _offsetController.reset();
    _offsetController.forward();

    _opacityTween.begin = _opacityTween.end;
    _opacityTween.end =
        mapValue(dy, 0, MediaQuery.of(context).size.height, 1.0, 0.0);
    _opacityController.duration = Duration.zero;
    _opacityController.reset();
    _opacityController.forward();
  }

  Widget _buildPage(_, int index) {
    final idx = mapToRange(index, 0, widget.imageProviders.length - 1);
    final ImageProvider provider = widget.imageProviders[idx];

    return ZoomableImage(
      imageProvider: provider,
      // onScaleStateChanged: _onScaleStateChanged,
    );
  }

  Widget _wrapWithCloseGesture({required Widget child}) {
    return GestureDetector(
      onVerticalDragStart: _isLocked ? null : _onDragStart,
      onVerticalDragUpdate: _isLocked
          ? null
          : (details) {
              _onDrag(details.globalPosition.dy - _start);
            },
      onVerticalDragCancel: _isLocked ? null : () => _onDragEnd(0.0),
      onVerticalDragEnd: _isLocked
          ? null
          : (details) {
              _onDragEnd(details.velocity.pixelsPerSecond.dy);
            },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      itemBuilder: _buildPage,
      physics: _isLocked || widget.imageProviders.length <= 1
          ? const NeverScrollableScrollPhysics()
          : null,
      controller: _pageController,
      onPageChanged: _onPageChanged,
    );

    return OffsetTransition(
      offset: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black,
          navigationBar: CupertinoNavigationBar(
            automaticallyImplyLeading: false,
            backgroundColor: kTranslucentBlackColor,
            middle: widget.imageProviders.length > 1
                ? AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isDragging ? 0.0 : 1.0,
                    child: Text(
                      '${_currentPageIndex + 1} of ${widget.imageProviders.length}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                      ),
                    ),
                  )
                : null,
            leading: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isDragging ? 0.0 : 1.0,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17.0,
                  ),
                ),
              ),
            ),
          ),
          child: SafeArea(
            child: _wrapWithCloseGesture(child: pageView),
          ),
        ),
      ),
    );
  }
}

class ZoomableImage extends StatefulWidget {
  const ZoomableImage({
    super.key,
    required this.imageProvider,
    // this.onScaleStateChanged,
  });

  final ImageProvider imageProvider;

  // final PhotoViewScaleStateChangedCallback onScaleStateChanged;

  @override
  // ignore: library_private_types_in_public_api
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  final _controller = PhotoViewScaleStateController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: widget.imageProvider,
      // loadingChild: Center(
      //   child: CupertinoActivityIndicator(),
      // ),
      enableRotation: false,
      initialScale: PhotoViewComputedScale.contained,
      minScale: PhotoViewComputedScale.contained,
      maxScale: 5.0,
      scaleStateController: _controller,
      scaleStateChangedCallback: (s) {
        // if (widget.onScaleStateChanged != null) {
        //   widget.onScaleStateChanged(s);
        // }
        if (s == PhotoViewScaleState.originalSize) {
          _controller.setInvisibly(PhotoViewScaleState.initial);
        }
      },
    );
  }
}

double mapValue(
    double value, double low1, double high1, double low2, double high2) {
  return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
}

int mapToRange(int value, int low, int high) {
  assert(low <= high);
  if (value >= low && value <= high) {
    return value;
  }

  int len = high - low + 1;
  return value % len;
}

class OffsetTransition extends AnimatedWidget {
  const OffsetTransition({
    super.key,
    required Animation<Offset> offset,
    required this.child,
  }) : super(listenable: offset);

  final Widget child;

  Listenable get offset => listenable;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: (listenable as Animation<Offset>).value,
      child: child,
    );
  }
}
