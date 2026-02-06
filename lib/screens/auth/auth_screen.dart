import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../dashboard/dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_tabController.index == 0) {
      // Login
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      // Register
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
    }

    if (success && mounted) {
      // Set userId in LanguageProvider to load/save language preference
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      await languageProvider.setUserId(authProvider.userId);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (authProvider.error != null && mounted) {
      _showErrorSnackBar(authProvider.error!);
      authProvider.clearError();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLanguageSheet(),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('Please enter your email address first');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success =
        await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (authProvider.error != null && mounted) {
      _showErrorSnackBar(authProvider.error!);
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.backgroundLight,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Language Switch
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildLanguageButton(),
                  ),

                  const SizedBox(height: 40),

                  // Logo and Title
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // Auth Card
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Tab Bar
                        _buildTabBar(),

                        const SizedBox(height: 32),

                        // Tab Content
                        AnimatedSize(
                          duration: AppConstants.animationNormal,
                          curve: Curves.easeInOut,
                          child: _buildTabContent(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showLanguageDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                languageProvider.languageName,
                style: AppTextStyles.labelMedium(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: const Icon(
            Icons.store_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CITY VAPE',
          style: AppTextStyles.headingLarge().copyWith(
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back! Please sign in to continue',
          style: AppTextStyles.bodyMedium(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondaryLight,
        labelStyle: AppTextStyles.labelLarge(),
        unselectedLabelStyle: AppTextStyles.labelLarge(),
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Register'),
        ],
        onTap: (index) => setState(() {}),
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Show name field only for register
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  InputField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: _tabController.index == 1
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              crossFadeState: _tabController.index == 1
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppConstants.animationNormal,
            ),

            InputField(
              label: 'Email',
              hint: 'Enter your email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            InputField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleAuth(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            // Forgot password (login only)
            AnimatedCrossFade(
              firstChild: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.labelMedium(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox(height: 8),
              crossFadeState: _tabController.index == 0
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: AppConstants.animationNormal,
            ),

            const SizedBox(height: 24),

            // Submit Button
            PrimaryButton(
              text: _tabController.index == 0 ? 'Login' : 'Create Account',
              onPressed: _handleAuth,
              isLoading: authProvider.isLoading,
              variant: ButtonVariant.gradient,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSheet() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.language,
            style: AppTextStyles.headingSmall(),
          ),
          const SizedBox(height: 24),

          // English Option
          _buildLanguageOption(
            title: 'English',
            subtitle: 'English',
            isSelected: languageProvider.isEnglish,
            onTap: () async {
              await languageProvider.setEnglish();
              if (mounted) Navigator.pop(context);
            },
          ),

          const SizedBox(height: 12),

          // Arabic Option
          _buildLanguageOption(
            title: 'العربية',
            subtitle: 'Arabic',
            isSelected: languageProvider.isArabic,
            onTap: () async {
              await languageProvider.setArabic();
              if (mounted) Navigator.pop(context);
            },
          ),

          SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium(
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
