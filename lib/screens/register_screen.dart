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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=================== REGISTRATION START ===================');
      debugPrint('Email: ${_emailController.text.trim()}');
      debugPrint('Password length: ${_passwordController.text.length}');
      
      final response = await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      debugPrint('=================== REGISTRATION RESPONSE ===================');
      debugPrint('Response details:');
      debugPrint('User: ${response.user?.email}');
      debugPrint('Session: ${response.session?.toJson()}');
      debugPrint('User ID: ${response.user?.id}');

      if (!mounted) return;

      if (response.user != null) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Verify Your Email'),
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
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                      // Show a snackbar on the login screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please check your email to verify your account before logging in.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _showPersistentError(_errorMessage!);
        });
      }
    } on AuthException catch (e) {
      debugPrint('=================== AUTH ERROR ===================');
      debugPrint('Error message: ${e.message}');
      debugPrint('Error status: ${e.statusCode}');
      debugPrint('Full error: $e');
      
      setState(() {
        switch (e.message) {
          case 'User already registered':
            _errorMessage = 'This email is already registered. Please sign in instead.';
            break;
          case 'Invalid email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'Signup email invalid':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case '{"code":"unexpected_failure","message":"Error sending confirmation email"}':
            _errorMessage = 'Account created but email confirmation is pending. Please try signing in.';
            break;
          default:
            _errorMessage = 'An error occurred: ${e.message}';
        }
        _showPersistentError(_errorMessage!);
      });
      
    } catch (e) {
      debugPrint('=================== UNEXPECTED ERROR ===================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error details: $e');
      
      setState(() => _errorMessage = 'An unexpected error occurred: $e');
      
      if (mounted) {
        _showPersistentError(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPersistentError(String message) {
    // Show a persistent error dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Error'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    
    // Also show a long-duration snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to get started',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
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
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushNamed(context, '/phone-login'),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
