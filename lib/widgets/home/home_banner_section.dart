import 'dart:async';

import 'package:LawyerOnline/carousel_form.dart';
import 'package:LawyerOnline/component/comming-soon.dart';
import 'package:LawyerOnline/component/link_url_in.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'package:LawyerOnline/widgets/home/home_theme.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          height: RV.bannerHeight(context),
          decoration: BoxDecoration(
            borderRadius: HomeTheme.brCardLg,
            color: Colors.grey.shade200,
          ),
          child: const Center(
            child: AppRingSpinner(color: HomeTheme.primary, size: 36),
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
              viewportFraction: 0.92,
              aspectRatio: 2.4,
              enlargeCenterPage: true,
              enlargeFactor: 0.22,
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
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: HomeTheme.brCardLg,
                    boxShadow: HomeTheme.softShadow(tint: HomeTheme.primary, y: 12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isNetwork
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEEF2F5),
                          ),
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [HomeTheme.primary, HomeTheme.accent],
                      )
                    : null,
                color: active ? null : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}
