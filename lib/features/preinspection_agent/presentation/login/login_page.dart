import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_button.dart';
import '../../state/session_provider.dart';

String _generateCaptcha() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  final rand = Random();
  return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
}

/// Port of `LoginPage.jsx`.
///
/// The web app's two tabs pick a portal (Claim / Pre-Inspection); this app IS
/// the preinspection portal, so its tabs pick who is signing in instead --
/// an agent or a surveyor -- and every screen after login says whose id it
/// is working under (see [sessionProvider]).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  UserRole _activeTab = UserRole.agent;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _showPassword = false;
  late String _captchaText;

  String? _usernameError;
  String? _passwordError;
  String? _captchaError;

  @override
  void initState() {
    super.initState();
    _captchaText = _generateCaptcha();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _refreshCaptcha() {
    setState(() {
      _captchaText = _generateCaptcha();
      _captchaController.clear();
    });
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final captcha = _captchaController.text.trim();

    setState(() {
      _usernameError = username.isEmpty ? 'Username is required' : null;
      _passwordError = password.isEmpty ? 'Password is required' : null;
      _captchaError = captcha.isEmpty
          ? 'Captcha is required'
          : (captcha != _captchaText ? 'Captcha does not match' : null);
    });

    if (_usernameError != null ||
        _passwordError != null ||
        _captchaError != null) {
      _refreshCaptcha();
      return;
    }

    // Remember who signed in -- the dashboard greets this id by name and
    // says whether it belongs to an agent or a surveyor.
    ref
        .read(sessionProvider.notifier)
        .signIn(userId: username, role: _activeTab);
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgApp),
        child: Column(
          children: [
            const SizedBox(height: 170),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _TabButton(
                                      label: 'Agent',
                                      color: const Color(0xFFDB6F37),
                                      shadowColor: const Color(0x66E07B39),
                                      selected: _activeTab == UserRole.agent,
                                      onTap: () => setState(
                                        () => _activeTab = UserRole.agent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _TabButton(
                                      label: 'Surveyor',
                                      color: const Color(0xFF4643F9),
                                      shadowColor: const Color(0x664F46E5),
                                      selected: _activeTab == UserRole.surveyor,
                                      onTap: () => setState(
                                        () => _activeTab = UserRole.surveyor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _InputField(
                                controller: _usernameController,
                                hint: 'User Name',
                                icon: Icons.person_outline,
                                errorText: _usernameError,
                                onChanged: (_) =>
                                    setState(() => _usernameError = null),
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _passwordController,
                                hint: 'Password',
                                obscureText: !_showPassword,
                                errorText: _passwordError,
                                onChanged: (_) =>
                                    setState(() => _passwordError = null),
                                suffix: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _captchaText,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        letterSpacing: 6,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: _refreshCaptcha,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _InputField(
                                controller: _captchaController,
                                hint: 'Enter Captcha',
                                errorText: _captchaError,
                                onChanged: (_) =>
                                    setState(() => _captchaError = null),
                              ),
                              const SizedBox(height: 20),
                              BottomButton(
                                label: 'Login',
                                onPressed: _handleLogin,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text.rich(
                                TextSpan(
                                  text: 'Powered by ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          'VROOMSYNC EXPERTISE PRIVATE LIMITED',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'All Rights Reserved 2025. CIN: U62099CT2025PTC017274',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Insurance is subject matter of solicitation. Images used on the website "
                                "and the mobile photographed, in them are for representative purpose only "
                                "and are not indicative of anyone's thought.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color shadowColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? suffix;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 53,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.borderInput),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.textRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
