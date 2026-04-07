import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static Future<void> shareInviteLink(String displayName) async {
    await Share.share(
      '$displayName wants to be your friend on Friendly! Download the app to connect.',
      subject: 'Join me on Friendly',
    );
  }
}
