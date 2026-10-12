import 'package:call_log_app/main.dart';
import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permissions_tab.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  bool _requested = false;
  int _refreshToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestRuntime());
  }

  Future<void> _requestRuntime() async {
    if (_requested) return;
    _requested = true;
    await <Permission>[
      Permission.notification,
      Permission.phone,
      Permission.contacts,
    ].request();
    if (!mounted) return;
    setState(() => _refreshToken++);
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Column(
        children: [
          Expanded(child: PermissionsTab(key: ValueKey(_refreshToken))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(l10n.onboardingContinue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
