import 'package:flutter/material.dart';

class CustomerScreenBackground extends StatelessWidget {
  const CustomerScreenBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9FBF7),
            Color(0xFFF6FBFF),
            Color(0xFFFFFEFB),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(
              size: 210,
              color: Colors.teal.withAlpha((0.16 * 255).round()),
            ),
          ),
          Positioned(
            top: 260,
            left: -95,
            child: _GlowOrb(
              size: 190,
              color: Colors.lightBlue.withAlpha((0.12 * 255).round()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class CustomerHeroCard extends StatelessWidget {
  const CustomerHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions = const [],
    this.badges = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E),
            Color(0xFF0891B2),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withAlpha((0.28 * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -52,
            right: -44,
            child: _GlowOrb(
              size: 150,
              color: Colors.white.withAlpha((0.14 * 255).round()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withAlpha(
                                      (0.9 * 255).round(),
                                    ),
                                    height: 1.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.16 * 255).round()),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.18 * 255).round()),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges,
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 22),
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  actions[index],
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerPill extends StatelessWidget {
  const CustomerPill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withAlpha((0.16 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class CustomerSurfaceCard extends StatelessWidget {
  const CustomerSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.94 * 255).round()),
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withAlpha((0.82 * 255).round()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withAlpha((0.07 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

class CustomerIconBadge extends StatelessWidget {
  const CustomerIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha((0.16 * 255).round()),
            color.withAlpha((0.08 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class CustomerSectionHeader extends StatelessWidget {
  const CustomerSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.teal.shade900,
              ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
