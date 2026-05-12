import 'package:cloud_firestore/cloud_firestore.dart';

class Party {
  final String id;
  final String partyCode;
  final String pinHash;
  final DateTime? createdAt;

  Party({
    required this.id,
    required this.partyCode,
    required this.pinHash,
    this.createdAt,
  });

  factory Party.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return Party(id: doc.id, partyCode: '', pinHash: '');
    }
    return Party(
      id: doc.id,
      partyCode: data['partyCode'] ?? '',
      pinHash: data['pinHash'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partyCode': partyCode,
      'pinHash': pinHash,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class GuestEntry {
  final String id;
  final String partyId;
  final String guestName;
  final String dish;
  final DateTime? createdAt;

  GuestEntry({
    required this.id,
    required this.partyId,
    required this.guestName,
    required this.dish,
    this.createdAt,
  });

  String get displayText => "$guestName — $dish";

  factory GuestEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return GuestEntry(id: doc.id, partyId: '', guestName: '', dish: '');
    }
    return GuestEntry(
      id: doc.id,
      partyId: data['partyId'] ?? '',
      guestName: data['guestName'] ?? '',
      dish: data['dish'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partyId': partyId,
      'guestName': guestName,
      'dish': dish,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
