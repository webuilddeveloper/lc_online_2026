import 'package:LawyerOnline/models/lawyer/lawyer_model.dart';

abstract class LawyerRepository {
  Future<List<LawyerModel>> searchLawyers({
    String topic = '',
    String subTopic = '',
    String province = '',
    String keyword = '',
    bool availableOnly = false,
  });
}

class ApiLawyerRepository implements LawyerRepository {
  const ApiLawyerRepository();

  @override
  Future<List<LawyerModel>> searchLawyers({
    String topic = '',
    String subTopic = '',
    String province = '',
    String keyword = '',
    bool availableOnly = false,
  }) {
    // TODO: Wire this once the team confirms the lawyer search endpoint.
    throw UnimplementedError('Lawyer search API contract is not ready yet.');
  }
}
