// lib/models/verification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatusEnum {
  notStarted,
  pending,
  approved,
  rejected,
  expired,
}

enum DocumentType {
  passport,
  driversLicense,
  nationalId,
}

enum ProofOfAddressType {
  utilityBill,
  bankStatement,
  leaseAgreement,
}

class VerificationDocument {
  final DocumentType type;
  final String frontImageUrl;
  final String? backImageUrl;
  final DateTime uploadedAt;

  VerificationDocument({
    required this.type,
    required this.frontImageUrl,
    this.backImageUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory VerificationDocument.fromMap(Map<String, dynamic> map) {
    return VerificationDocument(
      type: DocumentType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => DocumentType.passport,
      ),
      frontImageUrl: map['frontImageUrl'] ?? '',
      backImageUrl: map['backImageUrl'],
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class SelfieDocument {
  final String imageUrl;
  final DateTime uploadedAt;

  SelfieDocument({
    required this.imageUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory SelfieDocument.fromMap(Map<String, dynamic> map) {
    return SelfieDocument(
      imageUrl: map['imageUrl'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ProofOfAddressDocument {
  final ProofOfAddressType type;
  final String imageUrl;
  final DateTime uploadedAt;

  ProofOfAddressDocument({
    required this.type,
    required this.imageUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory ProofOfAddressDocument.fromMap(Map<String, dynamic> map) {
    return ProofOfAddressDocument(
      type: ProofOfAddressType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ProofOfAddressType.utilityBill,
      ),
      imageUrl: map['imageUrl'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class VerificationDocuments {
  final VerificationDocument? idDocument;
  final SelfieDocument? selfieWithId;
  final ProofOfAddressDocument? proofOfAddress;

  VerificationDocuments({
    this.idDocument,
    this.selfieWithId,
    this.proofOfAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'idDocument': idDocument?.toMap(),
      'selfieWithId': selfieWithId?.toMap(),
      'proofOfAddress': proofOfAddress?.toMap(),
    };
  }

  factory VerificationDocuments.fromMap(Map<String, dynamic> map) {
    return VerificationDocuments(
      idDocument: map['idDocument'] != null
          ? VerificationDocument.fromMap(map['idDocument'])
          : null,
      selfieWithId: map['selfieWithId'] != null
          ? SelfieDocument.fromMap(map['selfieWithId'])
          : null,
      proofOfAddress: map['proofOfAddress'] != null
          ? ProofOfAddressDocument.fromMap(map['proofOfAddress'])
          : null,
    );
  }
}

class ExtractedInfo {
  final String? fullName;
  final String? dateOfBirth;
  final String? documentNumber;
  final String? address;
  final String? nationality;

  ExtractedInfo({
    this.fullName,
    this.dateOfBirth,
    this.documentNumber,
    this.address,
    this.nationality,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'documentNumber': documentNumber,
      'address': address,
      'nationality': nationality,
    };
  }

  factory ExtractedInfo.fromMap(Map<String, dynamic> map) {
    return ExtractedInfo(
      fullName: map['fullName'],
      dateOfBirth: map['dateOfBirth'],
      documentNumber: map['documentNumber'],
      address: map['address'],
      nationality: map['nationality'],
    );
  }
}

class DeviceInfo {
  final String platform;
  final String version;
  final String model;

  DeviceInfo({
    required this.platform,
    required this.version,
    required this.model,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'version': version,
      'model': model,
    };
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      platform: map['platform'] ?? '',
      version: map['version'] ?? '',
      model: map['model'] ?? '',
    );
  }
}

class VerificationModel {
  final String userId;
  final VerificationStatusEnum status;
  final String type;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final DateTime? expiresAt;

  final VerificationDocuments? documents;
  final ExtractedInfo? extractedInfo;

  final String? reviewedBy;
  final String? reviewNotes;
  final String? rejectionReason;
  final int? verificationScore;

  final String? ipAddress;
  final String? userAgent;
  final DeviceInfo? deviceInfo;

  final DateTime createdAt;
  final DateTime updatedAt;

  VerificationModel({
    required this.userId,
    required this.status,
    required this.type,
    this.submittedAt,
    this.reviewedAt,
    this.approvedAt,
    this.expiresAt,
    this.documents,
    this.extractedInfo,
    this.reviewedBy,
    this.reviewNotes,
    this.rejectionReason,
    this.verificationScore,
    this.ipAddress,
    this.userAgent,
    this.deviceInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status.name,
      'type': type,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'documents': documents?.toMap(),
      'extractedInfo': extractedInfo?.toMap(),
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'rejectionReason': rejectionReason,
      'verificationScore': verificationScore,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceInfo': deviceInfo?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory VerificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VerificationModel(
      userId: map['userId'] ?? documentId,
      status: VerificationStatusEnum.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => VerificationStatusEnum.notStarted,
      ),
      type: map['type'] ?? 'traveler',
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      documents: map['documents'] != null
          ? VerificationDocuments.fromMap(map['documents'])
          : null,
      extractedInfo: map['extractedInfo'] != null
          ? ExtractedInfo.fromMap(map['extractedInfo'])
          : null,
      reviewedBy: map['reviewedBy'],
      reviewNotes: map['reviewNotes'],
      rejectionReason: map['rejectionReason'],
      verificationScore: map['verificationScore'],
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      deviceInfo: map['deviceInfo'] != null
          ? DeviceInfo.fromMap(map['deviceInfo'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  VerificationModel copyWith({
    String? userId,
    VerificationStatusEnum? status,
    String? type,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? approvedAt,
    DateTime? expiresAt,
    VerificationDocuments? documents,
    ExtractedInfo? extractedInfo,
    String? reviewedBy,
    String? reviewNotes,
    String? rejectionReason,
    int? verificationScore,
    String? ipAddress,
    String? userAgent,
    DeviceInfo? deviceInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VerificationModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      type: type ?? this.type,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      documents: documents ?? this.documents,
      extractedInfo: extractedInfo ?? this.extractedInfo,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verificationScore: verificationScore ?? this.verificationScore,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  bool get isApproved => status == VerificationStatusEnum.approved && !isExpired;
  bool get canResubmit => status == VerificationStatusEnum.rejected ||
      status == VerificationStatusEnum.expired;

  double get completionPercentage {
    int completed = 0;
    int total = 3;

    if (documents?.idDocument != null) completed++;
    if (documents?.selfieWithId != null) completed++;
    if (documents?.proofOfAddress != null) completed++;

    return completed / total;
  }
}