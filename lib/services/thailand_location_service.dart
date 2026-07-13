import 'package:LawyerOnline/models/location/province_model.dart';
import 'package:LawyerOnline/repositories/province_repository.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

class DistrictModel {
  const DistrictModel({
    required this.code,
    required this.title,
    required this.provinceCode,
  });

  final String code;
  final String title;
  final String provinceCode;

  factory DistrictModel.fromJson(Map<String, dynamic> json) => DistrictModel(
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? json['name']?.toString() ?? '',
        provinceCode: json['provinceCode']?.toString() ?? '',
      );
}

/// โหลดจังหวัด 77 จังหวัด + อำเภอ (ถ้า API รองรับ)
class ThailandLocationService {
  ThailandLocationService._();

  static final _provinceRepo = const ApiProvinceRepository();
  static List<ProvinceModel>? _provinceCache;

  static Future<List<ProvinceModel>> provinces() async {
    if (_provinceCache != null && _provinceCache!.isNotEmpty) {
      return _provinceCache!;
    }
    try {
      _provinceCache = await _provinceRepo.readProvinces();
      if (_provinceCache!.isNotEmpty) return _provinceCache!;
    } catch (_) {}

    try {
      final result = await postDio('${serverLC}route/province/read', {});
      final list = (result['objectData'] as List?) ?? [];
      _provinceCache = list
          .whereType<Map>()
          .map((e) => ProvinceModel.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.title.isNotEmpty)
          .toList();
    } catch (_) {
      _provinceCache = [];
    }
    return _provinceCache!;
  }

  static Future<List<DistrictModel>> districts(String provinceCode) async {
    if (provinceCode.isEmpty || provinceCode == '0') return [];
    try {
      final result = await postDio('${serverLC}route/district/read', {
        'provinceCode': provinceCode,
      });
      final list = (result['objectData'] as List?) ?? [];
      return list
          .whereType<Map>()
          .map((e) => DistrictModel.fromJson(Map<String, dynamic>.from(e)))
          .where((d) => d.title.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void clearCache() => _provinceCache = null;
}
