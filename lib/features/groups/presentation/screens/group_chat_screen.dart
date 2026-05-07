import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/group_provider.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<ChatMessageModel>> _messagesStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.chatsCollection)
        .doc(widget.groupId)
        .collection(AppConstants.messagesSubCollection)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final message = ChatMessageModel(
        id: '',
        groupId: widget.groupId,
        senderId: user.id,
        senderName: user.businessName,
        type: AppConstants.messageTypeText,
        text: text,
        sentAt: DateTime.now(),
        isRead: false,
        readBy: [user.id],
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.chatsCollection)
          .doc(widget.groupId)
          .collection(AppConstants.messagesSubCollection)
          .add(message.toFirestore());

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    await _uploadAndSendChatFile(
      File(picked.path),
      AppConstants.messageTypeImage,
      displayFileName: picked.name,
    );
  }

  Future<void> _sendVideo() async {
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (picked == null) return;
    await _uploadAndSendChatFile(
      File(picked.path),
      AppConstants.messageTypeVideo,
      displayFileName: picked.name,
    );
  }

  Future<void> _sendAudioPick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    final f = result.files.single;
    await _uploadAndSendChatFile(
      File(f.path!),
      AppConstants.messageTypeAudio,
      displayFileName: f.name,
      fileSizeBytes: f.size,
    );
  }

  Future<void> _sendGenericFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    final f = result.files.single;
    await _uploadAndSendChatFile(
      File(f.path!),
      AppConstants.messageTypeFile,
      displayFileName: f.name,
      fileSizeBytes: f.size,
    );
  }

  Future<void> _uploadAndSendChatFile(
    File file,
    String messageType, {
    String? displayFileName,
    int? fileSizeBytes,
    int? audioDurationSeconds,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final ext = _extensionFromPath(file.path);
      final storageName = '${const Uuid().v4()}.$ext';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(AppConstants.chatMediaPath)
          .child(widget.groupId)
          .child(storageName);

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      final message = ChatMessageModel(
        id: '',
        groupId: widget.groupId,
        senderId: user.id,
        senderName: user.businessName,
        type: messageType,
        mediaUrl: url,
        fileName: displayFileName ?? storageName,
        fileSizeBytes: fileSizeBytes,
        audioDurationSeconds: audioDurationSeconds,
        sentAt: DateTime.now(),
        isRead: false,
        readBy: [user.id],
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.chatsCollection)
          .doc(widget.groupId)
          .collection(AppConstants.messagesSubCollection)
          .add(message.toFirestore());

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _extensionFromPath(String path) {
    final i = path.lastIndexOf('.');
    if (i == -1 || i == path.length - 1) return 'dat';
    return path.substring(i + 1).toLowerCase();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group?.productName ?? 'Group Chat',
                  style: const TextStyle(fontSize: 16)),
              Text(
                '${group?.memberCount ?? 0} members',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          loading: () => const Text('Group Chat'),
          error: (_, __) => const Text('Group Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Group details',
            onPressed: () => context.push('/group/${widget.groupId}'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet.\nStart the conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    final showSender = i == 0 ||
                        messages[i - 1].senderId != msg.senderId;

                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      showSender: showSender,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment button
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: AppColors.textSecondary),
                    onPressed: () => _showAttachmentOptions(context),
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: _isSending ? null : _sendTextMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isSending
                            ? AppColors.border
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
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
              const SizedBox(height: 20),
              const Text(
                'Share',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.image_outlined,
                    label: 'Image',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendImage();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendVideo();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.mic_outlined,
                    label: 'Audio',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAudioOptions();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'File',
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendGenericFile();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Audio',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.primary),
              title: const Text('Record voice note',
                  style: TextStyle(fontFamily: 'Poppins')),
              subtitle: const Text('Up to 3 minutes',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textHint)),
              onTap: () {
                Navigator.pop(ctx);
                _openVoiceRecorder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined,
                  color: AppColors.accent),
              title: const Text('Choose audio file',
                  style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(ctx);
                _sendAudioPick();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openVoiceRecorder() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _VoiceRecordSheet(
        onDismiss: () => Navigator.pop(sheetCtx),
        onSend: (file, seconds) async {
          Navigator.pop(sheetCtx);
          await _uploadAndSendChatFile(
            file,
            AppConstants.messageTypeAudio,
            displayFileName: 'Voice note.m4a',
            fileSizeBytes: await file.length(),
            audioDurationSeconds: seconds < 1 ? 1 : seconds,
          );
        },
      ),
    );
  }
}

/// Bottom sheet: record a voice note, then upload as chat audio message.
class _VoiceRecordSheet extends StatefulWidget {
  final VoidCallback onDismiss;
  final Future<void> Function(File file, int durationSeconds) onSend;

  const _VoiceRecordSheet({
    required this.onDismiss,
    required this.onSend,
  });

  @override
  State<_VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<_VoiceRecordSheet> {
  AudioRecorder? _recorder;
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;
  bool _starting = false;
  bool _finishing = false;
  String? _path;

  static const int _maxSeconds = 180;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_silenceRecorder());
    super.dispose();
  }

  Future<void> _silenceRecorder() async {
    try {
      final r = _recorder;
      if (r != null) {
        if (await r.isRecording()) {
          await r.stop();
        }
        await r.dispose();
      }
    } catch (_) {}
    _recorder = null;
  }

  Future<void> _requestAndStart() async {
    setState(() => _starting = true);
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record'),
          ),
        );
      }
      setState(() => _starting = false);
      widget.onDismiss();
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/voice_${const Uuid().v4()}.m4a';
      _recorder = AudioRecorder();
      if (!await _recorder!.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot access microphone')),
          );
        }
        await _recorder!.dispose();
        _recorder = null;
        setState(() => _starting = false);
        widget.onDismiss();
        return;
      }

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _path!,
      );

      _seconds = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= _maxSeconds) {
          t.cancel();
          _timer = null;
          unawaited(_finishRecording());
        }
      });

      setState(() {
        _recording = true;
        _starting = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
      setState(() => _starting = false);
      await _silenceRecorder();
      widget.onDismiss();
    }
  }

  Future<void> _finishRecording() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    _timer = null;

    final path = _path;
    final dur = _seconds;

    setState(() => _recording = false);

    try {
      if (_recorder != null) {
        if (await _recorder!.isRecording()) {
          await _recorder!.stop();
        }
        await _recorder!.dispose();
        _recorder = null;
      }
    } catch (_) {}

    if (path != null && dur > 0) {
      final f = File(path);
      if (await f.exists() && await f.length() > 0) {
        await widget.onSend(f, dur);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing recorded')),
      );
    }
    widget.onDismiss();
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _timer = null;
    final path = _path;

    try {
      if (_recorder != null) {
        if (await _recorder!.isRecording()) {
          await _recorder!.stop();
        }
        await _recorder!.dispose();
        _recorder = null;
      }
    } catch (_) {}

    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Voice note',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (!_recording && !_starting)
                Text(
                  'Record up to ${Formatters.formatAudioDuration(_maxSeconds)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 20),
              if (_starting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              if (!_recording && !_starting) ...[
                FilledButton.icon(
                  onPressed: _requestAndStart,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text(
                    'Start recording',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
                TextButton(
                  onPressed: _cancelRecording,
                  child: const Text('Cancel',
                      style: TextStyle(fontFamily: 'Poppins')),
                ),
              ],
              if (_recording) ...[
                Text(
                  Formatters.formatAudioDuration(_seconds),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recording…',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: _cancelRecording,
                      child: const Text('Cancel',
                          style: TextStyle(fontFamily: 'Poppins')),
                    ),
                    FilledButton.icon(
                      onPressed: _finishing ? null : () => _finishRecording(),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop & send',
                          style: TextStyle(fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool showSender;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text ?? '',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'B',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSender && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: (message.type == AppConstants.messageTypeImage ||
                          message.type == AppConstants.messageTypeVideo)
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.chatBubbleSent
                        : AppColors.chatBubbleReceived,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: _buildMessageContent(context),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    Formatters.formatTime(message.sentAt),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case AppConstants.messageTypeImage:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.mediaUrl ?? '',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
          ),
        );

      case AppConstants.messageTypeVideo:
        return InkWell(
          onTap: () => _launchChatMediaUrl(context, message.mediaUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 200,
              height: 120,
              color: Colors.black.withValues(alpha: 0.78),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 52),
                  SizedBox(height: 6),
                  Text(
                    'Video · tap to open',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          ),
        );

      case AppConstants.messageTypeFile:
        return InkWell(
          onTap: () => _launchChatMediaUrl(context, message.mediaUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                color: isMe ? Colors.white : AppColors.primary,
                size: 26,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? 'Attachment',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.fileSizeBytes != null)
                      Text(
                        Formatters.formatFileSize(message.fileSizeBytes!),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isMe
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

      case AppConstants.messageTypeAudio:
        return InkWell(
          onTap: () => _launchChatMediaUrl(context, message.mediaUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                color: isMe ? Colors.white : AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio · tap to open',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (message.audioDurationSeconds != null)
                    Text(
                      Formatters.formatAudioDuration(
                          message.audioDurationSeconds!),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isMe ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

      default:
        return Text(
          message.text ?? '',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isMe ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        );
    }
  }
}

Future<void> _launchChatMediaUrl(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open this attachment')),
      );
    }
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
