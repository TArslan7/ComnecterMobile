
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _firestore
        .collection('friend_requests')
        .doc(toUserId)
        .collection('incoming')
        .doc(fromUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> acceptFriendRequest(String currentUserId, String requesterId) async {
    await _firestore.collection('friendships').doc(currentUserId).collection('friends').doc(requesterId).set({});
    await _firestore.collection('friendships').doc(requesterId).collection('friends').doc(currentUserId).set({});
    await _firestore.collection('friend_requests').doc(currentUserId).collection('incoming').doc(requesterId).delete();
  }

  Future<List<String>> getFriendList(String userId) async {
    final snapshot = await _firestore.collection('friendships').doc(userId).collection('friends').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
