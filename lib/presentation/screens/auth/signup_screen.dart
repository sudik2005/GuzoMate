import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/presentation/widgets/mesh_gradient_background.dart';
import 'package:byure/services/user_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/core/theme/app_theme.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  
  Gender _selectedGender = Gender.male;
  GenderPreference _selectedPreference = GenderPreference.women;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final authUser = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      // Create user profile
      final userService = UserService();
      final user = UserEntity(
        id: authUser.id,
        email: authUser.email,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        interests: [],
        photoUrls: [],
        walkingPreferences: WalkingPreferences(
          pace: WalkingPace.moderate,
          preferredDistanceKm: 5.0,
          preferredTerrains: [TerrainType.urban],
          preferredTimes: [],
        ),
        isAvailableToWalk: false,
        isPremium: false,
        createdAt: DateTime.now(),
        safetySettings: SafetySettings(
          shareLocationWithTrustedContacts: false,
          trustedContactIds: [],
          enableSOS: true,
        ),
        gender: _selectedGender,
        genderPreference: _selectedPreference,
      );

      await userService.createOrUpdateUser(user);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradientColors = isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
        : [const Color(0xFFE0F7FA), const Color(0xFFE8F5E9)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: MeshGradientBackground(
        isDark: isDark,
        child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _animController,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join the walking community',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Name
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                isDark: isDark,
                                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                              ),
                              const SizedBox(height: 16),

                              // Email
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                isDark: isDark,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!value.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Age
                              _buildTextField(
                                controller: _ageController,
                                label: 'Age',
                                icon: Icons.calendar_today_rounded,
                                isDark: isDark,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your age';
                                  final age = int.tryParse(value);
                                  if (age == null || age < 18 || age > 100) return 'Age must be 18+';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Gender Dropdown
                              DropdownButtonFormField<Gender>(
                                value: _selectedGender,
                                decoration: InputDecoration(
                                  labelText: 'I am a',
                                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
                                  filled: true,
                                  fillColor: isDark ? Colors.black26 : Colors.white70,
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                items: Gender.values.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(g.name[0].toUpperCase() + g.name.substring(1)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedGender = val!),
                              ),
                              const SizedBox(height: 16),

                              // Preference Dropdown
                              DropdownButtonFormField<GenderPreference>(
                                value: _selectedPreference,
                                decoration: InputDecoration(
                                  labelText: 'Prefer walking with',
                                  prefixIcon: Icon(Icons.favorite, color: AppTheme.primaryGreen),
                                  filled: true,
                                  fillColor: isDark ? Colors.black26 : Colors.white70,
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                items: GenderPreference.values.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedPreference = val!),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                obscureText: _obscurePassword,
                                onSuffixIconPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Password is required';
                                  if (value.length < 6) return 'Minimum 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                obscureText: _obscureConfirmPassword,
                                onSuffixIconPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please confirm password';
                                  if (value != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              // Sign Up Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Create Account', style: TextStyle(fontSize: 18)),
                                ),
                              ),


                              const SizedBox(height: 24),
                              
                              // Sign In Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/auth/login'),
                                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
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
          ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    VoidCallback? onSuffixIconPressed,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.white70,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: onSuffixIconPressed,
              )
            : null,
      ),
    );
  }
}
