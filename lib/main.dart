import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models.dart';

// 1. The State (Equivalent to your Angular State Model)
enum AppView { join, dashboard, organizer }

// 2. The Provider (Equivalent to an Angular Service with a Signal)
class AppViewNotifier extends Notifier<AppView> {
  @override
  AppView build() => AppView.join;

  void setView(AppView view) => state = view;
}

final appViewProvider = NotifierProvider<AppViewNotifier, AppView>(AppViewNotifier.new);

// Added state provider for the party to be used in the Dashboard
class CurrentPartyNotifier extends Notifier<Party?> {
  @override
  Party? build() => null;

  void setParty(Party party) => state = party;
}

final currentPartyProvider = NotifierProvider<CurrentPartyNotifier, Party?>(CurrentPartyNotifier.new);

// Exporting 'db' equivalent: Riverpod provider for Firestore
final dbProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. `initializeApp`: Creates the connection object using the provided config.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // runApp makes your widget the root of the tree [cite: 41, 42]
  runApp(const ProviderScope(child: GuestListApp()));
}

class GuestListApp extends StatelessWidget {
  const GuestListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guest List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Replaces global CSS for background color [cite: 55, 57]
        scaffoldBackgroundColor: Colors.grey[200], 
      ),
      home: const MainContainer(), // The default view [cite: 60]
    );
  }
}

class MainContainer extends ConsumerWidget { // ConsumerWidget allows reading providers
  const MainContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(appViewProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: _buildView(currentView),
          ),
        ),
      ),
    );
  }

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

class OrganizerView extends ConsumerWidget {
  const OrganizerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.build, color: Color(0xFFCBD5E1), size: 24),
                SizedBox(width: 8),
                Text(
                  "Organizer Tools",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
              onPressed: () => ref.read(appViewProvider.notifier).setView(AppView.join),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const CreatePartySection(),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFFEE2E2)),
        const SizedBox(height: 24),
        const DeletePartySection(),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),
        const DevToolsSection(),
      ],
    );
  }
}

// ── Create Party ──────────────────────────────────────────────────────────────
class CreatePartySection extends ConsumerStatefulWidget {
  const CreatePartySection({super.key});
  @override
  ConsumerState<CreatePartySection> createState() => _CreatePartySectionState();
}

class _CreatePartySectionState extends ConsumerState<CreatePartySection> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showPin = false;
  String? _error;
  String? _createdCode;

  @override
  void dispose() { _pinCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(7, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createParty() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 characters.');
      return;
    }
    if (pin != confirm) { setState(() => _error = 'PINs do not match.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final db = ref.read(dbProvider);
      final code = _generateCode();
      final pinHash = sha256.convert(utf8.encode(pin)).toString();
      await db.collection('parties').add({
        'partyCode': code, 'pinHash': pinHash, 'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() { _createdCode = code; _loading = false; });
    } catch (e) { setState(() { _error = 'Error: $e'; _loading = false; }); }
  }

  void _reset() {
    setState(() { _createdCode = null; _error = null; _showPin = false; });
    _pinCtrl.clear(); _confirmCtrl.clear();
  }

  InputDecoration _field(String hint, {bool showToggle = false}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    suffixIcon: showToggle
        ? IconButton(
            icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 18, color: const Color(0xFF94A3B8)),
            onPressed: () => setState(() => _showPin = !_showPin),
          )
        : null,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _createdCode != null ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("✅ Party Created!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
      const SizedBox(height: 12),
      const Text("Share this code with your guests:", style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
        child: Text(_createdCode!, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6, color: Color(0xFF6D28D9))),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 44,
        child: ElevatedButton(
          onPressed: _reset,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          child: const Text("Create Another Party", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Create a New Party", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
      const SizedBox(height: 16),
      const Text("Create a PIN", style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
      const SizedBox(height: 4),
      SizedBox(height: 44, child: TextField(
        controller: _pinCtrl,
        obscureText: !_showPin,
        decoration: _field("Enter PIN", showToggle: true),
      )),
      const SizedBox(height: 12),
      const Text("Confirm PIN", style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
      const SizedBox(height: 4),
      SizedBox(height: 44, child: TextField(
        controller: _confirmCtrl,
        obscureText: !_showPin,
        decoration: _field("Confirm PIN"),
      )),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)))],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 44,
        child: ElevatedButton(
          onPressed: _loading ? null : _createParty,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Create Party", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );
}

// ── Delete Party ──────────────────────────────────────────────────────────────
class DeletePartySection extends ConsumerStatefulWidget {
  const DeletePartySection({super.key});
  @override
  ConsumerState<DeletePartySection> createState() => _DeletePartySectionState();
}

class _DeletePartySectionState extends ConsumerState<DeletePartySection> {
  final _codeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() { _codeCtrl.dispose(); _pinCtrl.dispose(); super.dispose(); }

  Future<void> _deleteParty() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final pin = _pinCtrl.text.trim();
    if (code.isEmpty || pin.isEmpty) { setState(() => _error = 'Both fields are required.'); return; }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final db = ref.read(dbProvider);
      final q = await db.collection('parties').where('partyCode', isEqualTo: code).limit(1).get();
      if (q.docs.isEmpty) { setState(() { _error = 'Party not found.'; _loading = false; }); return; }
      final doc = q.docs.first;
      final data = doc.data();
      final pinHash = sha256.convert(utf8.encode(pin)).toString();
      if (data['pinHash'] != pinHash) { setState(() { _error = 'Incorrect PIN.'; _loading = false; }); return; }
      final guests = await db.collection('guestEntries').where('partyId', isEqualTo: doc.id).get();
      final batch = db.batch();
      for (final g in guests.docs) batch.delete(g.reference);
      batch.delete(doc.reference);
      await batch.commit();
      setState(() { _success = 'Party "$code" deleted successfully.'; _loading = false; });
      _codeCtrl.clear(); _pinCtrl.clear();
    } catch (e) { setState(() { _error = 'Error: $e'; _loading = false; }); }
  }

  InputDecoration _field(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFFECACA))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFFECACA))),
    counterText: '',
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: const [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 20),
        SizedBox(width: 8),
        Text("Danger Zone: Delete Party", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(text: const TextSpan(style: TextStyle(fontSize: 13, color: Color(0xFF991B1B)), children: [
              TextSpan(text: "Permanently delete a party and all its guest records. "),
              TextSpan(text: "This cannot be undone.", style: TextStyle(fontWeight: FontWeight.bold)),
            ])),
            const SizedBox(height: 16),
            SizedBox(height: 44, child: TextField(controller: _codeCtrl, textCapitalization: TextCapitalization.characters, decoration: _field("Enter Party Code"))),
            const SizedBox(height: 12),
            SizedBox(height: 44, child: TextField(controller: _pinCtrl, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: _field("Enter Original PIN (6 digits)"))),
            if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)))],
            if (_success != null) ...[const SizedBox(height: 8), Text(_success!, style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)))],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: _loading ? null : _deleteParty,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Delete Party Forever", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ── Dev Tools ─────────────────────────────────────────────────────────────────
