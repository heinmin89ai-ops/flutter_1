import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';
import '../../../core/errors/localized_failure.dart';
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
  final _confirmController = TextEditingController();
  final _invitationController = TextEditingController();
  bool _isActivating = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _invitationController.dispose();
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
                        Text(
                          _isActivating ? l10n.activateAccountTitle : l10n.appName,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isActivating ? l10n.activateAccountSubtitle : l10n.signInSubtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(labelText: l10n.emailLabel, prefixIcon: const Icon(Icons.email_outlined)),
                          validator: (value) => value == null || !value.contains('@') ? l10n.validationValidEmail : null,
                        ),
                        if (_isActivating) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _invitationController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.invitationCodeLabel,
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            validator: (value) => value == null || value.trim().length < 6
                                ? l10n.validationEnterInvitationCode
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: _isActivating ? TextInputAction.next : TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _isActivating ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        if (_isActivating) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.confirmPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (value) => value != _passwordController.text
                                ? l10n.validationPasswordMismatch
                                : null,
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(_isActivating ? l10n.activateAccount : l10n.signIn),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isSubmitting ? null : _toggleMode,
                          child: Text(_isActivating ? l10n.signInInstead : l10n.haveAnInvitation),
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

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.validationEnterPassword;
    // Existing accounts were created before the length check existed, so only
    // activation demands a strong password.
    if (_isActivating && value.length < 8) return l10n.authWeakPassword;
    return null;
  }

  void _toggleMode() {
    setState(() {
      _isActivating = !_isActivating;
      _errorMessage = null;
      _confirmController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      if (_isActivating) {
        await widget.authRepository.activate(
          email: _emailController.text,
          password: _passwordController.text,
          invitationCode: _invitationController.text.toUpperCase(),
        );
      } else {
        await widget.authRepository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on LocalizedFailure catch (error) {
      if (mounted) setState(() => _errorMessage = localizedFailureMessage(l10n, error));
    } catch (_) {
      if (mounted) setState(() => _errorMessage = l10n.signInFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
