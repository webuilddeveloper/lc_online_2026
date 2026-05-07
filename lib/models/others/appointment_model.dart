class AppointmentModel {
  final String code;
  final String clientName;
  final String caseType;
  final String subCaseType;
  final String appointmentDate;
  final String appointmentTime;
  final String title;
  final String details;
  final String paymentStatus;

  const AppointmentModel({
    required this.code,
    required this.clientName,
    required this.caseType,
    required this.subCaseType,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.title,
    required this.details,
    required this.paymentStatus,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      code: map['code'] ?? '',
      clientName: map['clientName'] ?? '',
      caseType: map['caseType'] ?? '',
      subCaseType: map['subCaseType'] ?? '',
      appointmentDate: map['appointmentDate'] ?? '',
      appointmentTime: map['appointmentTime'] ?? '',
      title: map['title'] ?? '',
      details: map['details'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'clientName': clientName,
        'caseType': caseType,
        'subCaseType': subCaseType,
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'title': title,
        'details': details,
        'paymentStatus': paymentStatus,
      };
}