import 'package:flutter/material.dart';

/// A user avatar widget with customizable appearance.
class UserAvatar extends StatelessWidget {
  final String? name;
  final double radius;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? imageUrl;

  const UserAvatar({
    super.key,
    this.name,
    this.radius = 24,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.imageUrl,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? theme.colorScheme.primary;

    if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: bgColor,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: icon != null
          ? Icon(icon, size: radius * 0.8, color: fgColor)
          : Text(
              _initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
    );
  }
}

/// A welcome card that shows user information with avatar.
class WelcomeCard extends StatelessWidget {
  final String greeting;
  final String name;
  final bool isAdmin;
  final Widget? trailing;

  const WelcomeCard({
    super.key,
    this.greeting = 'Welcome back,',
    required this.name,
    required this.isAdmin,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            UserAvatar(
              radius: 30,
              icon: isAdmin ? Icons.admin_panel_settings : Icons.person,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      isAdmin ? 'Administrator' : 'Patient',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor:
                        isAdmin ? Colors.purple[100] : Colors.blue[100],
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
