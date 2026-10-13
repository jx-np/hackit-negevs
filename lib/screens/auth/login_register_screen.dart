import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  static final _emailRe = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
  );
  static final _nameRe = RegExp(r'^[A-Za-z0-9]+( [A-Za-z0-9]+)?$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _registerMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _registerMode = !_registerMode;
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final controller = context.read<AuthController>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await (_registerMode
        ? controller.register(
            email: email,
            password: password,
            displayName: _nameController.text.trim(),
          )
        : controller.login(email: email, password: password));

    // On success the AuthController flips status to signedIn and notifies
    // listeners; the _AuthGate (home) rebuilds and swaps this screen out
    // automatically. Do NOT pop here — this screen is the root route, and
    // popping it empties the navigator stack and causes a black screen.
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.authEnterEmail;
    if (!_emailRe.hasMatch(text)) return l10n.authValidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value ?? '';
    if (text.isEmpty) return l10n.authEnterPassword;
    if (_registerMode && text.length < 8) {
      return l10n.authPasswordLength;
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_registerMode) return null;
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.authEnterName;
    if (!_nameRe.hasMatch(text)) return l10n.authNameInvalid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<AuthController>();
    final busy = controller.busy;

    return Scaffold(
      appBar: AppBar(
        title: Text(_registerMode ? l10n.authCreateAccount : l10n.authSignIn),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Icon(
                  Icons.account_circle,
                  size: 88,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _registerMode
                      ? l10n.authRegisterIntro
                      : l10n.authLoginIntro,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                if (_registerMode) ...[
                  _FieldLabel(text: l10n.authYourName),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: theme.textTheme.titleMedium,
                    decoration: _fieldDecoration(l10n.authYourNameHint),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 20),
                ],
                _FieldLabel(text: l10n.authEmail),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: theme.textTheme.titleMedium,
                  decoration: _fieldDecoration(l10n.authEmailHint),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                _FieldLabel(text: l10n.authPassword),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: theme.textTheme.titleMedium,
                  decoration: _fieldDecoration(l10n.authPasswordHint).copyWith(
                    suffixIcon: IconButton(
                      iconSize: 28,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.error!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 64,
                  child: FilledButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            _registerMode ? l10n.authCreateAccount : l10n.authSignIn,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: TextButton(
                    onPressed: busy ? null : _toggleMode,
                    child: Text(
                      _registerMode
                          ? l10n.authToggleToLogin
                          : l10n.authToggleToRegister,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
