import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

class TokenPaymentScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TokenPaymentScreen({super.key, required this.groupId});

  @override
  ConsumerState<TokenPaymentScreen> createState() =>
      _TokenPaymentScreenState();
}

class _TokenPaymentScreenState extends ConsumerState<TokenPaymentScreen> {
  bool _isConfirming = false;

  Future<void> _confirmPayment() async {
    setState(() => _isConfirming = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await ref.read(groupServiceProvider).updateMemberPaymentStatus(
            widget.groupId,
            user.id,
            AppConstants.paymentStatusTokenPaid,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token payment confirmed! Proforma invoice will be shared shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Token Payment')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          final myMembership = user != null ? group.getMember(user.id) : null;
          final myQty = myMembership?.quantity ?? 0;
          final pricePerUnit = group.currentPricePerUnit;
          final myTotal = pricePerUnit * myQty;
          final tokenAmount =
              myTotal * ((group.tokenPercentage ?? 10) / 100);

          // UPI deep link for QR
          final upiLink =
              'upi://pay?pa=${AppConstants.companyUpiId}&pn=${Uri.encodeComponent(AppConstants.companyAccountName)}&am=${tokenAmount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('Token for ${group.productName}')}';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Token Payment',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pay token amount to confirm your participation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Formatters.formatCurrency(tokenAmount),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${group.tokenPercentage ?? 10}% of your order value',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Order summary
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
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Row(label: 'Product', value: group.productName),
                    _Row(label: 'Quantity', value: '$myQty units'),
                    _Row(
                        label: 'Price/unit',
                        value: Formatters.formatCurrency(pricePerUnit)),
                    const Divider(height: 16),
                    _Row(
                        label: 'Total Order Value',
                        value: Formatters.formatCurrency(myTotal),
                        isBold: true),
                    _Row(
                        label: 'Token Amount',
                        value: Formatters.formatCurrency(tokenAmount),
                        isBold: true,
                        valueColor: AppColors.accent),
                    _Row(
                        label: 'Remaining (to supplier)',
                        value: Formatters.formatCurrency(myTotal - tokenAmount),
                        valueColor: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scan QR to Pay',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pay to VAYA Technologies (Token Amount)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
                      'Or pay via bank transfer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BankDetailRow(
                        label: 'Account Name',
                        value: AppConstants.companyAccountName),
                    _BankDetailRow(
                        label: 'Bank',
                        value: AppConstants.companyBankName),
                    _BankDetailRow(
                        label: 'Account No.',
                        value: AppConstants.companyAccountNumber),
                    _BankDetailRow(
                        label: 'IFSC',
                        value: AppConstants.companyIfscCode),
                    _BankDetailRow(
                        label: 'UPI ID',
                        value: AppConstants.companyUpiId),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Important note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Important',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Token amount is paid to VAYA Technologies\n'
                      '• After payment, upload your payment screenshot\n'
                      '• Proforma invoice will be shared after verification\n'
                      '• Final payment goes directly to the supplier',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.warning,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'I Have Paid – Confirm',
                onPressed: _confirmPayment,
                isLoading: _isConfirming,
                prefixIcon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Upload Payment Screenshot',
                variant: AppButtonVariant.outline,
                onPressed: () => context.push(
                    '/payment/proof/${widget.groupId}/token'),
                prefixIcon: Icons.upload_outlined,
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
                  color: valueColor ??
                      (isBold ? AppColors.textPrimary : AppColors.textPrimary))),
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
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!')),
              );
            },
            child: const Icon(Icons.copy, size: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
