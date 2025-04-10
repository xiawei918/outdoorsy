import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/user_provider.dart';

class UserAvatar extends ConsumerWidget {
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;

  const UserAvatar({
    super.key,
    this.size = 32,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    
    return profileAsync.when(
      loading: () => _buildLoadingAvatar(),
      error: (_, __) => _buildErrorAvatar(),
      data: (profile) {
        if (profile == null) return _buildErrorAvatar();
        
        // If there's an avatar URL, use it
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(profile.avatarUrl!),
          );
        }
        
        // Otherwise, show initials
        return _buildInitialsAvatar(profile.name);
      },
    );
  }

  Widget _buildInitialsAvatar(String name) {
    // Get initials (up to 2 characters)
    final initials = _getInitials(name);
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppColors.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppColors.gray200,
      child: SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorAvatar() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppColors.gray200,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: textColor ?? AppColors.gray400,
      ),
    );
  }

  String _getInitials(String name) {
    // Split the name into parts and filter out empty strings
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    
    // Return up to 2 initials
    return parts.take(2).map((part) => part[0].toUpperCase()).join('');
  }
} 