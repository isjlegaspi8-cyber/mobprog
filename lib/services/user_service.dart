import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      try {
        await _loadProfile(user);
      } catch (error) {
        debugPrint('Signed in, but Firestore profile sync failed: $error');
        await _saveAuthIdentity(user);
      }
    }
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Firebase did not return a user.');

    try {
      await user.updateDisplayName(username.trim());
    } catch (error) {
      debugPrint('Could not update Firebase Auth display name: $error');
    }
    final profile = <String, dynamic>{
      'uid': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'age': age,
      'contactNo': contactNo.trim(),
      'username': username.trim(),
      'email': user.email ?? email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(user.uid).set(profile);
    await _cacheProfile(user, profile);
    return credential;
  }

  Future<void> _loadProfile(firebase_auth.User user) async {
    final profileRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await profileRef.get();
    Map<String, dynamic> profile;

    if (snapshot.exists) {
      profile = snapshot.data() ?? <String, dynamic>{};
    } else {
      final prefs = await SharedPreferences.getInstance();
      final sameUser = prefs.getString('uid') == user.uid;
      profile = {
        'uid': user.uid,
        'firstName': sameUser ? prefs.getString('firstName') ?? '' : '',
        'lastName': sameUser ? prefs.getString('lastName') ?? '' : '',
        'age': sameUser ? prefs.getInt('age') ?? 0 : 0,
        'contactNo': sameUser ? prefs.getString('contactNo') ?? '' : '',
        'username':
            user.displayName ??
            (sameUser ? prefs.getString('username') ?? '' : ''),
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await profileRef.set(profile);
    }

    profile['uid'] = user.uid;
    profile['email'] = user.email ?? profile['email'] ?? '';
    profile['username'] = user.displayName ?? profile['username'] ?? '';
    await _cacheProfile(user, profile);
  }

  Future<void> _cacheProfile(
    firebase_auth.User user,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final previousUid = prefs.getString('uid');
    if (previousUid != null && previousUid != user.uid) {
      for (final key in ['firstName', 'lastName', 'age', 'contactNo']) {
        await prefs.remove(key);
      }
    }
    await prefs.setString('uid', user.uid);
    await prefs.setString('username', profile['username']?.toString() ?? '');
    await prefs.setString('email', profile['email']?.toString() ?? '');
    await prefs.setString('firstName', profile['firstName']?.toString() ?? '');
    await prefs.setString('lastName', profile['lastName']?.toString() ?? '');
    final age = profile['age'];
    await prefs.setInt('age', age is int ? age : int.tryParse('$age') ?? 0);
    await prefs.setString('contactNo', profile['contactNo']?.toString() ?? '');
    await prefs.setInt('id', 1);
  }

  Future<void> _saveAuthIdentity(firebase_auth.User user) async {
    final prefs = await SharedPreferences.getInstance();
    final previousUid = prefs.getString('uid');
    if (previousUid != null && previousUid != user.uid) {
      for (final key in ['firstName', 'lastName', 'age', 'contactNo']) {
        await prefs.remove(key);
      }
    }
    await prefs.setString('uid', user.uid);
    await prefs.setString('email', user.email ?? '');
    await prefs.setString(
      'username',
      user.displayName ?? user.email?.split('@').first ?? '',
    );
  }

  Future<Map<String, dynamic>> getUserData() async {
    final user = currentUser;
    if (user != null) {
      try {
        await _loadProfile(user);
      } catch (error) {
        debugPrint('Could not refresh profile from Firestore: $error');
      }
    }
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getInt('id') ?? 1;

    return {
      'id': savedId > 0 ? savedId : 1,
      'uid': user?.uid ?? prefs.getString('uid') ?? '',
      'username': prefs.getString('username') ?? user?.displayName ?? '',
      'email': user?.email ?? prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'contactNo': prefs.getString('contactNo') ?? '',
    };
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  Future<List<User>> getAllUsersForChat() async {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    final snapshot = await _firestore.collection('users').get();
    final users = <User>[];

    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;

      final data = doc.data();
      final user = User.fromJson({...data, 'uid': doc.id});

      if (user.email.isEmpty &&
          user.username.isEmpty &&
          user.fullName.isEmpty) {
        continue;
      }

      users.add(user);
    }

    users.sort(
      (a, b) => (a.fullName.isNotEmpty ? a.fullName : a.username)
          .toLowerCase()
          .compareTo(
            (b.fullName.isNotEmpty ? b.fullName : b.username).toLowerCase(),
          ),
    );

    return users;
  }

  Future<bool> isLoggedIn() async {
    return await authStateChanges.first != null;
  }

  Future<void> updateUsername(String username) async {
    final user = currentUser;
    if (user == null) throw Exception('No signed-in user.');
    await user.updateDisplayName(username.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'username': username.trim(),
    }, SetOptions(merge: true));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username.trim());
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw Exception('No signed-in email account.');
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    try {
      await user.reauthenticateWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password') {
        throw Exception(
          'Current password was not accepted. Enter the password you use to sign in.',
        );
      }
      rethrow;
    }
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount({required String password}) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw Exception('No signed-in email account.');
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
    await _clearProfile();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> logout() => signOut();

  Future<void> _clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'id',
      'uid',
      'username',
      'email',
      'firstName',
      'lastName',
      'age',
      'contactNo',
    ]) {
      await prefs.remove(key);
    }
  }
}
