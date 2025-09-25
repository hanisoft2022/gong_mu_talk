import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../domain/paystub_verification.dart';

typedef JsonMap = Map<String, Object?>;

class PaystubVerificationRepository {
  PaystubVerificationRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required AuthCubit authCubit,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _authCubit = authCubit;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuthCubit _authCubit;

  DocumentReference<JsonMap> _verificationDoc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('verifications')
      .doc('paystub');

  Stream<PaystubVerification> watchVerification(String uid) {
    return _verificationDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return PaystubVerification.none;
      }
      return PaystubVerification.fromSnapshot(snapshot);
    });
  }

  Future<PaystubVerification> fetchVerification(String uid) async {
    final DocumentSnapshot<JsonMap> snapshot = await _verificationDoc(
      uid,
    ).get();
    if (!snapshot.exists) {
      return PaystubVerification.none;
    }
    return PaystubVerification.fromSnapshot(snapshot);
  }

  Future<void> uploadPaystub({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      throw StateError('로그인 후 급여 명세서를 업로드할 수 있습니다.');
    }

    final String sanitizedName = _sanitizeFileName(fileName);
    final String storagePath =
        'paystub_uploads/$uid/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    final SettableMetadata metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: <String, String>{
        'uid': uid,
        'verificationDocPath': _verificationDoc(uid).path,
        'originalFileName': sanitizedName,
      },
    );

    await _verificationDoc(uid).set(<String, Object?>{
      'status': PaystubVerificationStatus.processing.name,
      'uploadedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'detectedTrack': null,
      'detectedKeywords': const <String>[],
      'errorMessage': null,
      'storagePath': storagePath,
      'originalFileName': sanitizedName,
    });

    await _storage.ref(storagePath).putData(bytes, metadata);
  }

  String _sanitizeFileName(String fileName) {
    final String trimmed = fileName.trim();
    final String withoutSpace = trimmed.replaceAll(RegExp(r'\s+'), '_');
    return withoutSpace.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
  }
}
