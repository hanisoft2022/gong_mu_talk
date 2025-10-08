// ignore_for_file: avoid_print

/// Verification script to fix comment count discrepancies
///
/// This script:
/// 1. Reads all posts from Firestore
/// 2. For each post, counts actual non-deleted comments
/// 3. Compares with stored commentCount
/// 4. Fixes mismatches by updating commentCount
///
/// Usage:
///   dart run scripts/verify_comment_counts.dart
///
/// Requirements:
///   - Firebase credentials configured
///   - Firestore access with read/write permissions
library;

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Import actual Firebase configuration from the app
import 'package:gong_mu_talk/firebase_options.dart';

Future<void> main() async {
  print('🔍 Starting comment count verification...\n');

  // Initialize Firebase using app's configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('💡 Ensure firebase_options.dart exists in lib/');
    exit(1);
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Fetch all posts
    print('📥 Fetching all posts...');
    final QuerySnapshot<Map<String, dynamic>> postsSnapshot =
        await firestore.collection('posts').get();

    print('📊 Found ${postsSnapshot.docs.length} posts\n');

    int totalChecked = 0;
    int mismatchCount = 0;
    int fixedCount = 0;

    for (final DocumentSnapshot<Map<String, dynamic>> postDoc
        in postsSnapshot.docs) {
      final String postId = postDoc.id;
      final Map<String, dynamic>? postData = postDoc.data();

      if (postData == null) {
        print('⚠️  Post $postId has no data, skipping');
        continue;
      }

      // Get stored commentCount
      final int storedCount = (postData['commentCount'] as num?)?.toInt() ?? 0;

      // Count actual non-deleted comments
      final QuerySnapshot<Map<String, dynamic>> commentsSnapshot =
          await firestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .where('deleted', isEqualTo: false)
              .get();

      final int actualCount = commentsSnapshot.docs.length;

      totalChecked++;

      // Check for mismatch
      if (storedCount != actualCount) {
        mismatchCount++;
        print('❌ Mismatch found:');
        print('   Post ID: $postId');
        print('   Stored count: $storedCount');
        print('   Actual count: $actualCount');
        print('   Difference: ${storedCount - actualCount}');

        // Fix the mismatch
        try {
          await postDoc.reference.update({
            'commentCount': actualCount,
          });
          fixedCount++;
          print('   ✅ Fixed!\n');
        } catch (e) {
          print('   ❌ Failed to fix: $e\n');
        }
      }
    }

    // Summary
    print('\n${"=" * 60}');
    print('📋 Verification Summary:');
    print("=" * 60);
    print('Total posts checked: $totalChecked');
    print('Mismatches found: $mismatchCount');
    print('Successfully fixed: $fixedCount');
    print('Failed to fix: ${mismatchCount - fixedCount}');
    print("=" * 60);

    if (mismatchCount == 0) {
      print('\n✅ All comment counts are correct!');
    } else if (fixedCount == mismatchCount) {
      print('\n✅ All mismatches have been fixed!');
    } else {
      print('\n⚠️  Some mismatches could not be fixed. Check errors above.');
    }
  } catch (e, stackTrace) {
    print('\n❌ Error during verification: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }

  exit(0);
}
