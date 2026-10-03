import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<ChatMessage>> watchMessages(User recipient) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      return Stream.error(StateError('Sign in to view messages.'));
    }
    if (recipient.uid.isEmpty || recipient.uid == currentUserId) {
      return Stream.error(StateError('This chat participant is invalid.'));
    }

    final chatId = _chatId(currentUserId, recipient.uid);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => ChatMessage.fromMap(document.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required User recipient,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    final currentUserId = currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw StateError('Sign in to send messages.');
    }
    if (recipient.uid.isEmpty || recipient.uid == currentUserId) {
      throw StateError('This chat participant is invalid.');
    }

    final chatId = _chatId(currentUserId, recipient.uid);
    final chat = _firestore.collection('chats').doc(chatId);
    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((transaction) async {
      transaction.set(chat, {
        'participants': [currentUserId, recipient.uid],
        'updatedAt': now,
      }, SetOptions(merge: true));
      transaction.set(chat.collection('messages').doc(), {
        'senderId': currentUserId,
        'recipientId': recipient.uid,
        'text': text,
        'createdAt': now,
      });
    });
  }

  String _chatId(String firstUserId, String secondUserId) {
    final participants = [firstUserId, secondUserId]..sort();
    return participants.join('__');
  }
}

class ChatMessage {
  const ChatMessage({required this.text, required this.senderId});

  final String text;
  final String senderId;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
    );
  }
}
