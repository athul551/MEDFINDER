import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pharmacy.dart';
import '../models/stock_item.dart';
import '../utils/app_constants.dart';

class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.stock,
    this.pharmacy,
    this.distanceKm,
    this.onTap,
    this.trailing,
  });

  final StockItem stock;
  final Pharmacy? pharmacy;
  final double? distanceKm;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '\$');
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(stock.medicineName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pharmacy != null) Text(pharmacy!.name),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _InfoChip(
                  label: stock.isAvailable ? 'Available' : 'Out of stock',
                  color:
                      stock.isAvailable ? AppColors.success : AppColors.danger,
                ),
                _InfoChip(label: 'Qty ${stock.quantity}'),
                _InfoChip(label: formatter.format(stock.price)),
                if (distanceKm != null)
                  _InfoChip(label: '${distanceKm!.toStringAsFixed(1)} km'),
              ],
            ),
            if (stock.isLowStock || stock.isExpiringSoon) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (stock.isLowStock) 'Low stock',
                  if (stock.isExpiringSoon)
                    'Expires ${DateFormat.yMMMd().format(stock.expiryDate)}',
                ].join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
