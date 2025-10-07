/// Test Career Selector Widget
///
/// Provides a UI for selecting test careers in debug mode to validate
/// the lounge access system.
///
/// **Purpose**:
/// - Development/testing tool (kDebugMode only)
/// - Allows developers to test different career scenarios
/// - Updates user's test career in Firestore
/// - Validates lounge access permissions
///
/// **Features**:
/// - Modal bottom sheet with scrollable career list
/// - Updates user's careerHierarchy, accessibleLoungeIds, defaultLoungeId
/// - Refreshes AuthCubit after update
/// - Shows success/error feedback
///
/// **Usage**:
/// Used by ProfileHeader widget when in debug mode.

library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../domain/career_hierarchy.dart';
import '../../../../community/domain/services/lounge_access_service.dart';
import '../../constants/test_careers.dart';

/// Shows a modal bottom sheet for selecting a test career
///
/// This function displays a bottom sheet with all available test careers
/// and handles the selection/update process.
void showTestCareerSelector(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '테스트용 직렬 선택',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...testCareers.map((career) {
                return ListTile(
                  title: Text(career['name']!),
                  subtitle: Text('ID: ${career['id']}'),
                  onTap: () {
                    Navigator.pop(context);
                    updateTestCareer(context, career['id']!);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}

/// Updates the user's test career in Firestore
///
/// This function:
/// 1. Creates a CareerHierarchy from the selected career ID
/// 2. Calculates accessible lounge IDs using LoungeAccessService
/// 3. Updates Firestore with new career data
/// 4. Refreshes AuthCubit to reflect changes
/// 5. Shows success/error feedback
///
/// [careerId] - The selected career ID from testCareers list
Future<void> updateTestCareer(BuildContext context, String careerId) async {
  try {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final String? userId = authCubit.state.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      return;
    }

    // CareerHierarchy 생성
    CareerHierarchy? careerHierarchy;
    List<String> accessibleLoungeIds = ['all']; // 기본값
    String defaultLoungeId = 'all';

    if (careerId != 'none') {
      careerHierarchy = CareerHierarchy.fromSpecificCareer(careerId);

      // LoungeAccessService를 사용하여 접근 가능한 라운지 ID 생성
      final accessibleLounges = LoungeAccessService.getAccessibleLounges(
        careerHierarchy,
      );
      accessibleLoungeIds = accessibleLounges
          .map((lounge) => lounge.id)
          .toList();

      // 기본 라운지는 LoungeAccessService를 통해 가져옴
      defaultLoungeId = LoungeAccessService.getDefaultLoungeId(careerHierarchy);
    }

    // Firestore 직접 업데이트
    // 테스트 모드에서는 testModeCareer 필드에 직렬 정보 저장
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'careerHierarchy': careerHierarchy?.toMap(),
      'careerTrack': careerHierarchy?.legacyCareerTrack.name ?? 'none',
      'accessibleLoungeIds': accessibleLoungeIds,
      'defaultLoungeId': defaultLoungeId,
      'testModeCareer': careerHierarchy?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // AuthCubit 새로고침
    await authCubit.refreshAuthStatus();

    if (context.mounted) {
      final careerName = testCareers.firstWhere(
        (c) => c['id'] == careerId,
        orElse: () => {'name': careerId},
      )['name'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('테스트 직렬이 "$careerName"(으)로 설정되었습니다'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }
}
