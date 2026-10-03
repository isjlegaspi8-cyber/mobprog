import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({required this.user, super.key});

  final User user;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  late final Stream<List<ChatMessage>> _messagesStream;
  late final StreamSubscription<List<ChatMessage>> _messagesSubscription;
  String get _currentUserId => _chatService.currentUserId ?? '';
  bool _isSending = false;
  String? _messagesError;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.watchMessages(widget.user);
    _messagesSubscription = _messagesStream.listen(
      (messages) {
        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _messagesError = null;
          _isLoadingMessages = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _messagesError = error.toString();
          _isLoadingMessages = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(recipient: widget.user, text: messageText);
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.user.fullName.isNotEmpty
        ? widget.user.fullName
        : widget.user.username;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              child: CustomText(
                text: displayName.substring(0, 1).toUpperCase(),
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: displayName,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomText(
                    text: 'Online now',
                    fontSize: 11.sp,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.30,
                    ),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : _messagesError != null
                  ? Center(
                      child: CustomText(
                        text: 'Could not load messages: $_messagesError',
                        fontSize: 14.sp,
                        color: theme.colorScheme.error,
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 36.sp,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          CustomText(
                            text: 'No messages yet. Say hello!',
                            fontSize: 14.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (_, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == _currentUserId;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: EdgeInsets.only(bottom: 10.h),
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 0.72.sw),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isMe
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isMe ? 18.r : 10.r),
                                  topRight: Radius.circular(isMe ? 10.r : 18.r),
                                  bottomLeft: Radius.circular(18.r),
                                  bottomRight: Radius.circular(18.r),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: message.text,
                                      fontSize: 15.sp,
                                      color: isMe
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(22.r),
                  child: InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(22.r),
                    child: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Icon(
                        _isSending
                            ? Icons.hourglass_top_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
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
}
