import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  static const String _phoneLoginRoute = '/phone-login';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=================== REGISTRATION START ===================');
      debugPrint('Name: ${_nameController.text.trim()}');
      debugPrint('Email: ${_emailController.text.trim()}');
      debugPrint('Password length: ${_passwordController.text.length}');
      
      final response = await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      
      debugPrint('=================== REGISTRATION RESPONSE ===================');
      debugPrint('Response details:');
      debugPrint('User: ${response.user?.email}');
      debugPrint('Session: ${response.session?.toJson()}');
      debugPrint('User ID: ${response.user?.id}');

      if (!mounted) return;

      if (response.user != null) {
        // Show verification dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.mark_email_read, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Verify Your Email'),
                ],
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('We sent a verification email to: ${response.user!.email}'),
                    const SizedBox(height: 10),
                    const Text('Please check your email and click the verification link to complete your registration.'),
                    const SizedBox(height: 10),
                    const Text('After confirming your email, you can log in to your account.'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Navigate to login screen
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      debugPrint('=================== AUTH ERROR ===================');
      debugPrint('Error message: ${e.message}');
      debugPrint('Error status: ${e.statusCode}');
      debugPrint('Full error: $e');
      
      setState(() {
        _isLoading = false;
        if (e.message.contains('Invalid username format')) {
          _showUsernameFormatError(context);
        } else {
          switch (e.message) {
            case 'User already registered':
              _errorMessage = 'This email is already registered. Please sign in instead.';
              break;
            case 'Invalid email':
            case 'Signup email invalid':
              _errorMessage = 'Please enter a valid email address.';
              break;
            case '{"code":"unexpected_failure","message":"Error sending confirmation email"}':
              _errorMessage = 'Account created but email confirmation is pending. Please try signing in.';
              break;
            default:
              _errorMessage = 'An error occurred: ${e.message}';
          }
        }
      });
    } catch (e) {
      debugPrint('=================== UNEXPECTED ERROR ===================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error details: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  Future<void> _showUsernameFormatError(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('Invalid Username Format'),
            ],
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Your username must:'),
                SizedBox(height: 8),
                Text('• Contain only letters and numbers'),
                Text('• No spaces allowed'),
                Text('• No special characters'),
                SizedBox(height: 12),
                Text('Examples of valid usernames:'),
                Text('• john123'),
                Text('• TechUser'),
                Text('• ADMIN2024'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  Future<String?> _showPhoneInputDialog(BuildContext context) {
    final phoneController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, phoneController.text.trim());
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showAlreadyRegisteredDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Phone Already Registered'),
          content: const Text(
            'This phone number is already registered. Would you like to log in instead?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false); // Don't navigate to login
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true); // Navigate to login
              },
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToPhoneLogin() async {
    if (!mounted) return;
    await Navigator.pushNamed(context, _phoneLoginRoute);
  }

  Future<void> _navigateToPhoneLoginReplacement() async {
    if (!mounted) return;
    await Navigator.pushReplacementNamed(context, _phoneLoginRoute);
  }

  Future<void> _handlePhoneRegistration() async {
    if (!mounted) return;

    final phoneNumber = await _showPhoneInputDialog(context);
    if (!mounted || phoneNumber == null || phoneNumber.isEmpty) return;

    final isRegistered = await SupabaseService.isPhoneRegistered(phoneNumber);
    if (!mounted) return;

    if (isRegistered) {
      final shouldNavigateToLogin = await _showAlreadyRegisteredDialog(context);
      if (!mounted) return;
      
      if (shouldNavigateToLogin ?? false) {
        await _navigateToPhoneLoginReplacement();
      }
    } else {
      await _navigateToPhoneLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Name Field
                CustomTextField(
                  label: 'Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (!SupabaseService.isValidName(value)) {
                      return 'Name must be 2-50 characters and contain only letters, numbers, spaces, hyphens, or apostrophes';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
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
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  isPassword: true,
                  textCapitalization: TextCapitalization.none,
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
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _handlePhoneRegistration,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text('Continue with Phone'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
