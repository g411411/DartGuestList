/// Точка входа в приложение и базовая настройка (setup)
/// Здесь мы инициализируем Flutter, подключаем Firebase и запускаем главный widget.

import 'package:flutter/material.dart';
// Подключаем Riverpod для управления состоянием (state management)
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Подключаем Firebase Core для работы с базой данных
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'state.dart';
import 'views/join_view.dart';
import 'views/dashboard_view.dart';
import 'views/organizer_view.dart';

/// Главная функция (entry point) приложения. Она асинхронная (async), 
/// так как нам нужно дождаться инициализации Firebase перед запуском интерфейса.
void main() async {
  // Гарантируем, что движок Flutter готов к работе перед вызовом асинхронного кода
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем Firebase с конфигурацией для текущей платформы (Web, Android, iOS)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // runApp запускает наше приложение. 
  // ProviderScope - это обязательная обертка для Riverpod, которая хранит все state providers.
  runApp(const ProviderScope(child: GuestListApp()));
}

/// Корневой widget приложения. Stateless означает, что он не имеет внутреннего изменяемого состояния.
class GuestListApp extends StatelessWidget {
  const GuestListApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp - это базовый виджет, который дает нам доступ к стилям Material Design, 
    // навигации (routing) и глобальным темам (theme).
    return MaterialApp(
      title: 'Guest List',
      debugShowCheckedModeBanner: false, // Убираем красную полоску "DEBUG" в правом верхнем углу
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[200], // Устанавливаем светло-серый фон для всех экранов
      ),
      home: const MainContainer(), // Задаем MainContainer как стартовый экран
    );
  }
}

/// Главный контейнер (shell) приложения.
/// Наследуется от ConsumerWidget, что позволяет ему считывать данные из Riverpod providers.
class MainContainer extends ConsumerWidget {
  const MainContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch "слушает" appViewProvider. Если значение изменится, widget перерисуется (rebuild).
    // currentView хранит текущий экран (AppView.join, AppView.dashboard или AppView.organizer)
    final AppView currentView = ref.watch(appViewProvider);

    return Scaffold(
      body: Center(
        // SingleChildScrollView позволяет скроллить контент, если экран слишком маленький
        child: SingleChildScrollView(
          child: Container(
            width: 400, // Фиксируем ширину для красивого отображения (как карточка)
            margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              // Добавляем легкую тень (shadow)
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            // Отрисовываем нужный view в зависимости от текущего state
            child: _buildView(currentView),
          ),
        ),
      ),
    );
  }

  /// Вспомогательная функция (helper method), которая возвращает нужный widget 
  /// на основе текущего значения AppView.
  Widget _buildView(AppView view) {
    switch (view) {
      case AppView.join:
        return const JoinView();
      case AppView.dashboard:
        return const DashboardView();
      case AppView.organizer:
        return const OrganizerView();
    }
  }
}
