import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to check for duplicate likes from the same user
Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  print('🔍 Checking for duplicate likes...\n');

  // Get all likes
  final likesSnapshot = await firestore.collection('likes').get();

  // Group by postId
  final Map<String, List<String>> postLikes = {};
  final Map<String, List<String>> userLikes = {};

  for (var doc in likesSnapshot.docs) {
    final data = doc.data();
    final postId = data['postId'] as String;
    final uid = data['uid'] as String;

    postLikes.putIfAbsent(postId, () => []).add(uid);
    userLikes.putIfAbsent('$postId|$uid', () => []).add(doc.id);
  }

  // Check for duplicates
  int duplicateCount = 0;
  for (var entry in userLikes.entries) {
    if (entry.value.length > 1) {
      final parts = entry.key.split('|');
      print('❌ DUPLICATE LIKE FOUND!');
      print('   Post: ${parts[0]}');
      print('   User: ${parts[1]}');
      print('   Count: ${entry.value.length}');
      print('   Document IDs: ${entry.value}');
      print('');
      duplicateCount++;
    }
  }

  if (duplicateCount == 0) {
    print('✅ No duplicate likes found!');
  } else {
    print('⚠️  Found $duplicateCount posts with duplicate likes from same user');
  }

  // Check likeCount accuracy
  print('\n🔍 Checking likeCount accuracy...\n');

  for (var entry in postLikes.entries) {
    final postId = entry.key;
    final uniqueLikes = entry.value.toSet().length;

    final postDoc = await firestore.collection('posts').doc(postId).get();
    if (postDoc.exists) {
      final storedLikeCount = postDoc.data()?['likeCount'] as int? ?? 0;

      if (storedLikeCount != uniqueLikes) {
        print('❌ MISMATCH FOUND!');
        print('   Post: $postId');
        print('   Stored likeCount: $storedLikeCount');
        print('   Actual likes: $uniqueLikes');
        print('   Difference: ${storedLikeCount - uniqueLikes}');
        print('');
      }
    }
  }

  print('\n✅ Check complete!');
  exit(0);
}
