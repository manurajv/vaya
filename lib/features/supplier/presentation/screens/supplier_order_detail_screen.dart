import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../providers/supplier_provider.dart';

class SupplierOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const SupplierOrderDetailScreen({super.key, required this.orderId});

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
              // Order header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Formatters.formatOrderId(order.id),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.white70)),
                        _StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order.productName,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(Formatters.formatDateTime(order.createdAt),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white60)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Buyer info
              _InfoCard(title: 'Buyer Details', rows: [
                _Row('Business', order.buyerBusinessName),
                _Row('Quantity', '${order.quantity} units'),
                _Row('Price/unit',
                    Formatters.formatCurrency(order.pricePerUnit)),
              ]),
              const SizedBox(height: 12),

              // Payment info
              _InfoCard(title: 'Payment Details', rows: [
                _Row('Total Amount',
                    Formatters.formatCurrency(order.totalAmount)),
                _Row('Token Paid',
                    Formatters.formatCurrency(order.tokenAmount),
                    valueColor: AppColors.success),
                _Row('Balance Due',
                    Formatters.formatCurrency(order.remainingAmount),
                    valueColor: order.isFullyPaid
                        ? AppColors.success
                        : AppColors.accent),
                _Row('Payment Status',
                    _paymentLabel(order.paymentStatus)),
              ]),
              const SizedBox(height: 16),

              // Update status
              const Text('Update Order Status',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _StatusStepper(
                currentStatus: order.status,
                orderId: orderId,
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

  String _paymentLabel(String status) {
    switch (status) {
      case 'token_paid':
        return 'Token Paid';
      case 'full_paid':
        return 'Fully Paid';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}

class _StatusStepper extends ConsumerStatefulWidget {
  final String currentStatus;
  final String orderId;
  const _StatusStepper(
      {required this.currentStatus, required this.orderId});

  @override
  ConsumerState<_StatusStepper> createState() => _StatusStepperState();
}

class _StatusStepperState extends ConsumerState<_StatusStepper> {
  bool _isUpdating = false;

  static const _steps = [
    AppConstants.orderStatusPending,
    AppConstants.orderStatusConfirmed,
    AppConstants.orderStatusProcessing,
    AppConstants.orderStatusShipped,
    AppConstants.orderStatusDelivered,
  ];

  static const _labels = [
    'Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered'
  ];

  Future<void> _advance() async {
    final currentIndex = _steps.indexOf(widget.currentStatus);
    if (currentIndex >= _steps.length - 1) return;

    final nextStatus = _steps[currentIndex + 1];
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(supplierProductServiceProvider)
          .updateOrderStatus(widget.orderId, nextStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as ${_labels[currentIndex + 1]}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(widget.currentStatus);
    final isDelivered =
        widget.currentStatus == AppConstants.orderStatusDelivered;
    final isCancelled =
        widget.currentStatus == AppConstants.orderStatusCancelled;

    return Column(
      children: [
        // Visual stepper
        Row(
          children: _steps.asMap().entries.map((entry) {
            final i = entry.key;
            final isDone = i <= currentIndex;
            final isActive = i == currentIndex;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle_outlined,
                      size: 14,
                      color: isDone ? Colors.white : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isDone
                              ? AppColors.primary
                              : AppColors.textHint)),
                  if (i < _steps.length - 1)
                    Container(
                        height: 2,
                        color: isDone
                            ? AppColors.primary
                            : AppColors.border),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        if (!isDelivered && !isCancelled)
          AppButton(
            label: currentIndex < _steps.length - 1
                ? 'Mark as ${_labels[currentIndex + 1]}'
                : 'Delivered',
            onPressed: _isUpdating ? null : _advance,
            isLoading: _isUpdating,
            prefixIcon: Icons.arrow_forward,
          ),

        if (isDelivered)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 10),
                Text('Order delivered successfully!',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _InfoCard({required this.title, required this.rows});

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
          ...rows,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});

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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1),
      ),
    );
  }
}
