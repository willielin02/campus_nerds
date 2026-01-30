// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future launchExternalUrl2(
  BuildContext context,
  String url,
) async {
  // 1) 檢查字串
  if (url.isEmpty) {
    debugPrint('launchExternalUrl: empty url');
    return;
  }

  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    debugPrint('launchExternalUrl: invalid url: $url');
    return;
  }

  // 3) 在手機上用 url_launcher 開外部瀏覽器 (Safari / Chrome)
  if (!await canLaunchUrl(uri)) {
    debugPrint('launchExternalUrl: cannot launch url: $uri');
    return;
  }

  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
