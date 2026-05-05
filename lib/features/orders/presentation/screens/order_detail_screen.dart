import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Order ID & status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order ID',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.white70)),
                        Text(Formatters.formatOrderId(order.id),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(Formatters.formatDateTime(order.createdAt),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.white60)),
                      ],
                    ),
                    _StatusBadge(status: order.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order tracking
              _TrackingWidget(status: order.status),
              const SizedBox(height: 16),

              // Product details
              _InfoCard(
                title: 'Product Details',
                children: [
                  _InfoRow(label: 'Product', value: order.productName),
                  _InfoRow(label: 'Supplier', value: order.supplierName),
                  _InfoRow(label: 'Quantity', value: '${order.quantity} units'),
                  _InfoRow(
                      label: 'Price/unit',
                      value: Formatters.formatCurrency(order.pricePerUnit)),
                ],
              ),
              const SizedBox(height: 12),

              // Payment details
              _InfoCard(
                title: 'Payment Details',
                children: [
                  _InfoRow(
                      label: 'Total Amount',
                      value: Formatters.formatCurrency(order.totalAmount)),
                  _InfoRow(
                      label: 'Token Paid',
                      value: Formatters.formatCurrency(order.tokenAmount),
                      valueColor: AppColors.success),
                  _InfoRow(
                      label: 'Balance Due',
                      value: Formatters.formatCurrency(order.remainingAmount),
                      valueColor: order.isFullyPaid
                          ? AppColors.success
                          : AppColors.accent),
                  _InfoRow(
                      label: 'Payment Status',
                      value: _paymentStatusLabel(order.paymentStatus)),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              if (!order.isTokenPaid)
                AppButton(
                  label: 'Pay Token Amount',
                  onPressed: () =>
                      context.push('/payment/token/${order.groupId}'),
                  prefixIcon: Icons.payment_outlined,
                ),
              if (order.isTokenPaid && !order.isFullyPaid) ...[
                AppButton(
                  label: 'View Proforma Invoice',
                  variant: AppButtonVariant.outline,
                  onPressed: () =>
                      context.push('/invoice/$orderId'),
                  prefixIcon: Icons.receipt_outlined,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Make Final Payment',
                  onPressed: () =>
                      context.push('/payment/final/$orderId'),
                  prefixIcon: Icons.payment_outlined,
                ),
              ],
              if (order.isFullyPaid)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Payment Complete! Order is being processed.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'token_paid':
        return 'Token Paid';
      case 'full_paid':
        return 'Fully Paid';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TrackingWidget extends StatelessWidget {
  final String status;

  const _TrackingWidget({required this.status});

  static const _steps = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
  ];

  static const _labels = [
    'Order Placed',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
  ];

  static const _icons = [
    Icons.receipt_outlined,
    Icons.check_circle_outline,
    Icons.settings_outlined,
    Icons.local_shipping_outlined,
    Icons.home_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Tracking',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final isDone = index <= currentIndex;
              final isActive = index == currentIndex;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _icons[index],
                        size: 16,
                        color: isDone ? Colors.white : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isDone ? AppColors.primary : AppColors.textHint,
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        height: 2,
                        color: isDone ? AppColors.primary : AppColors.border,
                        margin: const EdgeInsets.only(top: 4),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
