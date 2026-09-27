import 'package:flutter/material.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.car_repair_outlined, size: 52, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(l10n.appName, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(l10n.signInSubtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.email_outlined)),
                          validator: (value) => value == null || !value.contains('@') ? l10n.validationValidEmail : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => value == null || value.length < 6 ? l10n.validationPasswordLength : null,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.signIn),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.authRepository.signIn(email: _emailController.text, password: _passwordController.text);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _errorMessage = _authFailureText(AppLocalizations.of(context), error));
    } catch (_) {
      if (mounted) setState(() => _errorMessage = AppLocalizations.of(context).signInFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// [AuthFailure] is raised outside the widget tree, so it carries a stable key
/// instead of prose. Unknown keys fall back to the raw message.
String _authFailureText(AppLocalizations l10n, AuthFailure failure) => switch (failure.messageKey) {
  'authInvalidCredentials' => l10n.authInvalidCredentials,
  'authTooManyRequests' => l10n.authTooManyRequests,
  'authUserDisabled' => l10n.authUserDisabled,
  'authConnectionRetry' => l10n.authConnectionRetry,
  'authNoUserReturned' => l10n.authNoUserReturned,
  'authAccountInactive' => l10n.authAccountInactive,
  'authNoValidRole' => l10n.authNoValidRole,
  'noWorkshopAssigned' => l10n.noWorkshopAssigned,
  _ => failure.message,
};
