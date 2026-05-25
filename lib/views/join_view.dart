import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state.dart';
import '../models.dart';
import '../services/party_service.dart';
// Виджет присоединения к вечеринке, позволяет пользователю ввести код и присоединиться.

// Виджет для присоединения к вечеринке
class JoinView extends ConsumerStatefulWidget {
  const JoinView({super.key});

  @override
  ConsumerState<JoinView> createState() => _JoinViewState();
}

// Состояние виджета, управляет вводом кода вечеринки и процессом присоединения
class _JoinViewState extends ConsumerState<JoinView> {
  final TextEditingController _partyCodeTextController = TextEditingController();

  @override
  void dispose() {
    _partyCodeTextController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinParty() async {
    final String enteredCode = _partyCodeTextController.text.trim();
    if (enteredCode.isEmpty) return;

    final PartyService partyService = ref.read(partyServiceProvider);
    
    try {
      final Party? party = await partyService.getPartyByCode(enteredCode);
      
      if (party != null) {
        ref.read(currentPartyProvider.notifier).setParty(party);
        ref.read(appViewProvider.notifier).setView(AppView.dashboard);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Party not found!")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error checking party code")),
        );
      }
    }
  }

  // Переопределяем метод build, создающий UI
  @override
  Widget build(BuildContext context) {
    // Основной контейнер UI для ввода кода и кнопки присоединения
    return Column(
      mainAxisSize: MainAxisSize.min, // Keeps it centered vertically
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Welcome to Guest List",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B), // Dark blue/gray color
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4), // Light green background
            border: Border.all(color: const Color(0xFFBBF7D0)), // Light green border
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text("🎉", style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    "Join a Party",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534), // Dark green text
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _partyCodeTextController,
                        decoration: InputDecoration(
                          hintText: "Enter Party Code",
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleJoinParty,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A), // Green button
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text(
                        "Add Me",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onDoubleTap: () {
                  ref.read(appViewProvider.notifier).setView(AppView.organizer);
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: const [
                    Text("💡", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      "Ask the party organizer for the code to join.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B), // Gray text
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        const Text(
          "Version 1.0",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