class DevToolsSection extends ConsumerStatefulWidget {
  const DevToolsSection({super.key});
  @override
  ConsumerState<DevToolsSection> createState() => _DevToolsSectionState();
}

class _DevToolsSectionState extends ConsumerState<DevToolsSection> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _deleteByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) { setState(() => _error = 'Enter a party code.'); return; }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final db = ref.read(dbProvider);
      final q = await db.collection('parties').where('partyCode', isEqualTo: code).limit(1).get();
      if (q.docs.isEmpty) { setState(() { _error = 'Party "$code" not found.'; _loading = false; }); return; }
      final doc = q.docs.first;
      final guests = await db.collection('guestEntries').where('partyId', isEqualTo: doc.id).get();
      final batch = db.batch();
      for (final g in guests.docs) batch.delete(g.reference);
      batch.delete(doc.reference);
      await batch.commit();
      setState(() { _success = 'Party "$code" deleted (no auth).'; _loading = false; });
      _codeCtrl.clear();
    } catch (e) { setState(() { _error = 'Error: $e'; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("DEVELOPER / TESTING TOOLS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 1.0)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Delete Party by Code (No PIN)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 12),
            SizedBox(height: 44, child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "Enter Party Code",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            )),
            if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)))],
            if (_success != null) ...[const SizedBox(height: 8), Text(_success!, style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)))],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: _loading ? null : _deleteByCode,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Delete (No Auth)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class JoinView extends ConsumerStatefulWidget {
  const JoinView({super.key});

  @override
  ConsumerState<JoinView> createState() => _JoinViewState();
}

