import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';
import '../utils/api_response.dart';

/// Backend service for Member Management CRUD operations
/// Handles all database interactions for gym members using Firestore
class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'members';

  /// Calculates due date as exactly one month after join date
  /// 
  /// Handles:
  /// - Leap years (e.g., 2024-01-31 → 2024-02-29)
  /// - February (e.g., 2026-01-31 → 2026-02-28)
  /// - Months with 30 days
  /// - Months with 31 days
  /// 
  /// Business Rule: dueDate = joinDate + 1 month
  DateTime _calculateDueDate(DateTime joinDate) {
    // Add one month to the join date
    int year = joinDate.year;
    int month = joinDate.month + 1;
    int day = joinDate.day;

    // Handle year rollover (December → January)
    if (month > 12) {
      month = 1;
      year++;
    }

    // Handle day overflow for months with fewer days
    // Get the last day of the target month
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    
    // If the join date's day exceeds the target month's days, use the last day
    if (day > lastDayOfMonth) {
      day = lastDayOfMonth;
    }

    final dueDate = DateTime(year, month, day);
    
    print('📅 [MemberService] Due date calculated: ${joinDate.toString().split(' ')[0]} → ${dueDate.toString().split(' ')[0]}');
    
    return dueDate;
  }

  /// Validates member data before database operations
  String? _validateMemberData({
    required String name,
    required String phone,
    required double amount,
    required DateTime joinDate,
    required String status,
  }) {
    if (name.trim().isEmpty) {
      return 'Name cannot be empty';
    }

    if (phone.trim().isEmpty) {
      return 'Phone cannot be empty';
    }

    if (amount < 0) {
      return 'Amount must be a positive number';
    }

    if (status != 'active' && status != 'inactive') {
      return 'Status must be either "active" or "inactive"';
    }

    return null;
  }

  /// POST /members - Create a new member
  /// 
  /// Creates a new member document in the Firestore "members" collection
  /// The dueDate is automatically calculated as joinDate + 1 month
  /// 
  /// Parameters:
  /// - name: Member's full name
  /// - phone: Member's phone number
  /// - amount: Membership fee amount
  /// - joinDate: Date when member joined
  /// - status: Member status (active/inactive)
  /// 
  /// Returns: ApiResponse with created member data
  Future<ApiResponse<Map<String, dynamic>>> addMember({
    required String name,
    required String phone,
    required double amount,
    required DateTime joinDate,
    required String status,
  }) async {
    try {
      print('➕ [MemberService] Adding new member: $name');

      // Automatically calculate due date (joinDate + 1 month)
      final dueDate = _calculateDueDate(joinDate);

      // Validate input data
      final validationError = _validateMemberData(
        name: name,
        phone: phone,
        amount: amount,
        joinDate: joinDate,
        status: status,
      );

      if (validationError != null) {
        print('❌ [MemberService] Validation failed: $validationError');
        return ApiResponse.error(message: validationError);
      }

      // Create member object
      final member = Member(
        name: name.trim(),
        phone: phone.trim(),
        amount: amount,
        joinDate: joinDate,
        dueDate: dueDate,
        status: status,
        createdAt: DateTime.now(),
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection(_collectionName)
          .add(member.toFirestore());

      print('✅ [MemberService] Member added successfully with ID: ${docRef.id}');

      // Fetch the created document to return complete data
      final createdDoc = await docRef.get();
      final createdMember = Member.fromFirestore(createdDoc);

      return ApiResponse.success(
        message: 'Member added successfully',
        data: createdMember.toJson(),
      );
    } catch (e) {
      print('❌ [MemberService] Error adding member: $e');
      return ApiResponse.error(
        message: 'Failed to add member: ${e.toString()}',
      );
    }
  }

  /// GET /members - Fetch all members
  /// 
  /// Retrieves all member documents from Firestore
  /// ordered by createdAt (latest first)
  /// 
  /// Returns: ApiResponse with list of all members
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllMembers() async {
    try {
      print('📋 [MemberService] Fetching all members...');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      final members = querySnapshot.docs
          .map((doc) => Member.fromFirestore(doc).toJson())
          .toList();

      print('✅ [MemberService] Retrieved ${members.length} member(s)');

      return ApiResponse.success(
        message: 'Members retrieved successfully',
        data: members,
      );
    } catch (e) {
      print('❌ [MemberService] Error fetching members: $e');
      return ApiResponse.error(
        message: 'Failed to fetch members: ${e.toString()}',
      );
    }
  }

  /// GET /members/{memberId} - Fetch a single member by ID
  /// 
  /// Retrieves a specific member document from Firestore
  /// 
  /// Parameters:
  /// - memberId: Document ID of the member
  /// 
  /// Returns: ApiResponse with member data
  Future<ApiResponse<Map<String, dynamic>>> getMemberById(String memberId) async {
    try {
      print('🔍 [MemberService] Fetching member with ID: $memberId');

      if (memberId.trim().isEmpty) {
        return ApiResponse.error(message: 'Member ID cannot be empty');
      }

      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(memberId)
          .get();

      if (!docSnapshot.exists) {
        print('❌ [MemberService] Member not found with ID: $memberId');
        return ApiResponse.error(message: 'Member not found');
      }

      final member = Member.fromFirestore(docSnapshot);
      print('✅ [MemberService] Member retrieved successfully');

      return ApiResponse.success(
        message: 'Member retrieved successfully',
        data: member.toJson(),
      );
    } catch (e) {
      print('❌ [MemberService] Error fetching member: $e');
      return ApiResponse.error(
        message: 'Failed to fetch member: ${e.toString()}',
      );
    }
  }

  /// PUT /members/{memberId} - Update an existing member
  /// 
  /// Updates a member document in Firestore using the document ID
  /// If joinDate is updated, dueDate is automatically recalculated
  /// 
  /// Parameters:
  /// - memberId: Document ID of the member to update
  /// - name: Updated member name (optional)
  /// - phone: Updated phone number (optional)
  /// - amount: Updated membership amount (optional)
  /// - joinDate: Updated join date (optional, triggers dueDate recalculation)
  /// - status: Updated status (optional)
  /// 
  /// Returns: ApiResponse with updated member data
  Future<ApiResponse<Map<String, dynamic>>> updateMember({
    required String memberId,
    String? name,
    String? phone,
    double? amount,
    DateTime? joinDate,
    String? status,
  }) async {
    try {
      print('✏️ [MemberService] Updating member with ID: $memberId');

      if (memberId.trim().isEmpty) {
        return ApiResponse.error(message: 'Member ID cannot be empty');
      }

      // Check if member exists
      final docRef = _firestore.collection(_collectionName).doc(memberId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('❌ [MemberService] Member not found with ID: $memberId');
        return ApiResponse.error(message: 'Member not found');
      }

      // Build update data
      final Map<String, dynamic> updateData = {};

      if (name != null) {
        if (name.trim().isEmpty) {
          return ApiResponse.error(message: 'Name cannot be empty');
        }
        updateData['name'] = name.trim();
      }

      if (phone != null) {
        if (phone.trim().isEmpty) {
          return ApiResponse.error(message: 'Phone cannot be empty');
        }
        updateData['phone'] = phone.trim();
      }

      if (amount != null) {
        if (amount < 0) {
          return ApiResponse.error(message: 'Amount must be a positive number');
        }
        updateData['amount'] = amount;
      }

      // If joinDate is updated, automatically recalculate dueDate
      if (joinDate != null) {
        final dueDate = _calculateDueDate(joinDate);
        updateData['joinDate'] = Timestamp.fromDate(joinDate);
        updateData['dueDate'] = Timestamp.fromDate(dueDate);
        print('📅 [MemberService] Join date updated, due date recalculated automatically');
      }

      if (status != null) {
        if (status != 'active' && status != 'inactive') {
          return ApiResponse.error(
            message: 'Status must be either "active" or "inactive"',
          );
        }
        updateData['status'] = status;
      }

      if (updateData.isEmpty) {
        return ApiResponse.error(message: 'No fields to update');
      }

      // Update document
      await docRef.update(updateData);
      print('✅ [MemberService] Member updated successfully');

      // Fetch updated document
      final updatedDoc = await docRef.get();
      final updatedMember = Member.fromFirestore(updatedDoc);

      return ApiResponse.success(
        message: 'Member updated successfully',
        data: updatedMember.toJson(),
      );
    } catch (e) {
      print('❌ [MemberService] Error updating member: $e');
      return ApiResponse.error(
        message: 'Failed to update member: ${e.toString()}',
      );
    }
  }

  /// DELETE /members/{memberId} - Delete a member
  /// 
  /// Deletes a member document from Firestore using the document ID
  /// 
  /// Parameters:
  /// - memberId: Document ID of the member to delete
  /// 
  /// Returns: ApiResponse confirming deletion
  Future<ApiResponse<void>> deleteMember(String memberId) async {
    try {
      print('🗑️ [MemberService] Deleting member with ID: $memberId');

      if (memberId.trim().isEmpty) {
        return ApiResponse.error(message: 'Member ID cannot be empty');
      }

      // Check if member exists
      final docRef = _firestore.collection(_collectionName).doc(memberId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('❌ [MemberService] Member not found with ID: $memberId');
        return ApiResponse.error(message: 'Member not found');
      }

      // Delete document
      await docRef.delete();
      print('✅ [MemberService] Member deleted successfully');

      return ApiResponse.success(
        message: 'Member deleted successfully',
      );
    } catch (e) {
      print('❌ [MemberService] Error deleting member: $e');
      return ApiResponse.error(
        message: 'Failed to delete member: ${e.toString()}',
      );
    }
  }

  /// Stream of all members (real-time updates)
  /// 
  /// Provides a real-time stream of member documents
  /// ordered by createdAt (latest first)
  /// 
  /// Returns: Stream of member list
  Stream<List<Member>> getMembersStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc))
            .toList());
  }

  /// Get members by status (active/inactive)
  /// 
  /// Filters members by their status
  /// 
  /// Parameters:
  /// - status: Filter by status (active/inactive)
  /// 
  /// Returns: ApiResponse with filtered member list
  Future<ApiResponse<List<Map<String, dynamic>>>> getMembersByStatus(
    String status,
  ) async {
    try {
      print('🔍 [MemberService] Fetching members with status: $status');

      if (status != 'active' && status != 'inactive') {
        return ApiResponse.error(
          message: 'Status must be either "active" or "inactive"',
        );
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      final members = querySnapshot.docs
          .map((doc) => Member.fromFirestore(doc).toJson())
          .toList();

      print('✅ [MemberService] Retrieved ${members.length} $status member(s)');

      return ApiResponse.success(
        message: 'Members retrieved successfully',
        data: members,
      );
    } catch (e) {
      print('❌ [MemberService] Error fetching members by status: $e');
      return ApiResponse.error(
        message: 'Failed to fetch members: ${e.toString()}',
      );
    }
  }
}
