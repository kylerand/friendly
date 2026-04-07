import 'package:url_launcher/url_launcher.dart';

class Handoff {
  static Future<void> call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> text(String phoneNumber) async {
    final uri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> email(String emailAddress) async {
    final uri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
