import 'package:LawyerOnline/repositories/booking_case_repository.dart';
import 'package:LawyerOnline/repositories/lawyer_repository.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';

abstract class LawyerAppointmentRepository {
  Future<List<Map<String, dynamic>>> readAppointmentsForLawyer(
    String lawyerCode,
  );

  Future<LawyerScheduleSnapshot> readScheduleForLawyer(String lawyerCode);
}

class LawyerScheduleSnapshot {
  const LawyerScheduleSnapshot({
    required this.appointments,
    required this.bookingJobs,
  });

  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> bookingJobs;
}

class ApiLawyerAppointmentRepository implements LawyerAppointmentRepository {
  const ApiLawyerAppointmentRepository({
    BookingCaseRepository caseRepository = const ApiBookingCaseRepository(),
  }) : _caseRepository = caseRepository;

  final BookingCaseRepository _caseRepository;

  @override
  Future<List<Map<String, dynamic>>> readAppointmentsForLawyer(
    String lawyerCode,
  ) async {
    debugPrint('📥 readAppointmentsForLawyer: $lawyerCode');
    
    if (lawyerCode.trim().isEmpty) {
      debugPrint('⚠️ lawyerCode is empty');
      return [];
    }

    try {
      final snapshot = await readScheduleForLawyer(lawyerCode);
      debugPrint('✅ Got ${snapshot.appointments.length} appointments');
      return snapshot.appointments;
    } catch (e) {
      debugPrint('❌ readAppointmentsForLawyer error: $e');
      rethrow;
    }
  }

  @override
  Future<LawyerScheduleSnapshot> readScheduleForLawyer(
    String lawyerCode,
  ) async {
    final code = lawyerCode.trim();
    
    debugPrint('📥 readScheduleForLawyer: $code');
    
    if (code.isEmpty) {
      debugPrint('⚠️ lawyerCode is empty');
      return const LawyerScheduleSnapshot(
        appointments: [],
        bookingJobs: [],
      );
    }

    try {
      final cases = await _caseRepository.readCases(lawyerCode: code);
      debugPrint('✅ Got ${cases.length} cases from API');

      final appointments = <Map<String, dynamic>>[];
      for (var i = 0; i < cases.length; i++) {
        try {
          final apt = CaseAppointmentMapper.fromCase(
            cases[i] as Map<String, dynamic>,
            colorIndex: i % 6,
          );
          appointments.add(apt);
          debugPrint('✅ Mapped appointment $i: ${apt['code']}');
        } catch (e) {
          debugPrint('⚠️ Error mapping case $i: $e');
          continue;
        }
      }

      debugPrint('✅ Final appointments: ${appointments.length}');
      
      return LawyerScheduleSnapshot(
        appointments: appointments,
        bookingJobs: [],
      );
    } catch (e, st) {
      debugPrint('❌ readScheduleForLawyer error: $e');
      debugPrint('📍 stacktrace: $st');
      rethrow;
    }
  }
}