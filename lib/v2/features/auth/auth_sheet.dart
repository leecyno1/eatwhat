import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens the eatwhat login/register sheet in the night palette.
///
/// Returns `true` when the user ends up signed in (fresh login or register),
/// `false` when the sheet is dismissed without an account. [reason] renders
/// as a lead-in strip — e.g. the ordering flow passes 下单提示.
Future<bool> showEatWhatAuthSheet(
  BuildContext context, {
  String? reason,
}) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.night.withValues(alpha: 0.72),
    builder: (context) => _EatWhatAuthSheet(reason: reason),
  );
  return signedIn ?? false;
}

/// Opens the signed-in account sheet: identity, membership card, and logout.
Future<void> showEatWhatAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.night.withValues(alpha: 0.72),
    builder: (context) => const _EatWhatAccountSheet(),
  );
}

class _EatWhatAuthSheet extends StatefulWidget {
  const _EatWhatAuthSheet({this.reason});

  final String? reason;

  @override
  State<_EatWhatAuthSheet> createState() => _EatWhatAuthSheetState();
}

class _EatWhatAuthSheetState extends State<_EatWhatAuthSheet> {
  static const _modeLogin = 0;
  static const _modeRegister = 1;

  int _mode = _modeLogin;
  bool _submitting = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    AuthResult result;
    if (_mode == _modeLogin) {
      result = await AuthService.login(
        usernameOrEmail: _usernameController.text.trim(),
        password: _passwordController.text,
        rememberMe: true,
      );
    } else {
      result = await AuthService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
      );
    }

    if (!mounted) return;
    if (result.success) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        key: const ValueKey('eatwhat-auth-sheet'),
        decoration: const BoxDecoration(
          color: AppPalette.nightSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
          border: Border(top: BorderSide(color: AppPalette.nightDivider)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.reason != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.leaf.withValues(alpha: 0.12),
                        borderRadius: AppRadii.small,
                        border: Border.all(
                          color: AppPalette.leaf.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        widget.reason!,
                        textAlign: TextAlign.center,
                        style: AppTypeNight.label.copyWith(
                          color: AppPalette.leaf,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _buildIdentity(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildModeTabs(),
                  const SizedBox(height: AppSpacing.lg),
                  if (_mode == _modeLogin) ..._buildLoginFields(),
                  if (_mode == _modeRegister) ..._buildRegisterFields(),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: AppTypeNight.label
                          .copyWith(color: const Color(0xFFE4513F)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppPalette.nightElevated,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppPalette.nightDivider),
            ),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            size: 22,
            color: AppPalette.leaf,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('吃什么账号', style: AppTypeNight.section),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _mode == _modeLogin ? '登录后继续' : '注册即自动登录',
          style: AppTypeNight.body,
        ),
      ],
    );
  }

  Widget _buildModeTabs() {
    Widget tab(int mode, String label) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _mode = mode;
            _error = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppPalette.leaf.withValues(alpha: 0.14)
                  : AppPalette.nightElevated,
              borderRadius: AppRadii.small,
              border: Border.all(
                color: selected ? AppPalette.leaf : AppPalette.nightDivider,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypeNight.label.copyWith(
                color: selected ? AppPalette.leaf : AppPalette.moonMuted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(_modeLogin, '登录'),
        const SizedBox(width: AppSpacing.sm),
        tab(_modeRegister, '注册'),
      ],
    );
  }

  List<Widget> _buildLoginFields() {
    return [
      _NightFormField(
        key: const ValueKey('auth-login-username'),
        controller: _usernameController,
        label: '用户名 / 邮箱',
        hint: '输入用户名或邮箱',
        prefixIcon: Icons.person_outline_rounded,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? '请输入用户名或邮箱' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      _NightFormField(
        key: const ValueKey('auth-login-password'),
        controller: _passwordController,
        label: '密码',
        hint: '输入密码',
        prefixIcon: Icons.lock_outline_rounded,
        obscure: true,
        validator: (value) =>
            (value == null || value.isEmpty) ? '请输入密码' : null,
      ),
    ];
  }

  List<Widget> _buildRegisterFields() {
    return [
      _NightFormField(
        key: const ValueKey('auth-register-username'),
        controller: _usernameController,
        label: '用户名',
        hint: '中文、字母、数字（即昵称）',
        prefixIcon: Icons.person_outline_rounded,
        validator: (value) {
          final name = value?.trim() ?? '';
          if (name.isEmpty) return '请输入用户名';
          if (name.length < 3) return '用户名至少 3 个字符';
          if (!RegExp(r'^[a-zA-Z0-9_\u4e00-\u9fa5]+$').hasMatch(name)) {
            return '仅支持中文、字母、数字和下划线';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.md),
      _NightFormField(
        key: const ValueKey('auth-register-email'),
        controller: _emailController,
        label: '邮箱',
        hint: '用于找回密码',
        prefixIcon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          final email = value?.trim() ?? '';
          if (email.isEmpty) return '请输入邮箱';
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
            return '邮箱格式不正确';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.md),
      _NightFormField(
        key: const ValueKey('auth-register-password'),
        controller: _passwordController,
        label: '密码',
        hint: '至少 8 位，含大小写字母和数字',
        prefixIcon: Icons.lock_outline_rounded,
        obscure: true,
        validator: (value) {
          final password = value ?? '';
          if (password.isEmpty) return '请输入密码';
          if (password.length < 8) return '密码至少 8 位';
          if (!password.contains(RegExp(r'[A-Z]')) ||
              !password.contains(RegExp(r'[a-z]')) ||
              !password.contains(RegExp(r'[0-9]'))) {
            return '需包含大小写字母和数字';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.md),
      _NightFormField(
        key: const ValueKey('auth-register-confirm'),
        controller: _confirmController,
        label: '确认密码',
        hint: '再输入一次密码',
        prefixIcon: Icons.lock_outline_rounded,
        obscure: true,
        validator: (value) =>
            (value ?? '') != _passwordController.text ? '两次密码不一致' : null,
      ),
    ];
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        key: ValueKey(
          _mode == _modeLogin ? 'auth-login-submit' : 'auth-register-submit',
        ),
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.leaf,
          foregroundColor: AppPalette.night,
          disabledBackgroundColor: AppPalette.nightElevated,
          disabledForegroundColor: AppPalette.moonMuted,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
          elevation: 0,
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppPalette.night),
                ),
              )
            : Text(
                _mode == _modeLogin ? '登录' : '注册并登录',
                style: AppTypeNight.label
                    .copyWith(fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

/// Night-styled form field shared by the login and register forms.
class _NightFormField extends StatelessWidget {
  const _NightFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.validator,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final FormFieldValidator<String> validator;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypeNight.microLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: AppTypeNight.label.copyWith(color: AppPalette.moonlight),
          cursorColor: AppPalette.leaf,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypeNight.label.copyWith(color: AppPalette.moonMuted),
            prefixIcon: Icon(prefixIcon, size: 18, color: AppPalette.moonMuted),
            filled: true,
            fillColor: AppPalette.nightElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.small,
              borderSide: const BorderSide(color: AppPalette.nightDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.small,
              borderSide: const BorderSide(color: AppPalette.leaf, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadii.small,
              borderSide: const BorderSide(color: Color(0xFFE4513F)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadii.small,
              borderSide: const BorderSide(color: Color(0xFFE4513F), width: 1.5),
            ),
            errorStyle: AppTypeNight.microLabel
                .copyWith(color: const Color(0xFFE4513F)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

/// Signed-in account sheet: identity, membership card, logout.
class _EatWhatAccountSheet extends StatelessWidget {
  const _EatWhatAccountSheet();

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.logout();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppPalette.nightSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('尚未登录', style: AppTypeNight.section),
            const SizedBox(height: AppSpacing.sm),
            Text('登录后可保存偏好与订单', style: AppTypeNight.body),
          ],
        ),
      );
    }

    final initial = user.nickname.isNotEmpty ? user.nickname.characters.first : '吃';

    return Container(
      key: const ValueKey('eatwhat-account-sheet'),
      decoration: const BoxDecoration(
        color: AppPalette.nightSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
        border: Border(top: BorderSide(color: AppPalette.nightDivider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppPalette.leaf.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppPalette.leaf.withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: AppTypeNight.section
                          .copyWith(color: AppPalette.leaf),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.nickname, style: AppTypeNight.section),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: AppTypeNight.microLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _MembershipCard(user: user),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  key: const ValueKey('auth-logout-button'),
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE4513F),
                    side: const BorderSide(
                      color: Color(0xFFE4513F),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.capsule,
                    ),
                  ),
                  child: const Text('退出登录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Membership card in the account sheet. Standard accounts see the upgrade
/// teaser; member accounts see the tier badge and join date.
class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final member = user.isMember;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: member
            ? AppPalette.leaf.withValues(alpha: 0.12)
            : AppPalette.nightElevated,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: member
              ? AppPalette.leaf.withValues(alpha: 0.45)
              : AppPalette.nightDivider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            member ? Icons.workspace_premium_rounded : Icons.card_membership,
            size: 26,
            color: member ? AppPalette.leaf : AppPalette.moonMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member ? '吃什么会员' : '标准账号',
                  style: AppTypeNight.label.copyWith(
                    color: member ? AppPalette.leaf : AppPalette.moonlight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member
                      ? (user.memberSince != null
                          ? '会员有效期与权益以正式上线为准 · ${user.memberSince!.year} 年加入'
                          : '会员权益以正式上线为准')
                      : '会员体系即将上线，敬请期待',
                  style: AppTypeNight.microLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
