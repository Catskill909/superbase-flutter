import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_snackbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final userName = SupabaseService.getUserName() ?? 'User';
    final displayId = user?.phone ?? user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                debugPrint('Signing out user: $displayId');
                await SupabaseService.signOut();
                
                if (context.mounted) {
                  // Explicitly navigate back to login screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                debugPrint('Error signing out: $e');
                if (context.mounted) {
                  showCustomSnackbar(
                    context: context,
                    message: 'Error signing out. Please try again.',
                    isSuccess: false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 96,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                displayId,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              const Text(
                'You have successfully signed in with Supabase.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
