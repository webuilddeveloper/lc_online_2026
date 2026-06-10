import 'package:LawyerOnline/models/location/province_model.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

abstract class ProvinceRepository {
  Future<List<ProvinceModel>> readProvinces();
}

class ProvinceRepositoryException implements Exception {
  const ProvinceRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiProvinceRepository implements ProvinceRepository {
  const ApiProvinceRepository();

  @override
  Future<List<ProvinceModel>> readProvinces() async {
    final result = await postDio('${server}route/province/read', {});
    if (result['objectData'] is! List) {
      throw const ProvinceRepositoryException('Invalid province response');
    }

    return result['objectData']
        .whereType<Map>()
        .map((item) => ProvinceModel.fromJson(Map<String, dynamic>.from(item)))
        .where((province) => province.title.isNotEmpty)
        .toList();
  }
}
