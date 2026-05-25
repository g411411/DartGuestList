// models.dart – Определения моделей данных для приложения
// ------------------------------------------------------------
// Этот файл содержит две модели: Party (вечеринка) и GuestEntry (запись гостя).
// Переменные и имена классов оставлены на английском, чтобы было удобно
// использовать их в коде и в Firestore, но комментарии написаны на русском
// для лучшего понимания новичками.

import 'package:cloud_firestore/cloud_firestore.dart';

// -----------------------------------------------------------------
// Модель Party – представляет вечерину, создаваемую пользователем
// -----------------------------------------------------------------
class Party {
  // Уникальный идентификатор документа в Firestore
  final String id;
  // Код вечеринки, используемый для присоединения
  final String partyCode;
  // Хэш PIN‑кода (SHA‑256) для защиты
  final String pinHash;
  // Дата создания (может быть null, если запись только что создана)
  final DateTime? createdAt;

  // Конструктор с обязательными параметрами
  Party({
    required this.id,
    required this.partyCode,
    required this.pinHash,
    this.createdAt,
  });

  // Фабричный метод – создает объект Party из снимка Firestore
  factory Party.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Если данных нет, возвращаем «пустой» объект (заполнится позже)
      return Party(id: doc.id, partyCode: '', pinHash: '');
    }
    return Party(
      id: doc.id,
      partyCode: data['partyCode'] ?? '',
      pinHash: data['pinHash'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Преобразование модели в Map для записи в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'partyCode': partyCode,
      'pinHash': pinHash,
      // Если createdAt уже известна, сохраняем её, иначе используем серверное время
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

// -----------------------------------------------------------------
// Модель GuestEntry – запись гостя на вечеринке
// -----------------------------------------------------------------
class GuestEntry {
  // Уникальный идентификатор записи в Firestore
  final String id;
  // Идентификатор вечеринки, к которой относится запись
  final String partyId;
  // Имя гостя
  final String guestName;
  // Текст блюда, которое гость принесёт
  final String dish;
  // Дата создания записи (может быть null)
  final DateTime? createdAt;

  GuestEntry({
    required this.id,
    required this.partyId,
    required this.guestName,
    required this.dish,
    this.createdAt,
  });

  // Удобный getter для отображения в UI
  String get displayText => "$guestName — $dish";

  // Фабричный метод – создает объект из снимка Firestore
  factory GuestEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return GuestEntry(
        id: doc.id,
        partyId: '',
        guestName: '',
        dish: '',
      );
    }
    return GuestEntry(
      id: doc.id,
      partyId: data['partyId'] ?? '',
      guestName: data['guestName'] ?? '',
      dish: data['dish'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Преобразование в Map для записи в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'partyId': partyId,
      'guestName': guestName,
      'dish': dish,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
