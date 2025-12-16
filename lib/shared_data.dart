import 'package:flutter/material.dart';

class SharedAppointment {
  final DateTime startTime;
  final Duration duration;
  final String clientName;
  final String serviceName;
  final String staffName;
  final String status;
  final bool isWebBooking;

  SharedAppointment({
    required this.startTime,
    required this.duration,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
    this.status = 'New',
    this.isWebBooking = false,
  });

  DateTime get endTime => startTime.add(duration);
}

class SharedStaffMember {
  final String name;
  final String role;
  final String availability;

  SharedStaffMember({
    required this.name,
    required this.role,
    required this.availability,
  });
}

class SharedDataService extends ChangeNotifier {
  // Shared staff data
  final List<SharedStaffMember> staffMembers = [
    SharedStaffMember(
      name: 'HarshalSpa PRO',
      role: 'Senior Stylist',
      availability: '9:00 AM - 8:00 PM',
    ),
    SharedStaffMember(
      name: 'Shivani Deshmukh',
      role: 'Beautician',
      availability: '10:00 AM - 7:00 PM',
    ),
    SharedStaffMember(
      name: 'Siddhi Shinde',
      role: 'Barber',
      availability: 'Full Day',
    ),
    SharedStaffMember(
      name: 'Juili Ware',
      role: 'Nail Technician',
      availability: '9:00 AM - 6:00 PM',
    ),
  ];

  // Shared appointment data
  final List<SharedAppointment> appointments = [
    // Today
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 10, 30),
      duration: const Duration(minutes: 30),
      clientName: 'Rahul Sharma',
      serviceName: 'Haircut',
      staffName: 'HarshalSpa PRO',
      status: 'Confirmed',
      isWebBooking: true,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 13, 0),
      duration: const Duration(minutes: 90),
      clientName: 'Priya Patel',
      serviceName: 'Keratin Treatment',
      staffName: 'HarshalSpa PRO',
      status: 'Confirmed',
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 10, 0),
      duration: const Duration(minutes: 60),
      clientName: 'Anjali Verma',
      serviceName: 'Facial',
      staffName: 'Shivani Deshmukh',
      status: 'Confirmed',
      isWebBooking: true,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 11, 30),
      duration: const Duration(minutes: 45),
      clientName: 'Vikram Singh',
      serviceName: 'Nail Art',
      staffName: 'Shivani Deshmukh',
      status: 'Confirmed',
      isWebBooking: true,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 14, 0),
      duration: const Duration(minutes: 75),
      clientName: 'Kavita Reddy',
      serviceName: 'Cleanup + Threading',
      staffName: 'Shivani Deshmukh',
      status: 'Pending',
      isWebBooking: true,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 9, 45),
      duration: const Duration(minutes: 40),
      clientName: 'Arjun Mehta',
      serviceName: 'Beard Trim + Haircut',
      staffName: 'Siddhi Shinde',
      status: 'Confirmed',
      isWebBooking: false,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 12, 0),
      duration: const Duration(minutes: 30),
      clientName: 'Rohan Joshi',
      serviceName: 'Classic Shave',
      staffName: 'Siddhi Shinde',
      status: 'Confirmed',
      isWebBooking: true,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 15, 30),
      duration: const Duration(minutes: 50),
      clientName: 'Siddharth Rao',
      serviceName: 'Hair Color (Roots)',
      staffName: 'Siddhi Shinde',
      status: 'Confirmed',
      isWebBooking: false,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 11, 0),
      duration: const Duration(minutes: 60),
      clientName: 'Riya Kapoor',
      serviceName: 'Gel Nail Extension',
      staffName: 'Juili Ware',
      status: 'Confirmed',
      isWebBooking: true,
    ),
    SharedAppointment(
      startTime: DateTime(2025, 12, 16, 13, 30),
      duration: const Duration(minutes: 45),
      clientName: 'Sneha Verma',
      serviceName: 'Manicure + Pedicure',
      staffName: 'Juili Ware',
      status: 'Confirmed',
      isWebBooking: true,
    ),
  ];

  // Methods to convert shared data to dashboard format
  List<Map<String, dynamic>> getDashboardAppointments() {
    return appointments.map((appointment) {
      final timeFormat = TimeOfDay.fromDateTime(appointment.startTime);
      final hour = timeFormat.hourOfPeriod == 0 ? 12 : timeFormat.hourOfPeriod;
      final period = timeFormat.period == DayPeriod.am ? 'AM' : 'PM';
      final minutes = timeFormat.minute.toString().padLeft(2, '0');
      
      return {
        'date': '${appointment.startTime.day}',
        'month': _getMonthAbbreviation(appointment.startTime.month),
        'time': '${_getDayAbbreviation(appointment.startTime.weekday)} $hour:$minutes$period',
        'service': appointment.serviceName,
        'client': appointment.clientName,
        'duration': '${appointment.duration.inMinutes}min',
        'staff': appointment.staffName,
        'price': _getServicePrice(appointment.serviceName),
      };
    }).toList();
  }

  List<Map<String, dynamic>> getDashboardStaffList() {
    return staffMembers.map((staff) {
      final staffAppointments = appointments.where((appt) => appt.staffName == staff.name).toList();
      final totalSales = staffAppointments.fold<int>(0, (sum, appt) => sum + _getServicePrice(appt.serviceName));
      final commission = (totalSales * 0.1).round(); // 10% commission
      
      return {
        'name': staff.name,
        'appointments': staffAppointments.length,
        'sales': totalSales,
        'commission': commission,
      };
    }).toList();
  }

  String _getMonthAbbreviation(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  String _getDayAbbreviation(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  int _getServicePrice(String serviceName) {
    // Simplified pricing logic - in a real app this would come from a service/pricing database
    switch (serviceName) {
      case 'Haircut':
        return 250;
      case 'Keratin Treatment':
        return 2500;
      case 'Facial':
        return 600;
      case 'Nail Art':
        return 400;
      case 'Cleanup + Threading':
        return 500;
      case 'Beard Trim + Haircut':
        return 300;
      case 'Classic Shave':
        return 150;
      case 'Hair Color (Roots)':
        return 800;
      case 'Gel Nail Extension':
        return 700;
      case 'Manicure + Pedicure':
        return 600;
      default:
        return 300;
    }
  }
}

// Singleton instance for easy access
final sharedDataService = SharedDataService();