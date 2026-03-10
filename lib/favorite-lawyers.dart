import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class FavoriteLawyersPage extends StatefulWidget {
  const FavoriteLawyersPage({super.key});

  @override
  State<FavoriteLawyersPage> createState() => _FavoriteLawyersPageState();
}

class _FavoriteLawyersPageState extends State<FavoriteLawyersPage> {

  List<dynamic> favoriteLawyers = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      "imageUrl": "assets/images/lawyer-avatar-1.png",
      "category": "กฎหมายครอบครัว",
      "experience": "11+ years",
      "rating": "4.8",
      "reviews": "60+",
      "skills": ["Family lawyer", "Estate planning lawyer"],
      "status": "online",
    },
    {
      "code": "1",
      "name": "ธนากร นิติศักดิ์",
      "imageUrl": "assets/images/lawyer-avatar-2.png",
      "category": "กฎหมายอาญา",
      "experience": "19+ years",
      "rating": "4.1",
      "reviews": "120+",
      "skills": ["Criminal lawyer", "Corporate lawyer"],
      "status": "offline",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "ทนายที่ถูกใจ",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () {},
      ),
      body: Column(
        children: [
          Expanded(child: _buildFavoriteList()),
        ],
      ),
    );
  }

  _buildFavoriteList() {
    return ListView.separated(
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
    );
  }

  _favoriteItem(dynamic model, {Function? onTap}) {
    return GestureDetector(
      onTap: () => onTap!(),
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

              /// Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  model['imageUrl'],
                  height: 55,
                  width: 55,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 15),

              /// Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      model['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      model['category'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 109, 109, 111),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [

                        const Icon(Icons.star,
                            color: Colors.orange, size: 16),

                        const SizedBox(width: 4),

                        Text(
                          model['rating'],
                          style: const TextStyle(fontSize: 12),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          "(${model['reviews']})",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 109, 109, 111),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      model['experience'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 109, 109, 111),
                      ),
                    ),
                  ],
                ),
              ),

              /// Favorite + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),

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
                            ? "ออนไลน์"
                            : "ออฟไลน์",
                        style: const TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                ],
              )
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