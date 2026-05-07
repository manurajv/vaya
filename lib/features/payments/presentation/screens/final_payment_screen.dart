import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../orders/presentation/providers/order_provider.dart';

class FinalPaymentScreen extends ConsumerWidget {
  final String orderId;

  const FinalPaymentScreen({super.key, required this.orderId});

  Future<void> _openUpi(BuildContext context, String upiLink) async {
    final uri = Uri.parse(upiLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open a UPI app. Pay using bank details below.'),
        ),
      );
    }
  }

  void _showPaidReminder(BuildContext context, String groupId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supplier payment'),
        content: const Text(
          'Please upload a payment receipt so the supplier can verify and release your goods.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(
                '/payment/proof/$groupId/final?orderId=$orderId',
              );
            },
            child: const Text('Upload proof'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Final Payment')),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          final remaining = order.remainingAmount;
          final payeeName =
              order.supplierBankAccountName ?? order.supplierName;
          final upiId =
              order.supplierUpiId ?? AppConstants.placeholderSupplierUpi;
          final upiLink =
              'upi://pay?pa=${Uri.encodeComponent(upiId)}&pn=${Uri.encodeComponent(payeeName)}&am=${remaining.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('VAYA ${order.productName}')}';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.payment_outlined,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Final Payment',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pay directly to the supplier',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Formatters.formatCurrency(remaining),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Remaining amount',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Breakdown',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _Row(
                        label: 'Total Order Value',
                        value: Formatters.formatCurrency(order.totalAmount)),
                    _Row(
                        label: 'Token Paid',
                        value:
                            '- ${Formatters.formatCurrency(order.tokenAmount)}',
                        valueColor: AppColors.success),
                    const Divider(height: 16),
                    _Row(
                        label: 'Amount to Pay',
                        value: Formatters.formatCurrency(remaining),
                        isBold: true,
                        valueColor: AppColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Pay to ${order.supplierName}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scan QR or use bank details below',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UPI: $upiId',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Pay with UPI app',
                      onPressed: order.isFullyPaid
                          ? null
                          : () => _openUpi(context, upiLink),
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      height: 44,
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: upiLink,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Supplier Bank Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BankDetailRow(
                        label: 'Account Name',
                        value: order.supplierBankAccountName ??
                            order.supplierName),
                    _BankDetailRow(
                        label: 'Bank',
                        value: order.supplierBankName ?? '—'),
                    _BankDetailRow(
                        label: 'Account No.',
                        value: order.supplierAccountNumber ?? '—'),
                    _BankDetailRow(
                        label: 'IFSC',
                        value: order.supplierIfscCode ?? '—'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After payment, upload your payment proof. The supplier will confirm receipt and process your order.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Upload Payment Proof',
                onPressed: order.isFullyPaid
                    ? null
                    : () => context.push(
                          '/payment/proof/${order.groupId}/final?orderId=${order.id}',
                        ),
                prefixIcon: Icons.upload_outlined,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'I Have Paid',
                variant: AppButtonVariant.outline,
                onPressed: order.isFullyPaid
                    ? null
                    : () =>
                        _showPaidReminder(context, order.groupId),
                prefixIcon: Icons.check_circle_outline,
              ),
              if (order.isFullyPaid) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'View Order',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/order/${order.id}'),
                  prefixIcon: Icons.receipt_long_outlined,
                ),
              ],
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _Row({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          if (value != '—')
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied!')),
                );
              },
              child:
                  const Icon(Icons.copy, size: 14, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}
