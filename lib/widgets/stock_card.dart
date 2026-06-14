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
    final formatter = NumberFormat.simpleCurrency();

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: Colors.teal.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.medicineName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (pharmacy != null) ...[
                          Text(
                            pharmacy!.name,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pharmacy!.reviewCount > 0) ...[
                            const SizedBox(height: 8),
                            StarRatingDisplay(
                              rating: pharmacy!.averageRating,
                              size: 15,
                              showValue: true,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  trailing ?? Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          [
                            if (stock.isLowStock) 'Low stock',
                            if (stock.isExpiringSoon)
                              'Expires ${DateFormat.yMMMd().format(stock.expiryDate)}',
                          ].join(' | '),
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
