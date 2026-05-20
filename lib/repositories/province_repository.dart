import 'package:LawyerOnline/models/location/province_model.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

abstract class ProvinceRepository {
  Future<List<ProvinceModel>> readProvinces();
}

class ApiProvinceRepository implements ProvinceRepository {
  const ApiProvinceRepository();

  @override
  Future<List<ProvinceModel>> readProvinces() async {
    final result = await postDio('${server}route/province/read', {});
    if (result is! List) return const [];

    return result
        .whereType<Map>()
        .map((item) => ProvinceModel.fromJson(Map<String, dynamic>.from(item)))
        .where((province) => province.title.isNotEmpty)
        .toList();
  }
}
