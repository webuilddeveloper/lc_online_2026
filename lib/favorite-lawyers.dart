import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/services/favorite_lawyer_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';

class FavoriteLawyersPage extends StatefulWidget {
  const FavoriteLawyersPage({super.key});

  @override
  State<FavoriteLawyersPage> createState() => _FavoriteLawyersPageState();
}

class _FavoriteLawyersPageState extends State<FavoriteLawyersPage> {
  List<Map<String, dynamic>> favoriteLawyers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final list = await FavoriteLawyerService.loadFavorites();
    if (!mounted) return;
    setState(() {
      favoriteLawyers = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFE9F2F9) : const Color(0xFFEEF2F5),
      appBar: isDesktop
          ? null
          : appBar(
              title: 'favoriteLawyers'.tr(),
              backBtn: true,
              rightBtn: false,
              backAction: () => goBack(),
              rightAction: () {},
            ),
      body: AppLayout(
        child: Container(
          decoration: isDesktop
              ? BoxDecoration(
                  color: const Color(0xFFEEF2F5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                )
              : null,
          child: Column(
            children: [
              if (isDesktop)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => goBack(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 1, color: const Color(0xFFDBDBDB)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'favoriteLawyers'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (favoriteLawyers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'favoriteLawyersEmpty'.tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        itemCount: favoriteLawyers.length,
        itemBuilder: (context, index) =>
            _favoriteItem(favoriteLawyers[index], onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LawyerOnlineDetails(code: favoriteLawyers[index]['code']),
            ),
          );
        }),
        separatorBuilder: (context, index) => const SizedBox(height: 15),
      ),
    );
  }

  Widget _favoriteItem(Map<String, dynamic> model, {VoidCallback? onTap}) {
    final imageUrl = model['imageUrl']?.toString() ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 55,
                        width: 55,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.asset(
                          'assets/images/lawyer-avatar-1.png',
                          height: 55,
                          width: 55,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        imageUrl.isNotEmpty
                            ? imageUrl
                            : 'assets/images/lawyer-avatar-1.png',
                        height: 55,
                        width: 55,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model['name']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      model['category']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 109, 109, 111),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          model['rating']?.toString() ?? '0',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${model['reviews'] ?? '0'})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 109, 109, 111),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      model['experience']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 109, 109, 111),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: model['status'] == 'online'
                              ? const Color(0xFF34C759)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        model['status'] == 'online'
                            ? 'online'.tr()
                            : 'offline'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}
