import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

String extractBaseDomain(String email) {
  if (!email.contains('@')) return '';
  final domain = email.split('@').last.toLowerCase();
  final parts = domain.split('.');

  if (domain.endsWith('.edu.tw')) {
    // gs.ncku.edu.tw / mail.ncku.edu.tw -> ncku.edu.tw
    if (parts.length >= 3) {
      return parts.sublist(parts.length - 3).join('.');
    } else {
      return domain;
    }
  } else {
    // 其他網域：先取最後兩段，例如 mit.edu -> mit.edu
    if (parts.length >= 2) {
      return parts.sublist(parts.length - 2).join('.');
    } else {
      return domain;
    }
  }
}

bool newCustomFunction(
  String email,
  List<String> allowedDomains,
) {
  // 1. 清掉前後空白並改成小寫
  final cleanedEmail = email.trim().toLowerCase();

  // 2. 拆成「帳號」跟「網域」
  final parts = cleanedEmail.split('@');
  if (parts.length != 2) {
    // 格式錯誤，直接視為不支援
    return false;
  }

  final emailDomain = parts[1]; // e.g. "gs.ncku.edu.tw" 或 "ncku.edu.tw"

  // 3. 檢查是否在 allowedDomains 裡
  //    - 完全相等：   "ncku.edu.tw"
  //    - 或是尾巴一樣："gs.ncku.edu.tw" endsWith ".ncku.edu.tw"
  for (final rawDomain in allowedDomains) {
    final domain = rawDomain.trim().toLowerCase();
    if (domain.isEmpty) continue;

    if (emailDomain == domain || emailDomain.endsWith('.$domain')) {
      return true;
    }
  }

  // 沒找到符合的網域 => 不支援
  return false;
}