class _JoinViewState extends ConsumerState<JoinView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        controller: _codeController,
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
                      onPressed: () async {
                        final code = _codeController.text.trim();
                        if (code.isNotEmpty) {
                          final db = ref.read(dbProvider);
                          try {
                            final query = await db.collection('parties').where('partyCode', isEqualTo: code).limit(1).get();
                            if (query.docs.isNotEmpty) {
                              final party = Party.fromFirestore(query.docs.first);
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
                                SnackBar(content: Text("Error checking party code")),
                              );
                            }
                          }
                        }
                      },
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

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final _nameController = TextEditingController();
  final _dishController = TextEditingController();
  final _scrollController = ScrollController();

  Future<void> _addGuest(String partyId) async {
    final name = _nameController.text.trim();
    final dish = _dishController.text.trim();
    if (name.isEmpty || dish.isEmpty) return;

    final db = ref.read(dbProvider);
    final entry = GuestEntry(
      id: '', // Firestore generates this
      partyId: partyId,
      guestName: name,
      dish: dish,
    );

    await db.collection('guestEntries').add(entry.toFirestore());

    _nameController.clear();
    _dishController.clear();
  }



  @override
  void dispose() {
    _nameController.dispose();
    _dishController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final party = ref.watch(currentPartyProvider);
    final partyId = party?.id ?? '';
    final partyCode = party?.partyCode ?? 'UNKNOWN';
    final db = ref.watch(dbProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFFE2E8F0)), // Light gray border
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top green line
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text("📋", style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              "Guest List",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(appViewProvider.notifier).setView(AppView.join);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444), // Red text
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Exit Party"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // For Party Tag
                    Row(
                      children: [
                        const Text(
                          "For Party: ",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            partyCode,
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 20),
                    // Add To List Form
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ADD TO LIST",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Text("💡", style: TextStyle(fontSize: 12)),
                              SizedBox(width: 6),
                              Text(
                                "Example: Allan — Salad, Juice, Cake",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: "Your Name (e.g. Al)",
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _dishController,
                                  maxLines: null,
                                  minLines: 1,
                                  keyboardType: TextInputType.multiline,
                                  decoration: InputDecoration(
                                    hintText: "Your dish (e.g. Sala)",
                                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () => _addGuest(partyId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                    ),
                                    child: const Text(
                                      "Add to List",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 40,
                                width: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _nameController.clear();
                                    _dishController.clear();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDCFCE7), // Light green
                                    foregroundColor: const Color(0xFF16A34A),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  child: const Icon(Icons.refresh, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Firestore Stream of Guests
                    StreamBuilder<QuerySnapshot>(
                      stream: db
                          .collection('guestEntries')
                          .where('partyId', isEqualTo: partyId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final entries = docs.map((d) => GuestEntry.fromFirestore(d)).toList();
                        
                        // Sort locally to avoid needing a Firestore composite index
                        entries.sort((a, b) {
                          final aTime = a.createdAt ?? DateTime.now();
                          final bTime = b.createdAt ?? DateTime.now();
                          return bTime.compareTo(aTime); // newest first
                        });

                        if (entries.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                "No guests yet. Be the first!",
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: RawScrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            thickness: 8.0,
                            radius: const Radius.circular(8.0),
                            thumbColor: const Color(0xFF94A3B8),
                            interactive: true,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
                              shrinkWrap: true,
                              itemCount: entries.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return GuestListItem(entry: entry);
                              },
                            ),
                          ),
                        );
                      },
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

class GuestListItem extends ConsumerStatefulWidget {
  final GuestEntry entry;

  const GuestListItem({super.key, required this.entry});

  @override
  ConsumerState<GuestListItem> createState() => _GuestListItemState();
}

class _GuestListItemState extends ConsumerState<GuestListItem> {
  bool _isEditing = false;
  late TextEditingController _editDishController;

  @override
  void initState() {
    super.initState();
    _editDishController = TextEditingController(text: widget.entry.dish);
  }

  @override
  void didUpdateWidget(GuestListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.dish != widget.entry.dish && !_isEditing) {
      _editDishController.text = widget.entry.dish;
    }
  }

  @override
  void dispose() {
    _editDishController.dispose();
    super.dispose();
  }

  Future<void> _updateGuest() async {
    final newDish = _editDishController.text.trim();
    if (newDish.isNotEmpty) {
      final db = ref.read(dbProvider);
      await db.collection('guestEntries').doc(widget.entry.id).update({
        'dish': newDish,
      });
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _deleteGuest() async {
    final db = ref.read(dbProvider);
    await db.collection('guestEntries').doc(widget.entry.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF), // Indigo-50
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC7D2FE)), // Indigo-200
        ),
        child: Row(
          children: [
            Text(
              "${widget.entry.guestName} ",
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              "— ",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _editDishController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFC7D2FE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFC7D2FE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: _updateGuest,
                icon: const Icon(Icons.check, size: 16),
                label: const Text("Save", style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo-500
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 32,
              width: 32,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _editDishController.text = widget.entry.dish;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      );
    }

    // Normal view
    final char = widget.entry.guestName.isNotEmpty ? widget.entry.guestName[0].toUpperCase() : '?';
    final colors = [
      const Color(0xFFF87171), // Red
      const Color(0xFFA78BFA), // Purple
      const Color(0xFF60A5FA), // Blue
      const Color(0xFF34D399), // Green
      const Color(0xFFFBBF24), // Yellow
    ];
    final colorIndex = char.codeUnitAt(0) % colors.length;
    final avatarColor = colors[colorIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            radius: 16,
            child: Text(
              char,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                children: [
                  TextSpan(
                    text: "${widget.entry.guestName} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: "— ",
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  TextSpan(
                    text: widget.entry.dish,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF60A5FA), size: 20),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 20),
            onPressed: _deleteGuest,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}
