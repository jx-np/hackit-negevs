import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
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

  AuthController? _auth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthController>();
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth..addListener(_onAuthChanged);
    }
  }

  /// When sign-in succeeds while this screen was *pushed* on top of the app
  /// (via [requireLogin]), pop it so the caller resumes. When it's the root
  /// route there's nothing to pop, so we leave it — the host rebuilds and
  /// swaps it out. Popping the root would empty the stack and show a black
  /// screen, so [canPop] guards against that.
  void _onAuthChanged() {
    if (mounted && _auth?.isSignedIn == true && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
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
            locale: _backendLocale(context),
          )
        : controller.login(email: email, password: password));

    // On a successful sign-in, commit the autofill context so the platform's
    // password manager offers to save (or update) the credentials the user
    // just submitted. On failure the context stays open so the manager can
    // still fill on the retry.
    if (controller.isSignedIn) {
      TextInput.finishAutofillContext();
    }

    // On success the AuthController flips status to signedIn and notifies
    // listeners. We handle the result in _onAuthChanged: if this screen was
    // pushed (by requireLogin) it pops itself; if it's the root route it stays
    // and the host rebuilds. Do NOT pop here directly — _onAuthChanged guards
    // against popping the root route (which would cause a black screen).
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

  /// The backend locale tag to register with, based on the in-app language.
  ///
  /// [Localizations.localeOf] gives the locale the app is actually showing —
  /// the user's in-app override when set, otherwise the device default already
  /// resolved against our supported locales. The backend expects a full tag
  /// (e.g. `en-SG`); we only vary the language and keep the `SG` region, and
  /// fall back to `en-SG` for anything unexpected.
  String _backendLocale(BuildContext context) {
    const Set<String> supported = {'en', 'zh', 'ta', 'ms'};
    final String language = Localizations.localeOf(context).languageCode;
    if (!supported.contains(language)) return 'en-SG';
    return '$language-SG';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<AuthController>();
    final busy = controller.busy;

    return AppScreen(
      title: _registerMode ? l10n.authCreateAccount : l10n.authSignIn,
      scrollable: true,
      body: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: context.tokens.space.sm),
                Icon(
                  LucideIcons.circleUserRound,
                  size: 88,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: context.tokens.space.lg),
                Text(
                  _registerMode
                      ? l10n.authRegisterIntro
                      : l10n.authLoginIntro,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: context.tokens.space.xl2),
                if (_registerMode) ...[
                  _FieldLabel(text: l10n.authYourName),
                  SizedBox(height: context.tokens.space.sm),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    style: theme.textTheme.titleMedium,
                    decoration: _fieldDecoration(l10n.authYourNameHint),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateName,
                  ),
                  SizedBox(height: context.tokens.space.xl),
                ],
                _FieldLabel(text: l10n.authEmail),
                SizedBox(height: context.tokens.space.sm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  style: theme.textTheme.titleMedium,
                  decoration: _fieldDecoration(l10n.authEmailHint),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateEmail,
                ),
                SizedBox(height: context.tokens.space.xl),
                _FieldLabel(text: l10n.authPassword),
                SizedBox(height: context.tokens.space.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: [
                    _registerMode
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!busy) _submit();
                  },
                  style: theme.textTheme.titleMedium,
                  decoration: _fieldDecoration(l10n.authPasswordHint).copyWith(
                    suffixIcon: IconButton(
                      iconSize: 28,
                      icon: Icon(
                        _obscurePassword
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                if (controller.error != null) ...[
                  SizedBox(height: context.tokens.space.xl),
                  Container(
                    padding: EdgeInsets.all(context.tokens.space.lg),
                    decoration: BoxDecoration(
                      color: context.tokens.risk.dangerContainer,
                      borderRadius: context.tokens.radii.mdRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          color: context.tokens.risk.onDangerContainer,
                          size: 28,
                        ),
                        SizedBox(width: context.tokens.space.md),
                        Expanded(
                          child: Text(
                            controller.error!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.tokens.risk.onDangerContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: context.tokens.space.xl2),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                    ),
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            _registerMode ? l10n.authCreateAccount : l10n.authSignIn,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                  ),
                ),
                SizedBox(height: context.tokens.space.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: busy ? null : _toggleMode,
                    child: Text(
                      _registerMode
                          ? l10n.authToggleToLogin
                          : l10n.authToggleToRegister,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
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
        borderRadius: context.tokens.radii.mdRadius,
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
