import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

class UploadPaymentProofScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String paymentType; // 'token' | 'final'
  final String? orderId;

  const UploadPaymentProofScreen({
    super.key,
    required this.groupId,
    required this.paymentType,
    this.orderId,
  });

  @override
  ConsumerState<UploadPaymentProofScreen> createState() =>
      _UploadPaymentProofScreenState();
}

class _UploadPaymentProofScreenState
    extends ConsumerState<UploadPaymentProofScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _selectedFile = File(picked.path));
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Source',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Camera',
                    style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Gallery',
                    style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a payment screenshot first')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final fileName = '${const Uuid().v4()}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(AppConstants.paymentProofsPath)
          .child(user.id)
          .child(fileName);

      final uploadTask = storageRef.putFile(_selectedFile!);

      uploadTask.snapshotEvents.listen((snap) {
        setState(() {
          _uploadProgress =
              snap.bytesTransferred / snap.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // Save proof record to Firestore
      await FirebaseFirestore.instance
          .collection(AppConstants.paymentsCollection)
          .add({
        'groupId': widget.groupId,
        if (widget.orderId != null) 'orderId': widget.orderId,
        'userId': user.id,
        'businessName': user.businessName,
        'paymentType': widget.paymentType,
        'proofImageUrl': downloadUrl,
        'notes': _notesCtrl.text.trim(),
        'status': 'pending_verification',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update member payment status to token_paid if token payment
      if (widget.paymentType == 'token') {
        await ref.read(groupServiceProvider).updateMemberPaymentStatus(
              widget.groupId,
              user.id,
              AppConstants.paymentStatusTokenPaid,
            );
        final orderSnap = await FirebaseFirestore.instance
            .collection(AppConstants.ordersCollection)
            .where('groupId', isEqualTo: widget.groupId)
            .where('buyerId', isEqualTo: user.id)
            .limit(1)
            .get();
        if (orderSnap.docs.isNotEmpty) {
          await orderSnap.docs.first.reference.update({
            'paymentStatus': AppConstants.paymentStatusTokenPaid,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      if (widget.paymentType == 'final' && widget.orderId != null) {
        await FirebaseFirestore.instance
            .collection(AppConstants.ordersCollection)
            .doc(widget.orderId)
            .update({
          'paymentStatus': AppConstants.paymentStatusFullPaid,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment proof uploaded! Our team will verify within 2 hours.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paymentType == 'token'
            ? 'Upload Token Payment Proof'
            : 'Upload Payment Proof'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload a screenshot of your payment confirmation (UPI, bank transfer, etc.). Our team will verify within 2 hours.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Image picker area
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null
                      ? AppColors.primary
                      : AppColors.border,
                  width: _selectedFile != null ? 2 : 1,
                  style: _selectedFile == null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              child: _selectedFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_outlined,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to upload screenshot',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'JPG, PNG up to 10MB',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (_selectedFile != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Change Image',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],

          const SizedBox(height: 20),

          // Notes field
          TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText:
                  'e.g., Transaction ID, payment reference...',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),

          // Upload progress
          if (_isUploading) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Uploading...',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                    Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],

          AppButton(
            label: 'Submit Payment Proof',
            onPressed: _isUploading ? null : _upload,
            isLoading: _isUploading,
            prefixIcon: Icons.cloud_upload_outlined,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
