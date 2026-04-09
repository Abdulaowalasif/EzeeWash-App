// lib/features/home/presentation/widgets/home_profile_glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

class HomeProfileGlassCard extends StatelessWidget {
  const HomeProfileGlassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
      curr is ProfileLoading ||
          curr is ProfileInitial ||
          curr is ProfileLoaded,
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const AppShimmer.profileGlassCard();
        }
        if (state is ProfileLoaded) {
          return _GlassCardContent(profile: state.profile);
        }
        if (state is ProfileError) {
          Future.delayed(
            const Duration(seconds: 2),
                () => context.read<ProfileBloc>().add(const ProfileLoadRequested()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Loaded content ───────────────────────────────────────────────────────────

class _GlassCardContent extends StatelessWidget {
  final dynamic profile;

  const _GlassCardContent({required this.profile});

  String _buildLocation() {
    final parts = <String>[
      if (profile.address != null && profile.address!.isNotEmpty)
        profile.address!,
      if (profile.city != null && profile.city!.isNotEmpty) profile.city!,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final location = _buildLocation();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                _Avatar(avatarUrl: profile.avatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: _ProfileInfo(
                    fullName: profile.fullName,
                    phone: profile.phone,
                    location: location,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  const _Avatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: hasUrl
          ? ClipOval(
        child: AppNetworkImage(
          url: avatarUrl,
          width: 52,
          height: 52,
          radius: 26,
          fallbackIcon: Iconsax.user,
        ),
      )
          : const Icon(Iconsax.user, color: Colors.white),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final String? fullName;
  final String? phone;
  final String location;

  const _ProfileInfo({
    required this.fullName,
    required this.phone,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName ?? 'User Profile',
          style: AppTextStyles.onGradientTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (phone != null && phone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _IconRow(icon: Icons.phone, text: phone!),
        ],
        if (location.isNotEmpty) ...[
          const SizedBox(height: 4),
          _IconRow(icon: Icons.location_on, text: location),
        ],
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, color: Colors.white70, size: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.onGradientSub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}