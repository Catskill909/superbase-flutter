import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkHandler {
  static final _appLinks = AppLinks();
  
  static void initialize(BuildContext context) {
    // Listen to incoming deep links when app is running
    _appLinks.uriLinkStream.listen((uri) {
      if (context.mounted) {
        _handleDeepLink(uri, context);
      }
    });

    // Handle any initial URI
    _appLinks.getInitialAppLink().then((uri) {
      if (context.mounted) {
        _handleDeepLink(uri, context);
      }
    });
  }

  static Future<void> _handleDeepLink(Uri? uri, BuildContext context) async {
    if (uri == null) return;

    try {
      // Check if this is an email confirmation link
      if (uri.fragment.contains('type=recovery') || uri.fragment.contains('type=signup')) {
        final uriParameters = Uri.parse('?${uri.fragment}').queryParameters;
        
        if (uriParameters['error_description'] != null) {
          if (context.mounted) {
            _showMessage(context, 'Error: ${uriParameters['error_description']}');
          }
          return;
        }

        // Get access token from URL parameters
        final accessToken = uriParameters['access_token'];
        final refreshToken = uriParameters['refresh_token'];
        
        if (accessToken != null && refreshToken != null) {
          // Set the session in Supabase
          await Supabase.instance.client.auth.setSession(accessToken);
          
          if (context.mounted) {
            _showMessage(context, 'Email confirmed successfully!');
            // Navigate to root route and let the auth state handle navigation
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Error processing link: $e');
      }
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
