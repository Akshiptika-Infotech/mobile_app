import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfigScope.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState is AuthError ? authState.message : null;

    final primary = config.primaryColor;
    final primaryDark = HSLColor.fromColor(primary)
        .withLightness(
          (HSLColor.fromColor(primary).lightness - 0.18).clamp(0.05, 1.0),
        )
        .toColor();

    final size = MediaQuery.sizeOf(context);
    // Responsive header height: smaller on small phones, larger on bigger screens
    final topHeight = size.height < 600 ? size.height * 0.30 : size.height * 0.42;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Gradient background ───────────────────────────────────────────
          Container(
            height: topHeight + 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primaryDark],
              ),
            ),
          ),

          // ── Wave / bottom fill ────────────────────────────────────────────
          Positioned(
            top: topHeight + 59,
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
                color: Theme.of(context).colorScheme.surface),
          ),

          // ── Main scrollable content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Hero section — logo + school name
                SizedBox(
                  height: topHeight - MediaQuery.of(context).padding.top,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SchoolLogo(
                            logoUrl: config.logoUrl,
                            primary: primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            config.appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'School Management',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.75),
                              fontSize: 13,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Form card — slides up from below
                Expanded(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.12),
                              blurRadius: 24,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            28,
                            32,
                            28,
                            MediaQuery.of(context).viewInsets.bottom + 32,
                          ),
                          child: _FormContent(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            obscurePassword: _obscurePassword,
                            onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            onSubmit: _submit,
                            primary: primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── School logo widget ──────────────────────────────────────────────────────

class _SchoolLogo extends StatelessWidget {
  const _SchoolLogo({required this.logoUrl, required this.primary});

  final String? logoUrl;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Responsive logo size: smaller on small phones
    final logoSize = size.height < 600 ? 72.0 : 96.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? _NetworkLogo(url: logoUrl!, primary: primary)
          : _FallbackIcon(primary: primary),
    );
  }
}

class _NetworkLogo extends StatelessWidget {
  const _NetworkLogo({required this.url, required this.primary});
  final String url;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isSvg = url.toLowerCase().contains('.svg');
    if (isSvg) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => CircularProgressIndicator(
          strokeWidth: 2,
          color: primary,
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : CircularProgressIndicator(strokeWidth: 2, color: primary),
      errorBuilder: (_, __, ___) => _FallbackIcon(primary: primary),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.school_rounded, size: 48, color: primary);
  }
}

// ── Form content ────────────────────────────────────────────────────────────

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
    required this.primary,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header text
          Text(
            'Welcome back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          // Error banner
          if (errorMessage != null) ...[
            _ErrorBanner(message: errorMessage!),
            const SizedBox(height: 20),
          ],

          // Email field
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'you@school.com',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.email_outlined, color: cs.onSurfaceVariant),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha:0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha:0.5), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.error, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$').hasMatch(v.trim())) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: onTogglePassword,
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha:0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha:0.5), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.error, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required.';
              if (v.length < 6) return 'Password must be at least 6 characters.';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Sign In button — gradient
          _GradientButton(
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            primary: primary,
          ),
        ],
      ),
    );
  }
}

// ── Gradient sign-in button ─────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.primary,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final primaryDark = HSLColor.fromColor(primary)
        .withLightness(
          (HSLColor.fromColor(primary).lightness - 0.12).clamp(0.05, 1.0),
        )
        .toColor();

    return AnimatedOpacity(
      opacity: onPressed == null ? 0.65 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, primaryDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha:0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 52,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha:0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
