import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/medicine_subscription.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/snackbars.dart';
import '../customer/customer_ui.dart';
import 'create_subscription_screen.dart';

class MySubscriptionsScreen extends StatelessWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
      ),
      body: StreamBuilder<List<MedicineSubscription>>(
        stream: context.read<FirestoreService>().watchSubscriptionsForUser(
              user.uid,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subs = snapshot.data ?? [];
          if (subs.isEmpty) {
            return _EmptySubscriptions();
          }

          final active = subs.where((s) => s.isActive).toList();
          final inactive = subs.where((s) => !s.isActive).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _SubscriptionsSummary(subs: subs, active: active),
              const SizedBox(height: 20),
              if (active.isNotEmpty) ...[
                const AnimatedStaggerItem(
                  delay: 50,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Active Subscriptions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF004D40),
                      ),
                    ),
                  ),
                ),
                ...active.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedStaggerItem(
                        delay: 100 + entry.key * 60,
                        child: _SubscriptionCard(subscription: entry.value),
                      ),
                    )),
              ],
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 12),
                const AnimatedStaggerItem(
                  delay: 50,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Paused',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF004D40),
                      ),
                    ),
                  ),
                ),
                ...inactive.map((sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SubscriptionCard(subscription: sub),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateSubscriptionScreen(),
          ),
        ),
      ),
    );
  }
}

class _EmptySubscriptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withAlpha((0.08 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 56,
                color: Color(0xFF00796B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Subscriptions Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to your regular medicines for\nauto reminders and one-tap refills.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Subscription'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateSubscriptionScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionsSummary extends StatelessWidget {
  final List<MedicineSubscription> subs;
  final List<MedicineSubscription> active;

  const _SubscriptionsSummary({
    required this.subs,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final dueSoon = subs.where((s) =>
        s.isActive && s.daysRemaining <= 3).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004D40),
            Color(0xFF00796B),
            Color(0xFF009688),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withAlpha((0.28 * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              value: active.length.toString(),
              label: 'Active',
              icon: Icons.check_circle_outline,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withAlpha((0.2 * 255).round()),
          ),
          Expanded(
            child: _SummaryStat(
              value: dueSoon.toString(),
              label: 'Due Soon',
              icon: Icons.warning_amber_outlined,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withAlpha((0.2 * 255).round()),
          ),
          Expanded(
            child: _SummaryStat(
              value: subs.length.toString(),
              label: 'Total',
              icon: Icons.inbox_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withAlpha((0.9 * 255).round()), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha((0.8 * 255).round()),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final MedicineSubscription subscription;

  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final status = subscription.status;
    final daysLeft = subscription.daysRemaining;
    final stockPct = subscription.estimatedStockRemaining;

    final (Color statusColor, String statusLabel) = switch (status) {
      SubscriptionStatus.active => (const Color(0xFF16A34A), 'Active'),
      SubscriptionStatus.upcoming => (const Color(0xFFF59E0B), 'Refill Soon'),
      SubscriptionStatus.refillDue => (const Color(0xFFDC2626), 'Refill Due'),
      SubscriptionStatus.inactive => (Colors.grey, 'Paused'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Color(0xFF00796B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.medicineName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    if (subscription.pharmacyName != null)
                      Text(
                        subscription.pharmacyName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DetailChip(
                icon: Icons.calendar_today_outlined,
                label: 'Next Refill',
                value: DateFormat('MMM d').format(subscription.nextRefillDate),
              ),
              const SizedBox(width: 12),
              _DetailChip(
                icon: Icons.repeat_outlined,
                label: 'Every',
                value: '${subscription.frequencyDays} days',
              ),
              const SizedBox(width: 12),
              _DetailChip(
                icon: Icons.inventory_2_outlined,
                label: 'Qty',
                value: '${subscription.quantity}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hourglass_bottom,
                            size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '$daysLeft days remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stockPct / 100,
                        minHeight: 5,
                        backgroundColor: Colors.teal.shade50,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stockPct > 50
                              ? const Color(0xFF16A34A)
                              : stockPct > 20
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refill Now', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00796B),
                      side: const BorderSide(color: Color(0xFF00796B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _refillNow(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      subscription.isActive
                          ? Icons.pause_outlined
                          : Icons.play_arrow_outlined,
                      size: 18,
                    ),
                    label: Text(
                      subscription.isActive ? 'Pause' : 'Resume',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _toggleActive(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _deleteSubscription(context),
                  child: const Icon(Icons.delete_outline, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _refillNow(BuildContext context) {
    final provider = context.read<SubscriptionProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refill Now?'),
        content: Text(
          'This will reset your refill schedule for '
          '${subscription.medicineName}.\n\n'
          'Next refill date will be set to '
          '${DateFormat('MMM d, yyyy').format(DateTime.now().add(Duration(days: subscription.frequencyDays)))}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.refillNow(subscription);
                if (context.mounted) {
                  showAppSnackBar(context, 'Refill scheduled!');
                }
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, 'Failed: $e', isError: true);
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toggleActive(BuildContext context) {
    final provider = context.read<SubscriptionProvider>();
    provider.toggleActive(subscription);
  }

  void _deleteSubscription(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Subscription?'),
        content: Text(
          'Stop subscription for ${subscription.medicineName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context
                    .read<SubscriptionProvider>()
                    .deleteSubscription(subscription.subscriptionId);
                if (context.mounted) {
                  showAppSnackBar(context, 'Subscription deleted.');
                }
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, 'Failed: $e', isError: true);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004D40),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
