import 'package:flutter/material.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';

/// A banner for sponsorship or premium features.
///
/// Currently returns an empty widget but can be expanded for monetization features.
class SponsorshipBanner extends StatelessWidget {
  const SponsorshipBanner({super.key, required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
