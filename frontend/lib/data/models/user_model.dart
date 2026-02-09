import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String role;
  final DateTime? createdAt;
  final String? businessName;
  final String? fssaiNumber;
  final String? officeAddress;
  final String? contactNumber;
  final String? operatingHours;
  final String? aadharFrontUrl;
  final String? aadharBackUrl;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.role,
    this.createdAt,
    this.businessName,
    this.fssaiNumber,
    this.officeAddress,
    this.contactNumber,
    this.operatingHours,
    this.aadharFrontUrl,
    this.aadharBackUrl,
    this.isVerified = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? '',
      role: data['role'] ?? 'buyer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      businessName: data['businessName'],
      fssaiNumber: data['fssaiNumber'],
      officeAddress: data['officeAddress'],
      contactNumber: data['contactNumber'],
      operatingHours: data['operatingHours'],
      aadharFrontUrl: data['aadharFrontUrl'],
      aadharBackUrl: data['aadharBackUrl'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'businessName': businessName,
      'fssaiNumber': fssaiNumber,
      'officeAddress': officeAddress,
      'contactNumber': contactNumber,
      'operatingHours': operatingHours,
      'aadharFrontUrl': aadharFrontUrl,
      'aadharBackUrl': aadharBackUrl,
      'isVerified': isVerified,
    };
  }
}
