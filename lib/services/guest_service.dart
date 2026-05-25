/// Сервис для работы с гостями (Guest Service)
/// Этот класс инкапсулирует все CRUD‑операции (создание, чтение, обновление, удаление)
/// для записей гостей, хранящихся в коллекции "guestEntries" Firestore.
/// Методы используют асинхронные Future и Stream, что позволяет UI реагировать
/// на изменения в реальном времени.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class GuestService {
  /// Экземпляр Firestore, получаемый через Riverpod‑провайдер.
  final FirebaseFirestore db;

  /// Конструктор с внедрением зависимости (Dependency Injection).
  GuestService(this.db);

  /// Добавляет нового гостя в указанную вечеринку.
  /// Параметры: partyId – ID вечеринки, guestName – имя гостя, dish – блюдо гостя.
  Future<void> addGuest(String partyId, String guestName, String dish) async {
    final GuestEntry entry = GuestEntry(
      id: '', // Firestore генерирует идентификатор автоматически
      partyId: partyId,
      guestName: guestName,
      dish: dish,
    );
    await db.collection('guestEntries').add(entry.toFirestore());
  }

  /// Обновляет название блюда у существующей записи гостя.
  /// entryId – уникальный ID записи в Firestore, newDish – новое название блюда.
  Future<void> updateGuestDish(String entryId, String newDish) async {
    await db.collection('guestEntries').doc(entryId).update({
      'dish': newDish,
    });
  }

  /// Удаляет запись гостя по её идентификатору.
  Future<void> deleteGuest(String entryId) async {
    await db.collection('guestEntries').doc(entryId).delete();
  }

  /// Возвращает поток (Stream) списка гостей для указанной вечеринки.
  /// С помощью StreamBuilder UI автоматически обновляется при изменении
  /// данных в Firestore.
  Stream<List<GuestEntry>> getGuestsStream(String partyId) {
    return db
        .collection('guestEntries')
        .where('partyId', isEqualTo: partyId)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      // Преобразуем каждый документ в объект GuestEntry
      final List<GuestEntry> entries = querySnapshot.docs
          .map((QueryDocumentSnapshot doc) => GuestEntry.fromFirestore(doc))
          .toList();
      // Сортируем локально по дате создания, новейшие сверху
      entries.sort((GuestEntry a, GuestEntry b) {
        final DateTime aTime = a.createdAt ?? DateTime.now();
        final DateTime bTime = b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return entries;
    });
  }
}
