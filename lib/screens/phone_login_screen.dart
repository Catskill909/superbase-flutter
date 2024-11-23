import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_text_field.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _showOTPField = false;
  String? _errorMessage;
  String? _currentPhone;

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      debugPrint('Sending OTP to phone: $phone');
      
      await SupabaseService.signInWithPhone(phone: phone);
      
      if (!mounted) return;
      
      setState(() {
        _showOTPField = true;
        _currentPhone = phone;
        _errorMessage = null;
      });

    } on AuthException catch (e) {
      debugPrint('Auth Exception during phone login: ${e.message}');
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('Unexpected error during phone login: $e');
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Verifying OTP for phone: $_currentPhone');
      
      final response = await SupabaseService.verifyPhoneOTP(
        phone: _currentPhone!,
        token: _otpController.text.trim(),
      );
      
      if (!mounted) return;

      if (response.session != null) {
        debugPrint('Phone verification successful');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        setState(() => _errorMessage = 'Invalid verification code');
      }

    } on AuthException catch (e) {
      debugPrint('Auth Exception during OTP verification: ${e.message}');
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('Unexpected error during OTP verification: $e');
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the verification code';
    }
    if (value.length != 6) {
      return 'Verification code must be 6 digits';
    }
    return null;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Phone Login',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!_showOTPField) ...[
                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Verification Code',
                    hint: 'Enter the 6-digit code',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    validator: _validateOTP,
                  ),
                ],
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : (_showOTPField ? _verifyOTP : _sendOTP),
                  child: _isLoading
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        )
                      : Text(_showOTPField ? 'Verify Code' : 'Send Code'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Use Email Instead'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
