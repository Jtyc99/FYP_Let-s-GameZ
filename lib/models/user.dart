import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String username;
  final String email;
  final String phone;
  final String bio;
  final String password;
  final String photoUrl;
  final List subscribers;
  final List subscribing;
  final List postIds;
  final List commentIds;
  final int unreadNotifications;
  final List notify;

  const User({
    required this.uid,
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.password,
    required this.photoUrl,
    required this.subscribers,
    required this.subscribing,
    required this.postIds,
    required this.commentIds,
    required this.unreadNotifications,
    required this.notify,
  });

  // map user's parameter to json to create user
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'email': email,
        'phone': phone,
        'bio': bio,
        'password': password,
        'photoUrl': photoUrl,
        'subscribers': subscribers,
        'subscribing': subscribing,
        'postIds': postIds,
        'commentIds': commentIds,
        'unreadNotifications': unreadNotifications,
        'notify': notify,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'],
      username: snapshot['username'],
      email: snapshot['email'],
      phone: snapshot['phone'],
      bio: snapshot['bio'],
      password: snapshot['password'],
      photoUrl: snapshot['photoUrl'],
      subscribers: snapshot['subscribers'],
      subscribing: snapshot['subscribing'],
      postIds: snapshot['postIds'],
      commentIds: snapshot['commentIds'],
      unreadNotifications: snapshot['unreadNotifications'],
      notify: snapshot['notify'],
    );
  }
}
