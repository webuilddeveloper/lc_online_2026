class UserModel {
  final String code;
  final String userType;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String imageUrl;
  final String category;
  final bool isActive;
  final String status;
  final String lawyerApplyStatus;
  final String prefixName;
  final String facebookID;
  final String googleID;
  final String lineID;
  final String line;
  final String sex;
  final String address;
  final String idcard;
  final double lastLat;
  final double lastLong;
  final String title;
  final String description;
  final List<String> expertiseList;
  final List<Map<String, dynamic>> expertiseData;
  final String province;
  final String provinceCode;
  final double experienceYears;
  final String isAvailable;
  final bool isAllowCase;
  final String lv0;
  final String lv1;
  final String lv2;
  final String lv3;
  final bool isPro;
  final DateTime? proTrialEndDate;
  final String proBillingCycle;
  final String urgentCaseScope;

  const UserModel({
    required this.code,
    required this.userType,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.category,
    required this.isActive,
    required this.status,
    this.lawyerApplyStatus = '',
    required this.prefixName,
    required this.facebookID,
    required this.googleID,
    required this.lineID,
    required this.line,
    required this.sex,
    required this.address,
    required this.idcard,
    required this.lastLat,
    required this.lastLong,
    this.title = '',
    this.description = '',
    this.expertiseList = const [],
    this.expertiseData = const [],
    this.province = '',
    this.provinceCode = '',
    this.experienceYears = 0,
    this.isAvailable = 'T',
    this.isAllowCase = false,
    this.lv0 = '',
    this.lv1 = '',
    this.lv2 = '',
    this.lv3 = '',
    this.isPro = false,
    this.proTrialEndDate,
    this.proBillingCycle = '',
    this.urgentCaseScope = 'expertise',
  });

  static double _parseDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  static List<Map<String, dynamic>> _parseExpertiseData(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static String _parseUrgentCaseScope(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    return value == 'all' ? 'all' : 'expertise';
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  factory UserModel.fromJson(dynamic json) {
    return UserModel(
      code: json['code']?.toString() ?? '',
      userType: json['userType']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isActive:
          json['isActive'] == true || json['isActive']?.toString() == 'true',
      status: json['status']?.toString() ?? '',
      lawyerApplyStatus: json['lawyerApplyStatus']?.toString() ?? '',
      prefixName: json['prefixName']?.toString() ?? '',
      facebookID: json['facebookID']?.toString() ?? '',
      googleID: json['googleID']?.toString() ?? '',
      lineID: json['lineID']?.toString() ?? '',
      line: json['line']?.toString() ?? '',
      sex: json['sex']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      idcard: json['idcard']?.toString() ?? '',
      lastLat: _parseDouble(json['lastLat']),
      lastLong: _parseDouble(json['lastLong']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      expertiseList: _parseStringList(json['expertiseList']),
      expertiseData: _parseExpertiseData(json['expertiseData']),
      province: json['province']?.toString() ?? '',
      provinceCode: json['provinceCode']?.toString() ?? '',
      experienceYears: _parseDouble(json['experienceYears']),
      isAvailable: json['isAvailable']?.toString().isNotEmpty == true
          ? json['isAvailable'].toString()
          : 'T',
      isAllowCase: json['isAllowCase'] == true ||
          json['isAllowCase']?.toString() == 'true',
      lv0: json['lv0']?.toString() ?? '',
      lv1: json['lv1']?.toString() ?? '',
      lv2: json['lv2']?.toString() ?? '',
      lv3: json['lv3']?.toString() ?? '',
      isPro: json['isPro'] == true || json['isPro']?.toString() == 'true',
      proTrialEndDate: _parseDateTime(json['proTrialEndDate']),
      proBillingCycle: json['proBillingCycle']?.toString() ?? '',
      urgentCaseScope: _parseUrgentCaseScope(json['urgentCaseScope']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'userType': userType,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'status': status,
      'lawyerApplyStatus': lawyerApplyStatus,
      'prefixName': prefixName,
      'facebookID': facebookID,
      'googleID': googleID,
      'lineID': lineID,
      'line': line,
      'sex': sex,
      'address': address,
      'idcard': idcard,
      'lastLat': lastLat,
      'lastLong': lastLong,
      'title': title,
      'description': description,
      'expertiseList': expertiseList,
      'province': province,
      'provinceCode': provinceCode,
      'experienceYears': experienceYears,
      'isAvailable': isAvailable,
      'isAllowCase': isAllowCase,
      'lv0': lv0,
      'lv1': lv1,
      'lv2': lv2,
      'lv3': lv3,
      'isPro': isPro,
      if (proTrialEndDate != null)
        'proTrialEndDate': proTrialEndDate!.toIso8601String(),
      'proBillingCycle': proBillingCycle,
      'urgentCaseScope': urgentCaseScope,
    };
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) {
      return email;
    }
    return [prefixName, firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  UserModel copyWith({
    String? code,
    String? userType,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? imageUrl,
    String? category,
    bool? isActive,
    String? status,
    String? lawyerApplyStatus,
    String? prefixName,
    String? facebookID,
    String? googleID,
    String? lineID,
    String? line,
    String? sex,
    String? address,
    String? idcard,
    double? lastLat,
    double? lastLong,
    String? title,
    String? description,
    List<String>? expertiseList,
    List<Map<String, dynamic>>? expertiseData,
    String? province,
    String? provinceCode,
    double? experienceYears,
    String? isAvailable,
    bool? isAllowCase,
    String? lv0,
    String? lv1,
    String? lv2,
    String? lv3,
    bool? isPro,
    DateTime? proTrialEndDate,
    String? proBillingCycle,
    String? urgentCaseScope,
  }) {
    return UserModel(
      code: code ?? this.code,
      userType: userType ?? this.userType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      lawyerApplyStatus: lawyerApplyStatus ?? this.lawyerApplyStatus,
      prefixName: prefixName ?? this.prefixName,
      facebookID: facebookID ?? this.facebookID,
      googleID: googleID ?? this.googleID,
      lineID: lineID ?? this.lineID,
      line: line ?? this.line,
      sex: sex ?? this.sex,
      address: address ?? this.address,
      idcard: idcard ?? this.idcard,
      lastLat: lastLat ?? this.lastLat,
      lastLong: lastLong ?? this.lastLong,
      title: title ?? this.title,
      description: description ?? this.description,
      expertiseList: expertiseList ?? this.expertiseList,
      expertiseData: expertiseData ?? this.expertiseData,
      province: province ?? this.province,
      provinceCode: provinceCode ?? this.provinceCode,
      experienceYears: experienceYears ?? this.experienceYears,
      isAvailable: isAvailable ?? this.isAvailable,
      isAllowCase: isAllowCase ?? this.isAllowCase,
      lv0: lv0 ?? this.lv0,
      lv1: lv1 ?? this.lv1,
      lv2: lv2 ?? this.lv2,
      lv3: lv3 ?? this.lv3,
      isPro: isPro ?? this.isPro,
      proTrialEndDate: proTrialEndDate ?? this.proTrialEndDate,
      proBillingCycle: proBillingCycle ?? this.proBillingCycle,
      urgentCaseScope: urgentCaseScope ?? this.urgentCaseScope,
    );
  }
}
