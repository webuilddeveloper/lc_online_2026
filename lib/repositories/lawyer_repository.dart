import 'package:LawyerOnline/models/lawyer/lawyer_model.dart';
import 'package:LawyerOnline/models/user_model.dart';
import 'package:LawyerOnline/repositories/register_account_repository.dart';

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
  const ApiLawyerRepository({
    RegisterAccountRepository accountRepository =
        const ApiRegisterAccountRepository(),
  }) : _accountRepository = accountRepository;

  final RegisterAccountRepository _accountRepository;

  @override
  Future<List<LawyerModel>> searchLawyers({
    String topic = '',
    String subTopic = '',
    String province = '',
    String keyword = '',
    bool availableOnly = false,
  }) async {
    final accounts = await _accountRepository.readAccounts(
      userType: 'lawyer',
      keySearch: keyword,
      limit: 100,
    );

    final normalizedKeyword = keyword.trim().toLowerCase();
    final normalizedProvince = province.trim().toLowerCase();
    return accounts
        .where((account) => account.code.trim().isNotEmpty)
        .map(_lawyerFromAccount)
        .where((lawyer) {
      if (availableOnly && !lawyer.isOnline) {
        return false;
      }
      if (normalizedProvince.isNotEmpty &&
          lawyer.province.toLowerCase() != normalizedProvince) {
        return false;
      }

      final searchText = [
        lawyer.name,
        lawyer.title,
        lawyer.specialty,
        lawyer.province,
      ].join(' ').toLowerCase();

      if (normalizedKeyword.isNotEmpty &&
          !searchText.contains(normalizedKeyword)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  LawyerModel _lawyerFromAccount(UserModel account) {
    final name = account.fullName.trim().isNotEmpty
        ? account.fullName.trim()
        : account.email.trim();
    final specialty =
        account.category.trim().isNotEmpty ? account.category.trim() : '-';
    final avatar = name.trim().isNotEmpty ? name.trim()[0] : 'L';
    final imageUrl = account.imageUrl.trim();

    return LawyerModel(
      code: account.code.trim(),
      name: name,
      title: 'Lawyer',
      specialty: specialty,
      experience: '-',
      experienceYears: 0,
      rating: 0,
      reviews: 0,
      price: 0,
      isOnline: account.isActive || account.status.trim().isEmpty,
      province: account.address.trim(),
      distance: '-',
      distanceKm: 0,
      eta: '-',
      office: account.address.trim(),
      avatar: avatar,
      color: 0xFF0262EC,
      imageUrl: imageUrl.startsWith('assets/')
          ? imageUrl
          : 'assets/images/lawyer-avatar-1.png',
    );
  }
}
