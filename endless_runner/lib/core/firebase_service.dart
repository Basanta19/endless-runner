import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'game_data.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Syncs local game data to Firestore.
  /// This ensures progress is saved to the cloud using the user's anonymous ID.
  Future<void> syncToCloud() async {
    try {
      User? user = _auth.currentUser;
      // Sign in anonymously if not already signed in
      user ??= (await _auth.signInAnonymously()).user;

      if (user != null) {
        final data = GameData();

        // Save detailed user progress
        await _db.collection('users').doc(user.uid).set({
          'coins': data.coins,
          'gems': data.gems,
          'highScore': data.highScore,
          'selectedCharacter': data.selectedCharacter,
          'unlockedCharacters': data.unlockedCharacters,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update global leaderboard if they have a score
        if (data.highScore > 0) {
          final displayName = data.nickname == "Player"
              ? 'Player_${user.uid.substring(0, 4)}'
              : data.nickname;

          await _db.collection('leaderboard').doc(user.uid).set({
            'score': data.highScore,
            'name': displayName,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Silence errors if offline or not configured yet
      debugPrint('Firebase Sync Error: $e');
    }
  }

  /// Fetches top scores for a leaderboard UI
  Stream<QuerySnapshot> getLeaderboard() {
    return _db
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(20)
        .snapshots();
  }
}
