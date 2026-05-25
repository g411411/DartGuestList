/// Глобальное управление состоянием (State Management)
/// В этом файле мы используем пакет Riverpod для создания "провайдеров" (providers).
/// Провайдеры позволяют хранить данные в одном месте и предоставлять к ним доступ 
/// из любого экрана, избегая передачи данных через аргументы виджетов (prop drilling).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'services/party_service.dart';
import 'services/guest_service.dart';

/// Перечисление (enum) доступных экранов в нашем приложении.
/// Это наш простой способ переключения (routing) между интерфейсами.
enum AppView { join, dashboard, organizer }

/// Notifier — это класс, который хранит какое-то значение (state) 
/// и уведомляет всех слушателей (widgets) при его изменении.
/// В данном случае он хранит текущий экран приложения (AppView).
class AppViewNotifier extends Notifier<AppView> {
  // Начальное значение (initial state)
  @override
  AppView build() => AppView.join;

  // Метод для обновления состояния. Когда мы присваиваем state новое значение,
  // Riverpod автоматически заставляет перерисовываться все зависимые виджеты.
  void setView(AppView view) => state = view;
}

/// Создаем глобальный NotifierProvider.
/// Через appViewProvider любой виджет может узнать текущий экран (ref.watch) 
/// или изменить его (ref.read(appViewProvider.notifier).setView).
final appViewProvider = NotifierProvider<AppViewNotifier, AppView>(AppViewNotifier.new);

/// Notifier для хранения текущей вечеринки (Party).
/// Значение может быть null (Party?), если вечеринка еще не выбрана.
class CurrentPartyNotifier extends Notifier<Party?> {
  @override
  Party? build() => null;

  void setParty(Party party) => state = party;
}

final currentPartyProvider = NotifierProvider<CurrentPartyNotifier, Party?>(CurrentPartyNotifier.new);

/// Обычный Provider для базы данных (Firestore).
/// Он просто возвращает один и тот же объект (instance) при каждом вызове.
/// Это удобно для внедрения зависимостей (Dependency Injection).
final dbProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Провайдеры сервисов (Services Providers).
/// Эти провайдеры создают объекты сервисов, передавая им базу данных.
/// Если в будущем мы захотим подменить базу данных (например, на мок для тестов),
/// нам достаточно будет поменять только dbProvider!

// Провайдер для PartyService (управление вечеринками)
final partyServiceProvider = Provider<PartyService>((ref) {
  final FirebaseFirestore db = ref.watch(dbProvider);
  return PartyService(db);
});

// Провайдер для GuestService (управление списком гостей)
final guestServiceProvider = Provider<GuestService>((ref) {
  final FirebaseFirestore db = ref.watch(dbProvider);
  return GuestService(db);
});
