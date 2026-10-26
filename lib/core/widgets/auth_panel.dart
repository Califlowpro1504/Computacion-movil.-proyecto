import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared, scrollable presentation for authentication on phones and wide screens.
class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28121F), AppTheme.background, Color(0xFF171222)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 56).clamp(0.0, double.infinity).toDouble(),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF51404D)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 12)),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A1823),
            border: Border.all(color: AppTheme.accent),
          ),
          child: const Icon(Icons.content_cut, size: 30, color: AppTheme.ivory),
        ),
        const SizedBox(height: 20),
        const Text(
          'CUT & GO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif', fontSize: 34, letterSpacing: 3,
            fontWeight: FontWeight.w700, color: AppTheme.ivory,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF51404D))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.diamond_outlined, size: 16, color: AppTheme.accent),
            ),
            Expanded(child: Divider(color: Color(0xFF51404D))),
          ],
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.muted, height: 1.5)),
        const SizedBox(height: 28),
      ],
    );
  }
}
