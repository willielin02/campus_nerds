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

Future launchExternalUrl(
  BuildContext context,
  String url,
) async {
  // 如果沒拿到網址就直接結束
  if (url.isEmpty) {
    debugPrint('launchExternalUrl: empty url');
    return;
  }

  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    debugPrint('launchExternalUrl: invalid url: $url');
    return;
  }

  // 強制用系統外部瀏覽器開啟（Safari / Chrome）
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}
