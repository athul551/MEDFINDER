import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pharmacy.dart';
import '../models/stock_item.dart';
import '../utils/app_constants.dart';
import 'star_rating_display.dart';

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
    final formatter = NumberFormat.simpleCurrency();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.medicineName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pharmacy != null) ...[
                          Text(
                            pharmacy!.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (pharmacy!.reviewCount > 0) ...[
                            const SizedBox(height: 2),
                            StarRatingDisplay(
                              rating: pharmacy!.averageRating,
                              size: 14,
                              showValue: true,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  trailing ?? const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    label: stock.isAvailable ? 'Available' : 'Out of stock',
                    color: stock.isAvailable
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  _InfoChip(label: 'Qty ${stock.quantity}'),
                  _InfoChip(label: formatter.format(stock.price)),
                  if (distanceKm != null)
                    _InfoChip(label: '${distanceKm!.toStringAsFixed(1)} km'),
                ],
              ),
              if (stock.isLowStock || stock.isExpiringSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            if (stock.isLowStock) 'Low stock',
                            if (stock.isExpiringSoon)
                              'Expires ${DateFormat.yMMMd().format(stock.expiryDate)}',
                          ].join(' | '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
        color: textColor.withOpacity(0.1),
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
