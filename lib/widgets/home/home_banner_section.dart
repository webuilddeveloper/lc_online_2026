import 'package:LawyerOnline/carousel_form.dart';
import 'package:LawyerOnline/component/comming-soon.dart';
import 'package:LawyerOnline/component/link_url_in.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

const _kAccent = Color(0xFF2F80ED);

// ─── Banner Section ───────────────────────────────────────────────
// StatefulWidget ของตัวเอง → _currentBanner state อยู่ที่นี่
// กด dot หรือ scroll banner ไม่ rebuild หน้า home เลย
class HomeBannerSection extends StatefulWidget {
  final List<dynamic> banners;
  const HomeBannerSection({super.key, required this.banners});

  @override
  State<HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<HomeBannerSection> {
  int _current = 0;

  void _onBannerTap(dynamic item) {
    if (item['action'] == 'out') {
      launchInWebViewWithJavaScript(item['path']);
    } else if (item['action'] == 'in') {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ComingSoonPage(
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
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _kAccent),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 0.9,
              aspectRatio: 3,
              enlargeCenterPage: true,
              enlargeFactor: 0.32,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, _) =>
                  setState(() => _current = index),
            ),
            items: widget.banners.map((item) {
              return GestureDetector(
                onTap: () => _onBannerTap(item),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(item['imageUrl']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(133, 55, 55, 55)
                            .withOpacity(0.5),
                        BlendMode.srcATop,
                      ),
                    ),
                  ),
                  child: Image.asset(
                    item['imageUrl'],
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