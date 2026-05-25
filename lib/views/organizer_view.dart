import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state.dart';
import '../services/party_service.dart';

// Виджет-организатор, отображает инструменты для создания, удаления и управления вечеринками
class OrganizerView extends ConsumerWidget {
  const OrganizerView({super.key});

  // Переопределяем метод build для построения UI
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
// Секция создания новой вечеринки
class CreatePartySection extends ConsumerStatefulWidget {
  const CreatePartySection({super.key});
  @override
  ConsumerState<CreatePartySection> createState() => _CreatePartySectionState();
}

// Состояние секции создания, управляет вводом PIN и процессом создания
class _CreatePartySectionState extends ConsumerState<CreatePartySection> {
  final TextEditingController _pinTextController = TextEditingController();
  final TextEditingController _confirmPinTextController = TextEditingController();
  bool _isLoading = false;
  bool _showPin = false;
  String? _errorMessage;
  String? _createdPartyCode;

  @override
  void dispose() {
    _pinTextController.dispose();
    _confirmPinTextController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateParty() async {
    final String pin = _pinTextController.text.trim();
    final String confirmPin = _confirmPinTextController.text.trim();
    
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 characters.');
      return;
    }
    
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'PINs do not match.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final PartyService partyService = ref.read(partyServiceProvider);
      final String code = await partyService.createParty(pin);
      
      setState(() {
        _createdPartyCode = code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _createdPartyCode = null;
      _errorMessage = null;
      _showPin = false;
    });
    _pinTextController.clear();
    _confirmPinTextController.clear();
  }

  InputDecoration _buildInputDecoration(String hint, {bool showToggle = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      suffixIcon: showToggle
          ? IconButton(
              icon: Icon(
                _showPin ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _showPin = !_showPin),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _createdPartyCode != null ? _buildSuccessMessage() : _buildCreateForm(),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "✅ Party Created!",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
        ),
        const SizedBox(height: 12),
        const Text("Share this code with your guests:", style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _createdPartyCode!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: Color(0xFF6D28D9),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _resetForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text("Create Another Party", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Create a New Party", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
        const SizedBox(height: 16),
        const Text("Create a PIN", style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _pinTextController,
            obscureText: !_showPin,
            decoration: _buildInputDecoration("Enter PIN", showToggle: true),
          ),
        ),
        const SizedBox(height: 12),
        const Text("Confirm PIN", style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _confirmPinTextController,
            obscureText: !_showPin,
            decoration: _buildInputDecoration("Confirm PIN"),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleCreateParty,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Create Party", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ── Delete Party ──────────────────────────────────────────────────────────────
// Секция удаления вечеринки (опасная зона)
class DeletePartySection extends ConsumerStatefulWidget {
  const DeletePartySection({super.key});
  @override
  ConsumerState<DeletePartySection> createState() => _DeletePartySectionState();
}

// Состояние секции удаления, обрабатывает ввод кода и PIN для подтверждения
class _DeletePartySectionState extends ConsumerState<DeletePartySection> {
  final TextEditingController _partyCodeTextController = TextEditingController();
  final TextEditingController _pinTextController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _partyCodeTextController.dispose();
    _pinTextController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteParty() async {
    final String code = _partyCodeTextController.text.trim().toUpperCase();
    final String pin = _pinTextController.text.trim();
    
    if (code.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Both fields are required.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final PartyService partyService = ref.read(partyServiceProvider);
      await partyService.deleteParty(code, pin);
      
      setState(() {
        _successMessage = 'Party "$code" deleted successfully.';
        _isLoading = false;
      });
      _partyCodeTextController.clear();
      _pinTextController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFFECACA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFFECACA)),
      ),
      counterText: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 20),
            SizedBox(width: 8),
            Text(
              "Danger Zone: Delete Party",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            border: Border.all(color: const Color(0xFFFECACA)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
                  children: [
                    TextSpan(text: "Permanently delete a party and all its guest records. "),
                    TextSpan(text: "This cannot be undone.", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _partyCodeTextController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _buildInputDecoration("Enter Party Code"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _pinTextController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: _buildInputDecoration("Enter Original PIN (6 digits)"),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 8),
                Text(_successMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A))),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleDeleteParty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: _isLoading
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
}

// ── Dev Tools ─────────────────────────────────────────────────────────────────
// Инструменты разработчика / тестирования
class DevToolsSection extends ConsumerStatefulWidget {
  const DevToolsSection({super.key});
  @override
  ConsumerState<DevToolsSection> createState() => _DevToolsSectionState();
}

// Состояние секции разработчика, предоставляет быстрые действия без аутентификации
class _DevToolsSectionState extends ConsumerState<DevToolsSection> {
  final TextEditingController _partyCodeTextController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _partyCodeTextController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteByCode() async {
    final String code = _partyCodeTextController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter a party code.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final PartyService partyService = ref.read(partyServiceProvider);
      await partyService.deletePartyByCode(code);
      
      setState(() {
        _successMessage = 'Party "$code" deleted (no auth).';
        _isLoading = false;
      });
      _partyCodeTextController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "DEVELOPER / TESTING TOOLS",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Delete Party by Code (No PIN)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _partyCodeTextController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Enter Party Code",
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 8),
                Text(_successMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A))),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleDeleteByCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF475569),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: _isLoading
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
}
