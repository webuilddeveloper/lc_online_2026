import 'dart:async';

import 'package:LawyerOnline/carousel_form.dart';
import 'package:LawyerOnline/component/comming-soon.dart';
import 'package:LawyerOnline/component/link_url_in.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

const _kAccent = Color(0xFF2F80ED);

// ─── Banner Section ───────────────────────────────────────────────
// StatefulWidget ของตัวเอง → _currentBanner state อยู่ที่นี่
// กด dot หรือ scroll banner ไม่ rebuild หน้า home เลย
class HomeBannerSection extends StatefulWidget {
  final List<dynamic> banners;
  final bool autoPlayEnabled;
  const HomeBannerSection({
    super.key,
    required this.banners,
    this.autoPlayEnabled = true,
  });

  @override
  State<HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<HomeBannerSection> {
  static const _autoPlayInterval = Duration(seconds: 4);
  static const _autoPlayAnimationDuration = Duration(milliseconds: 800);

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  Timer? _autoPlayTimer;
  ModalRoute<dynamic>? _route;
  bool _autoPlayAnimating = false;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restartAutoPlayTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(covariant HomeBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlayEnabled != widget.autoPlayEnabled) {
      if (widget.autoPlayEnabled) {
        _restartAutoPlayTimer();
      } else {
        _stopAutoPlayTimer();
      }
    }
    if (!identical(oldWidget.banners, widget.banners) ||
        oldWidget.banners.length != widget.banners.length) {
      if (_current >= widget.banners.length) {
        _current = widget.banners.isEmpty ? 0 : widget.banners.length - 1;
      }
      _restartAutoPlayTimer();
    }
  }

  @override
  void dispose() {
    _stopAutoPlayTimer();
    super.dispose();
  }

  void _restartAutoPlayTimer() {
    _stopAutoPlayTimer();
    if (!widget.autoPlayEnabled || widget.banners.length <= 1) return;

    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      unawaited(_advanceBanner());
    });
  }

  void _stopAutoPlayTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  Future<void> _advanceBanner() async {
    if (!mounted || !widget.autoPlayEnabled || _autoPlayAnimating || !_carouselController.ready) {
      return;
    }
    if (_route?.isCurrent == false) return;

    _autoPlayAnimating = true;
    try {
      await _carouselController.nextPage(
        duration: _autoPlayAnimationDuration,
        curve: Curves.fastOutSlowIn,
      );
    } catch (_) {
      // The carousel may be disposed while an autoplay frame is in flight.
    } finally {
      _autoPlayAnimating = false;
    }
  }

  void _onBannerTap(dynamic item) {
    if (item['action'] == 'out') {
      launchInWebViewWithJavaScript(item['path']);
    } else if (item['action'] == 'in') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarouselForm(
            code: item['code'],
            model: item,
            url: mainBannerApi,
            urlGallery: bannerGalleryApi,
          ),
        ),
      );
    } else if ((item['action'] as String? ?? '').toUpperCase() == 'P') {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ComingSoonPage(
            title: 'Comming Soon',
            lottieUrl:
                'https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Container(
          height: RV.bannerHeight(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
          ),
          child: const Center(
            child: AppRingSpinner(color: _kAccent, size: 36),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: RV.bannerHeight(context),
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              viewportFraction: 0.9,
              aspectRatio: 3,
              enlargeCenterPage: true,
              enlargeFactor: 0.32,
              autoPlay: false,
              autoPlayInterval: _autoPlayInterval,
              autoPlayAnimationDuration: _autoPlayAnimationDuration,
              pauseAutoPlayOnManualNavigate: false,
              onPageChanged: (index, _) {
                if (!mounted) return;
                setState(() => _current = index);
              },
            ),
            items: widget.banners.map((item) {
              final imageUrl = item['imageUrl']?.toString() ?? '';
              final isNetwork = imageUrl.startsWith('http');
              return GestureDetector(
                onTap: () => _onBannerTap(item),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: isNetwork ? NetworkImage(imageUrl) : AssetImage(imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(133, 55, 55, 55)
                            .withValues(alpha: 0.5),
                        BlendMode.srcATop,
                      ),
                    ),
                  ),
                  child: isNetwork
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEEF2F5),
                          ),
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // ── dot indicators ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _kAccent : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
