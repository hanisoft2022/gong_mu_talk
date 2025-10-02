// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:gong_mu_talk/features/community/domain/models/lounge_definitions.dart';

/// 라운지 데이터를 JSON 파일로 내보내기
void main() {
  final lounges = LoungeDefinitions.defaultLounges;
  final jsonData = lounges.map((l) => {
    'id': l.id,
    ...l.toMap(),
  }).toList();

  final file = File('lounges_export.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonData));

  print('✅ Exported ${lounges.length} lounges to lounges_export.json');
  print('📍 File location: ${file.absolute.path}');
}
