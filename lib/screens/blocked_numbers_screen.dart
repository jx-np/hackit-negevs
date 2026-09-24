import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedNumbersScreen extends StatefulWidget {
  const BlockedNumbersScreen({super.key});

  @override
  State<BlockedNumbersScreen> createState() => _BlockedNumbersScreenState();
}

class _BlockedNumbersScreenState extends State<BlockedNumbersScreen> {
  static const String _prefsKey = 'spam_blocked_numbers';

  final Set<String> _blocked = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey) ?? '';
    if (!mounted) return;
    setState(() {
      _blocked
        ..clear()
        ..addAll(stored.split(',').where((e) => e.isNotEmpty));
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _blocked.join(','));
  }

  Future<void> _unblock(String number) async {
    setState(() => _blocked.remove(number));
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unblocked $number')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numbers = _blocked.toList()..sort();
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Blocked Numbers'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).maybePop()),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(Icons.refresh),
            semanticsLabel: 'Refresh',
            onPress: _load,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : numbers.isEmpty
          ? _buildEmpty(context)
          : FTileGroup.builder(
              count: numbers.length,
              tileBuilder: (context, index) {
                final number = numbers[index];
                return FTile(
                  prefix: FAvatar.raw(
                    size: 36,
                    child: Icon(
                      Icons.block,
                      size: 18,
                      color: context.theme.colors.error,
                    ),
                  ),
                  title: Text(number),
                  suffix: FButton.icon(
                    onPress: () => _unblock(number),
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    child: const Icon(Icons.clear),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          const Text('No blocked numbers'),
        ],
      ),
    );
  }
}
