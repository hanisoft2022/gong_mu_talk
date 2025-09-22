import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:gong_mu_talk/core/firebase/firebase_initializer.dart';
import 'package:gong_mu_talk/features/community/data/community_repository.dart';
import 'package:gong_mu_talk/features/profile/domain/career_track.dart';
import 'package:gong_mu_talk/features/community/domain/models/post.dart';

Future<void> main() async {
  // Minimal Flutter bindings (no UI) so firebase_core works in Flutter context
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.ensureInitialized();

  // Ensure we're authenticated (anonymous is fine for seeding)
  final FirebaseAuth auth = FirebaseAuth.instance;
  try {
    await auth.signInAnonymously();
  } catch (_) {
    // If already signed in, continue
  }
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'seed_bot';

  final CommunityRepository community = CommunityRepository();
  final Random random = Random();

  // Generate sample texts
  const List<String> samples = <String>[
    '오늘 업무 중 느낀 점을 공유해요. 같은 경험 있으신가요?',
    '부서 내 협업을 더 잘하려면 무엇이 필요할까요?',
    '점심 추천 부탁드립니다! 정부청사 근처 맛집 아시나요?',
    '업무 자동화 아이디어를 모아봅시다.',
    '정책 자료 정리 노하우 공유합니다.',
    '회의가 많은 날엔 집중 시간이 부족하네요.',
    '새로 발령받은 부서에 적응 중입니다.',
    '문서 양식 표준화에 대한 의견이 궁금해요.',
    '업무용 장비 교체 일정이 잡혔다고 합니다.',
    '팀 내 코드 리뷰 문화를 만들어볼까 해요.',
  ];

  final List<String> tagsPool = <String>['업무', '복지', '협업', '자동화', '문서', '정책', '리뷰', '점심'];
  final List<CareerTrack> tracks = <CareerTrack>[...CareerTrack.values.where((t) => t != CareerTrack.none)];

  // Create chirp posts (쫑알쫑알)
  for (int i = 0; i < 18; i += 1) {
    final String text = samples[random.nextInt(samples.length)];
    final List<String> tags = List<String>.generate(
      1 + random.nextInt(3),
      (_) => tagsPool[random.nextInt(tagsPool.length)],
    ).toSet().toList();

    final CareerTrack authorTrack = tracks[random.nextInt(tracks.length)];
    final Post post = await community.createPost(
      type: PostType.chirp,
      authorUid: uid,
      authorNickname: '시드봇',
      authorTrack: authorTrack,
      text: text,
      audience: random.nextBool() ? PostAudience.all : PostAudience.serial,
      serial: authorTrack.name,
      tags: tags,
    );

    // Add a couple of comments per post
    final int commentCount = 1 + random.nextInt(3);
    for (int c = 0; c < commentCount; c += 1) {
      await community.createComment(
        postId: post.id,
        authorUid: uid,
        authorNickname: '시드봇',
        text: '의견 ${c + 1}: ${samples[random.nextInt(samples.length)]}',
      );
    }
  }

  // Optionally, create some board-type posts if your app uses boards
  for (int i = 0; i < 6; i += 1) {
    await community.createPost(
      type: PostType.board,
      authorUid: uid,
      authorNickname: '시드봇',
      authorTrack: tracks[random.nextInt(tracks.length)],
      text: '공지/게시판 샘플 글 #${i + 1}: ${samples[random.nextInt(samples.length)]}',
      audience: PostAudience.all,
      serial: 'general',
      boardId: 'general', // 존재하지 않아도 조회는 가능
      tags: const <String>['공지'],
    );
  }

  // Done
  // ignore: avoid_print
  print('Dummy community data seeded successfully as uid=$uid');
}
