// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String profImage;
  final String username;
  final datePublished;
  final String filename;
  final List params;
  final String postUrl;
  final List authorizedUserIds;
  final String description;
  final likes;

  const Post({
    required this.postId,
    required this.uid,
    required this.profImage,
    required this.username,
    required this.datePublished,
    required this.filename,
    required this.params,
    required this.postUrl,
    required this.authorizedUserIds,
    required this.description,
    required this.likes,
  });

  // map post's parameter to json to create post
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'uid': uid,
        'profImage': profImage,
        'username': username,
        'datePublished': datePublished,
        'filename': filename,
        'params': params,
        'postUrl': postUrl,
        'authorizedUserIds': authorizedUserIds,
        'description': description,
        'likes': likes,
      };

  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      postId: snapshot['postId'],
      uid: snapshot['uid'],
      profImage: snapshot['profImage'],
      username: snapshot['username'],
      datePublished: snapshot['datePublished'],
      filename: snapshot['filename'],
      params: snapshot['params'],
      postUrl: snapshot['postUrl'],
      authorizedUserIds: snapshot['authorizedUserIds'],
      description: snapshot['description'],
      likes: snapshot['likes'],
    );
  }
}
