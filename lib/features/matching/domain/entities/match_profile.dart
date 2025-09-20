import 'package:equatable/equatable.dart';

import '../../../profile/domain/career_track.dart';

class MatchProfile extends Equatable {
  const MatchProfile({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.location,
    required this.yearsOfService,
    required this.introduction,
    required this.interests,
    required this.authorTrack,
  });

  final String id;
  final String name;
  final String jobTitle;
  final String location;
  final int yearsOfService;
  final String introduction;
  final List<String> interests;
  final CareerTrack authorTrack;

  @override
  List<Object?> get props => [
    id,
    name,
    jobTitle,
    location,
    yearsOfService,
    introduction,
    interests,
    authorTrack,
  ];
}
