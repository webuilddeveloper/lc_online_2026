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
  final String prefixName;
  final String facebookID;
  final String googleID;
  final String lineID;
  final String line;
  final String sex;
  final String address;
  final String idcard;

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
    required this.prefixName,
    required this.facebookID,
    required this.googleID,
    required this.lineID,
    required this.line,
    required this.sex,
    required this.address,
    required this.idcard,
  });

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
      prefixName: json['prefixName']?.toString() ?? '',
      facebookID: json['facebookID']?.toString() ?? '',
      googleID: json['googleID']?.toString() ?? '',
      lineID: json['lineID']?.toString() ?? '',
      line: json['line']?.toString() ?? '',
      sex: json['sex']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      idcard: json['idcard']?.toString() ?? '',
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
      'prefixName': prefixName,
      'facebookID': facebookID,
      'googleID': googleID,
      'lineID': lineID,
      'line': line,
      'sex': sex,
      'address': address,
      'idcard': idcard,
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
    String? prefixName,
    String? facebookID,
    String? googleID,
    String? lineID,
    String? line,
    String? sex,
    String? address,
    String? idcard,
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
      prefixName: prefixName ?? this.prefixName,
      facebookID: facebookID ?? this.facebookID,
      googleID: googleID ?? this.googleID,
      lineID: lineID ?? this.lineID,
      line: line ?? this.line,
      sex: sex ?? this.sex,
      address: address ?? this.address,
      idcard: idcard ?? this.idcard,
    );
  }
}
