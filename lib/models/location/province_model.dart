class ProvinceModel {
  const ProvinceModel({
    required this.code,
    required this.title,
  });

  final String code;
  final String title;

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
      };
}
