import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state.dart';
import '../models.dart';
import '../services/guest_service.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final TextEditingController _guestNameTextController = TextEditingController();
  final TextEditingController _guestDishTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _handleAddGuest(String partyId) async {
    final String name = _guestNameTextController.text.trim();
    final String dish = _guestDishTextController.text.trim();
    if (name.isEmpty || dish.isEmpty) return;

    final GuestService guestService = ref.read(guestServiceProvider);
    await guestService.addGuest(partyId, name, dish);

    _guestNameTextController.clear();
    _guestDishTextController.clear();
  }

  @override
  void dispose() {
    _guestNameTextController.dispose();
    _guestDishTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Party? party = ref.watch(currentPartyProvider);
    final String partyId = party?.id ?? '';
    final String partyCode = party?.partyCode ?? 'UNKNOWN';
    final GuestService guestService = ref.watch(guestServiceProvider);

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
                                    controller: _guestNameTextController,
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
                                  controller: _guestDishTextController,
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
                                    onPressed: () => _handleAddGuest(partyId),
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
                                    _guestNameTextController.clear();
                                    _guestDishTextController.clear();
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
                    // Stream of Guests from GuestService
                    StreamBuilder<List<GuestEntry>>(
                      stream: guestService.getGuestsStream(partyId),
                      builder: (BuildContext context, AsyncSnapshot<List<GuestEntry>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        final List<GuestEntry> entries = snapshot.data ?? [];

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
                              separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 12),
                              itemBuilder: (BuildContext context, int index) {
                                final GuestEntry entry = entries[index];
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
  late TextEditingController _editDishTextController;

  @override
  void initState() {
    super.initState();
    _editDishTextController = TextEditingController(text: widget.entry.dish);
  }

  @override
  void didUpdateWidget(GuestListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.dish != widget.entry.dish && !_isEditing) {
      _editDishTextController.text = widget.entry.dish;
    }
  }

  @override
  void dispose() {
    _editDishTextController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateGuest() async {
    final String newDish = _editDishTextController.text.trim();
    if (newDish.isNotEmpty) {
      final GuestService guestService = ref.read(guestServiceProvider);
      await guestService.updateGuestDish(widget.entry.id, newDish);
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _handleDeleteGuest() async {
    final GuestService guestService = ref.read(guestServiceProvider);
    await guestService.deleteGuest(widget.entry.id);
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
              child: TextField(
                controller: _editDishTextController,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: _handleUpdateGuest,
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
                    _editDishTextController.text = widget.entry.dish;
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
    final String char = widget.entry.guestName.isNotEmpty ? widget.entry.guestName[0].toUpperCase() : '?';
    final List<Color> colors = [
      const Color(0xFFF87171), // Red
      const Color(0xFFA78BFA), // Purple
      const Color(0xFF60A5FA), // Blue
      const Color(0xFF34D399), // Green
      const Color(0xFFFBBF24), // Yellow
    ];
    final int colorIndex = char.codeUnitAt(0) % colors.length;
    final Color avatarColor = colors[colorIndex];

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
            onPressed: _handleDeleteGuest,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}
