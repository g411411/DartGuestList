/// Сервис для работы с вечеринками (Party Service)
/// Этот класс инкапсулирует всю бизнес-логику, связанную с созданием,
/// поиском и удалением вечеринок в Firestore.
/// Все методы асинхронные (Future) и возвращают результаты через
/// механизмы Dart Futures, что позволяет легко их использовать в UI.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class PartyService {
  /// Экземпляр Firestore, получаемый через Riverpod‑провайдер.
  final FirebaseFirestore db;

  /// Конструктор с внедрением зависимости (Dependency Injection).
  PartyService(this.db);

  /// Приватный метод для генерации уникального кода вечеринки.
  /// Генерирует 7‑символьную строку, состоящую из букв и цифр без легко
  /// путающихся символов (O, 0, 1, I).
  String _generateCode() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random rng = Random();
    return List.generate(7, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Создаёт новую вечеринку.
  /// Принимает PIN‑код, который будет захеширован и сохранён в базе.
  /// Возвращает сгенерированный код вечеринки (String).
  Future<String> createParty(String pin) async {
    final String code = _generateCode();
    // Хешируем PIN‑код алгоритмом SHA‑256 – так хранится только хеш, а не сам PIN.
    final String pinHash = sha256.convert(utf8.encode(pin)).toString();
    await db.collection('parties').add({
      'partyCode': code,
      'pinHash': pinHash,
      // Серверное время создаёт точную отметку создания.
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  /// Ищет вечеринку по коду.
  /// Возвращает объект Party, если найден, иначе null.
  Future<Party?> getPartyByCode(String code) async {
    final QuerySnapshot querySnapshot = await db
        .collection('parties')
        .where('partyCode', isEqualTo: code)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return Party.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  /// Удаляет вечеринку, проверяя корректность PIN‑кода.
  /// При неверном PIN выбрасывает Exception.
  Future<void> deleteParty(String code, String pin) async {
    final QuerySnapshot querySnapshot = await db
        .collection('parties')
        .where('partyCode', isEqualTo: code)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Party not found.');
    }
    final QueryDocumentSnapshot doc = querySnapshot.docs.first;
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String pinHash = sha256.convert(utf8.encode(pin)).toString();
    if (data['pinHash'] != pinHash) {
      throw Exception('Incorrect PIN.');
    }
    await _deletePartyAndGuests(doc);
  }

  /// Удаляет вечеринку без проверки PIN‑кода (для разработчиков).
  Future<void> deletePartyByCode(String code) async {
    final QuerySnapshot querySnapshot = await db
        .collection('parties')
        .where('partyCode', isEqualTo: code)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Party "$code" not found.');
    }
    final QueryDocumentSnapshot doc = querySnapshot.docs.first;
    await _deletePartyAndGuests(doc);
  }

  /// Приватный метод, который удаляет сам документ вечеринки и
  /// все связанные записи гостей в одной батч‑операции.
  Future<void> _deletePartyAndGuests(QueryDocumentSnapshot partyDoc) async {
    final QuerySnapshot guests = await db
        .collection('guestEntries')
        .where('partyId', isEqualTo: partyDoc.id)
        .get();
    final WriteBatch batch = db.batch();
    for (final QueryDocumentSnapshot guest in guests.docs) {
      batch.delete(guest.reference);
    }
    batch.delete(partyDoc.reference);
    await batch.commit();
  }
}
