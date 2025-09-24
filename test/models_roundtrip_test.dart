import 'package:flutter_test/flutter_test.dart';

import 'package:gong_mu_talk/features/profile/domain/user_doc.dart';

void main() {
  test('UserDoc roundtrip toJson/fromJson', () {
    final DateTime now = DateTime.now();
    final UserDoc src = UserDoc(
      uid: 'u1',
      nickname: '닉',
      serial: 'general',
      department: '행안부',
      region: '서울',
      role: 'member',
      createdAt: now,
      blocked: false,
    );
    final Map<String, Object?> json = src.toJson();
    final UserDoc back = UserDoc.fromJson('u1', json);
    expect(back.uid, src.uid);
    expect(back.nickname, src.nickname);
    expect(back.serial, src.serial);
    expect(back.department, src.department);
    expect(back.region, src.region);
    expect(back.role, src.role);
    expect(back.blocked, src.blocked);
  });
}


