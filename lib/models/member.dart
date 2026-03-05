import 'package:cloud_firestore/cloud_firestore.dart';

/// Member model representing a gym member in the system
class Member {
  final String? id;
  final String name;
  final String phone;
  final double amount;
  final DateTime joinDate;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;

  Member({
    this.id,
    required this.name,
    required this.phone,
    required this.amount,
    required this.joinDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  /// Create Member from Firestore document
  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      joinDate: (data['joinDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'inactive',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert Member to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'amount': amount,
      'joinDate': Timestamp.fromDate(joinDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert Member to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'amount': amount,
      'joinDate': joinDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
