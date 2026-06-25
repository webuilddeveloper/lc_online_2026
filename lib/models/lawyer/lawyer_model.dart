class LawyerModel {
  const LawyerModel({
    required this.code,
    required this.name,
    required this.title,
    required this.specialty,
    required this.experience,
    required this.experienceYears,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.isOnline,
    required this.province,
    this.distance = '',
    this.distanceKm = 0,
    this.eta = '',
    this.office = '',
    this.avatar = '',
    this.color = 0xFF0262EC,
    this.imageUrl = '',
  });

  final String code;
  final String name;
  final String title;
  final String specialty;
  final String experience;
  final int experienceYears;
  final double rating;
  final int reviews;
  final int price;
  final bool isOnline;
  final String province;
  final String distance;
  final double distanceKm;
  final String eta;
  final String office;
  final String avatar;
  final int color;
  final String imageUrl;

  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      code: _string(json['code'] ?? json['id']),
      name: _string(json['name'] ?? json['fullName']),
      title: _string(json['title']),
      specialty: _string(json['specialty']),
      experience: _string(json['experience']),
      experienceYears: _int(json['experienceYears']),
      rating: _double(json['rating']),
      reviews: _int(json['reviews']),
      price: _int(json['price']),
      isOnline: json['isOnline'] == true,
      province: _string(json['province']),
      distance: _string(json['distance']),
      distanceKm: _double(json['distanceKm']),
      eta: _string(json['eta']),
      office: _string(json['office']),
      avatar: _string(json['avatar']),
      color: _int(json['color'], fallback: 0xFF0262EC),
      imageUrl: _string(json['imageUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'title': title,
        'specialty': specialty,
        'experience': experience,
        'experienceYears': experienceYears,
        'rating': rating,
        'reviews': reviews,
        'price': price,
        'isOnline': isOnline,
        'province': province,
        'distance': distance,
        'distanceKm': distanceKm,
        'eta': eta,
        'office': office,
        'avatar': avatar,
        'color': color,
        'imageUrl': imageUrl,
      };

  // Map<String, dynamic> toLegacyMap() => toJson();

  Map<String, dynamic> toLegacyMap() {
    return {
      'code': code,
      'name': name,
      'title': title,
      'specialty': specialty,
      'experience': experience,
      'experienceYears': experienceYears,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'province': province,
      'distance': distance,
      'distanceKm': distanceKm,
      'eta': eta,
      'office': office,
      'avatar': avatar,
      'color': color,
      'imageUrl': imageUrl,
      'available': isOnline, // ✅ แปลง isOnline → available
      'isOnline': isOnline,
      // ... field อื่นๆ
    };
  }

  static String _string(dynamic value) => value?.toString() ?? '';

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _double(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
