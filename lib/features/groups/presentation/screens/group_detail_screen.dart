import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/countdown_timer_widget.dart';
import '../../../../shared/widgets/group_progress_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/group_provider.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isSupplier = currentUser?.userType == AppConstants.userTypeSupplier;

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group')),
            body: const Center(child: Text('Group not found')),
          );
        }

        final isMember =
            currentUserId != null && group.isMember(currentUserId);
        final isCreator = currentUserId == group.creatorId;
        final myMembership =
            currentUserId != null ? group.getMember(currentUserId) : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              group.productName,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Only members and supplier can access chat
              if (isMember || isSupplier)
                IconButton(
                  icon: const Icon(Icons.chat_outlined),
                  onPressed: () => context.push('/group-chat/$groupId'),
                  tooltip: 'Group Chat',
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
                tooltip: 'Share Group',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              _StatusBanner(group: group),
              const SizedBox(height: 12),

              // Countdown + progress card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + countdown on same row — countdown is compact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Group Progress',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        // Use compact inline timer instead of box to avoid overflow
                        CountdownTimerWidget(
                          deadline: group.deadline,
                          showIcon: true,
                          compact: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GroupProgressWidget(group: group, showTiers: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // My participation card (buyers only, if member)
              if (!isSupplier && isMember && myMembership != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Participation',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          // Increase quantity button — only for active groups
                          // before payment is made
                          if (group.status == AppConstants.groupStatusActive &&
                              myMembership.paymentStatus ==
                                  AppConstants.paymentStatusPending)
                            GestureDetector(
                              onTap: () => _showIncreaseQuantitySheet(
                                context,
                                ref,
                                group: group,
                                currentQuantity: myMembership.quantity,
                                userId: currentUserId!,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Increase Qty',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _ParticipationStat(
                            label: 'Your Quantity',
                            value: '${myMembership.quantity} units',
                          ),
                          _ParticipationStat(
                            label: 'Your Total',
                            value: Formatters.formatCurrency(
                              group.currentPricePerUnit * myMembership.quantity,
                            ),
                          ),
                          _ParticipationStat(
                            label: 'Token Amount',
                            value: Formatters.formatCurrency(
                              group.currentPricePerUnit *
                                  myMembership.quantity *
                                  ((group.tokenPercentage ?? 10) / 100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _PaymentStatusChip(status: myMembership.paymentStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Discount approval status (buyer-initiated mode)
              if (group.mode == AppConstants.groupModeBuyerInitiated) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: group.discountApproved
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        group.discountApproved
                            ? Icons.verified_outlined
                            : Icons.pending_outlined,
                        color: group.discountApproved
                            ? AppColors.success
                            : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.discountApproved
                                  ? 'Discount Approved by Supplier'
                                  : 'Awaiting Supplier Approval',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: group.discountApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                            if (group.discountApprovalNote != null &&
                                group.discountApprovalNote!.isNotEmpty)
                              Text(
                                group.discountApprovalNote!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Members list
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
                    Text(
                      'Members (${group.memberCount})',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...group.members.map((member) => _MemberRow(
                          member: member,
                          isCurrentUser: member.userId == currentUserId,
                          isCreator: member.userId == group.creatorId,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Group info
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
                      'Group Info',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Supplier', value: group.supplierName),
                    _InfoRow(
                        label: 'Created by',
                        value: group.creatorBusinessName),
                    _InfoRow(
                      label: 'Group Mode',
                      value: group.mode == AppConstants.groupModeBuyerInitiated
                          ? 'Buyer Initiated'
                          : 'Supplier Target',
                    ),
                    _InfoRow(
                        label: 'Min. Quantity',
                        value: '${group.minimumQuantity} units'),
                    if (group.targetQuantity != null)
                      _InfoRow(
                          label: 'Target Quantity',
                          value: '${group.targetQuantity} units'),
                    _InfoRow(
                        label: 'Deadline',
                        value: Formatters.formatDateTime(group.deadline)),
                    _InfoRow(
                        label: 'Token Amount',
                        value:
                            '${group.tokenPercentage ?? 10}% of order value'),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),

          // Bottom actions
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildBottomActions(
              context,
              group: group,
              isMember: isMember,
              isCreator: isCreator,
              isSupplier: isSupplier,
              myMembership: myMembership,
              ref: ref,
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context, {
    required group,
    required bool isMember,
    required bool isCreator,
    required bool isSupplier,
    required myMembership,
    required WidgetRef ref,
  }) {
    // Suppliers see chat only — no join/payment actions
    if (isSupplier) {
      return AppButton(
        label: 'Open Group Chat',
        variant: AppButtonVariant.outline,
        onPressed: () => context.push('/group-chat/$groupId'),
        prefixIcon: Icons.chat_outlined,
      );
    }

    if (group.status == AppConstants.groupStatusCompleted) {
      if (isMember &&
          myMembership?.paymentStatus == AppConstants.paymentStatusPending) {
        return AppButton(
          label: 'Pay Token Amount',
          onPressed: () => context.push('/payment/token/$groupId'),
          prefixIcon: Icons.payment_outlined,
        );
      }
      if (isMember &&
          myMembership?.paymentStatus ==
              AppConstants.paymentStatusTokenPaid) {
        return AppButton(
          label: 'View Proforma Invoice',
          onPressed: () {},
          variant: AppButtonVariant.outline,
          prefixIcon: Icons.receipt_outlined,
        );
      }
      return const SizedBox(height: 8);
    }

    if (group.status == AppConstants.groupStatusExpired) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This group has expired',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'See Options',
            variant: AppButtonVariant.outline,
            onPressed: () => context.push('/group-expired/$groupId'),
            prefixIcon: Icons.help_outline,
            height: 44,
          ),
        ],
      );
    }

    if (!isMember) {
      return AppButton(
        label: 'Join This Group',
        onPressed: () => context.push('/join-group/$groupId'),
        prefixIcon: Icons.group_add_outlined,
      );
    }

    if (group.mode == AppConstants.groupModeBuyerInitiated &&
        !group.discountApproved &&
        isCreator) {
      return AppButton(
        label: 'Request Supplier Approval',
        onPressed: () async {
          await ref
              .read(groupServiceProvider)
              .requestDiscountApproval(groupId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Discount approval request sent to supplier')),
            );
          }
        },
        prefixIcon: Icons.send_outlined,
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Chat',
            variant: AppButtonVariant.outline,
            onPressed: () => context.push('/group-chat/$groupId'),
            prefixIcon: Icons.chat_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Invite',
            onPressed: () {},
            prefixIcon: Icons.person_add_outlined,
          ),
        ),
      ],
    );
  }

  /// Bottom sheet for increasing quantity
  void _showIncreaseQuantitySheet(
    BuildContext context,
    WidgetRef ref, {
    required group,
    required int currentQuantity,
    required String userId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _IncreaseQuantitySheet(
        groupId: groupId,
        group: group,
        currentQuantity: currentQuantity,
        userId: userId,
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final group;
  const _StatusBanner({required this.group});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (group.status) {
      case 'active':
        color = AppColors.groupActive;
        label = 'Group is Active';
        icon = Icons.groups_outlined;
        break;
      case 'completed':
        color = AppColors.groupCompleted;
        label = 'Group Completed! 🎉';
        icon = Icons.check_circle_outline;
        break;
      case 'expired':
        color = AppColors.groupExpired;
        label = 'Group Expired';
        icon = Icons.timer_off_outlined;
        break;
      case 'pending_approval':
        color = AppColors.groupPending;
        label = 'Awaiting Supplier Approval';
        icon = Icons.pending_outlined;
        break;
      default:
        color = AppColors.textSecondary;
        label = group.status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipationStat extends StatelessWidget {
  final String label;
  final String value;
  const _ParticipationStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ],
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final String status;
  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'token_paid':
        color = AppColors.warning;
        label = 'Token Paid';
        break;
      case 'full_paid':
        color = AppColors.success;
        label = 'Fully Paid';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Payment Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final member;
  final bool isCurrentUser;
  final bool isCreator;
  const _MemberRow(
      {required this.member,
      required this.isCurrentUser,
      required this.isCreator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              member.businessName.isNotEmpty
                  ? member.businessName[0].toUpperCase()
                  : 'B',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(member.businessName,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('You',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                color: Colors.white)),
                      ),
                    if (isCreator)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('Creator',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                color: Colors.white)),
                      ),
                  ],
                ),
                Text('${member.quantity} units',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          _PaymentStatusChip(status: member.paymentStatus),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── Increase Quantity Bottom Sheet ───────────────────────────────────────────

class _IncreaseQuantitySheet extends ConsumerStatefulWidget {
  final String groupId;
  final group;
  final int currentQuantity;
  final String userId;

  const _IncreaseQuantitySheet({
    required this.groupId,
    required this.group,
    required this.currentQuantity,
    required this.userId,
  });

  @override
  ConsumerState<_IncreaseQuantitySheet> createState() =>
      _IncreaseQuantitySheetState();
}

class _IncreaseQuantitySheetState
    extends ConsumerState<_IncreaseQuantitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _additionalQtyCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _additionalQtyCtrl.dispose();
    super.dispose();
  }

  int get _additionalQty =>
      int.tryParse(_additionalQtyCtrl.text.trim()) ?? 0;

  int get _newTotal => widget.currentQuantity + _additionalQty;

  double get _newTotalAmount =>
      widget.group.currentPricePerUnit * _newTotal;

  double get _additionalAmount =>
      widget.group.currentPricePerUnit * _additionalQty;

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(groupServiceProvider).updateMemberQuantity(
            groupId: widget.groupId,
            userId: widget.userId,
            additionalQuantity: _additionalQty,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Quantity updated to $_newTotal units!'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push sheet above keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Increase Your Quantity',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current: ${widget.currentQuantity} units · '
                '${Formatters.formatCurrency(widget.group.currentPricePerUnit)}/unit',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Input
              TextFormField(
                controller: _additionalQtyCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (v) => Validators.validateQuantity(v, min: 1),
                decoration: InputDecoration(
                  labelText: 'Additional Quantity',
                  hintText: 'How many more units?',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixText: 'units',
                ),
              ),
              const SizedBox(height: 16),

              // Live preview
              if (_additionalQty > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _PreviewRow(
                        label: 'Current quantity',
                        value: '${widget.currentQuantity} units',
                      ),
                      _PreviewRow(
                        label: 'Adding',
                        value: '+ $_additionalQty units',
                        valueColor: AppColors.success,
                      ),
                      const Divider(height: 14),
                      _PreviewRow(
                        label: 'New total',
                        value: '$_newTotal units',
                        isBold: true,
                      ),
                      _PreviewRow(
                        label: 'Additional cost',
                        value: Formatters.formatCurrency(_additionalAmount),
                        valueColor: AppColors.accent,
                      ),
                      _PreviewRow(
                        label: 'New order total',
                        value: Formatters.formatCurrency(_newTotalAmount),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              AppButton(
                label: _additionalQty > 0
                    ? 'Confirm — Add $_additionalQty units'
                    : 'Enter quantity above',
                onPressed: _additionalQty > 0 && !_isLoading ? _confirm : null,
                isLoading: _isLoading,
                prefixIcon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _PreviewRow({
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
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
