// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:lets_gamez/models/post.dart';
import 'package:lets_gamez/resources/storage_methods.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // upload post
  Future<List<String>> uploadPost(
    String uid,
    String profImage,
    String username,
    String filename,
    Uint8List file,
    List authorizedUserIds,
    String description,
  ) async {
    List<String> res = ['error', ''];
    try {
      // generate params for aes-256 encryption
      List<Uint8List> params = generateParams();
      // convert params from Uint8List to string
      List<String> paramsString = [
        convertToString(params[0]),
        convertToString(params[1]),
      ];
      // perform aes-256 cbc mode encryption
      file = await encryptFile(params, file);

      // rename file by adding .aes at end of file extension
      filename = '$filename.aes';

      List<String> fileDetails =
          await StorageMethods().uploadFileToStorage('posts', file, true);

      Post post = Post(
        postId: fileDetails[0],
        uid: uid,
        profImage: profImage,
        username: username,
        datePublished: DateTime.now(),
        filename: filename,
        params: paramsString,
        postUrl: fileDetails[1],
        authorizedUserIds: authorizedUserIds,
        description: description,
        likes: [],
      );

      _firebaseFirestore.collection('posts').doc(fileDetails[0]).set(
            post.toJson(),
          );

      // update postId of post to user document
      await _firebaseFirestore.collection('users').doc(uid).update({
        'postIds': FieldValue.arrayUnion([fileDetails[0]]),
      });

      res[0] = 'success';
      res[1] = fileDetails[0];
    } catch (e) {
      res[0] = e.toString();
    }
    return res;
  }

  // checking if likePost or likeComment has been done in 5 minutes ago (for anti spamming)
  Future<bool> likedPostOrComment(String ownerId) async {
    bool liked = false;
    QuerySnapshot<Map<String, dynamic>> notiSnaps = await _firebaseFirestore
        .collection('users')
        .doc(ownerId)
        .collection('notifications')
        .get();
    for (int i = 0; i < notiSnaps.docs.length; i++) {
      String notificationId = notiSnaps.docs[i].data()['notificationId'];
      DocumentSnapshot<Map<String, dynamic>> notiSnap = await _firebaseFirestore
          .collection('users')
          .doc(ownerId)
          .collection('notifications')
          .doc(notificationId)
          .get();
      String type = notiSnap.data()!['type'];
      DateTime datePublished = notiSnap.data()!['datePublished'].toDate();
      if (type == 'like' || type == 'like_2') {
        Duration diff = DateTime.now().difference(datePublished);
        if (diff.inMinutes < 5) {
          liked = true;
          break;
        }
      } else {
        liked = false;
      }
    }
    return liked;
  }

  // adding like to post
  Future<void> likePost(String uid, String profilePic, String username,
      String postId, String ownerId, List likes) async {
    try {
      if (likes.contains(uid)) {
        // removing like
        await _firebaseFirestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        // adding like
        await _firebaseFirestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
        if (uid != ownerId) {
          bool liked = await likedPostOrComment(ownerId);
          if (!liked) {
            await sendNotification(
                ownerId, postId, uid, profilePic, username, '', 'like');
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // adding comment to post
  Future<void> postComment(String postId, String ownerId, String uid,
      String profilePic, String username, String text) async {
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firebaseFirestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'commentId': commentId,
          'uid': uid,
          'profilePic': profilePic,
          'username': username,
          'text': text,
          'datePublished': DateTime.now(),
          'likes': [],
        });
        // update commentId of comment to user document
        await _firebaseFirestore.collection('users').doc(uid).update({
          'commentIds': FieldValue.arrayUnion([commentId]),
        });

        if (uid != ownerId) {
          await sendNotification(
              ownerId, postId, uid, profilePic, username, '', 'comment');
        }
      } else {
        print('Empty text');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // adding like to comment
  Future<void> likeComment(String postId, String commentId, String uid,
      String profilePic, String username, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firebaseFirestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firebaseFirestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'likes': FieldValue.arrayUnion([uid]),
        });
        DocumentSnapshot snap = await _firebaseFirestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .get();
        String ownerId = (snap.data()! as dynamic)['uid'];
        if (uid != ownerId) {
          bool liked = await likedPostOrComment(ownerId);
          if (!liked) {
            await sendNotification(
                ownerId, postId, uid, profilePic, username, '', 'like_2');
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // editing post description
  Future<String> editPost(
    String postId,
    List authorizedUserIds,
    String description,
  ) async {
    String res = 'error';
    try {
      _firebaseFirestore.collection('posts').doc(postId).update({
        'authorizedUserIds': authorizedUserIds,
        'description': description,
      });
      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // deleting post
  Future<void> deletePost(String uid, String postId) async {
    try {
      // delete commentIds from users documents
      // find out commentIds of comments under the post
      var commentSnap = await _firebaseFirestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();
      List commentIds = [];
      for (int i = 0; i < commentSnap.docs.length; i++) {
        commentIds.add(commentSnap.docs[i].data()['commentId']);
      }
      // find out owners of those comments
      var userSnap = await _firebaseFirestore.collection('users').get();
      for (int i = 0; i < userSnap.docs.length; i++) {
        String userId = userSnap.docs[i].data()['uid'];
        for (int j = 0; j < commentIds.length; j++) {
          if (userSnap.docs[i].data()['commentIds'].contains(commentIds[j])) {
            await _firebaseFirestore.collection('users').doc(userId).update({
              'commentIds': FieldValue.arrayRemove([commentIds[j]]),
            });
          }
        }
      }
      // delete postId from user document
      await _firebaseFirestore.collection('users').doc(uid).update({
        'postIds': FieldValue.arrayRemove([postId]),
      });
      // delete post from post collection
      await _firebaseFirestore.collection('posts').doc(postId).delete();
      // delete file from Firebase Storage
      await StorageMethods().deleteFileFromStorage(uid, postId);
    } catch (e) {
      print(e.toString());
    }
  }

  // download post
  Future<List<String>> downloadPost(
      String uid, String postId, String filename) async {
    List<String> res = ['error', ''];
    try {
      // Retrieve file in Uint8List from Firebase Storage
      Uint8List file =
          await StorageMethods().downloadFileFromStorage(uid, postId);

      // revert change on filename
      filename = filename.replaceAll('.aes', '');

      // get params for aes-256 decryption
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      List paramsString = postSnap.data()!['params'];
      List<Uint8List> params = [
        convertToUint8List(paramsString[0]),
        convertToUint8List(paramsString[1]),
      ];

      // perform aes-256 cbc mode decryption
      file = await decryptFile(params, file);

      // get path for external storage
      String path = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS);

      // convert file from Uint8List to File and write in 'Download' folder in android emulator
      final out = await File('$path/$filename').create();
      out.writeAsBytes(file);

      res[0] = 'success';
      res[1] = out.path;
    } catch (e) {
      res[0] = e.toString();
    }
    return res;
  }

  // sending new notification to user
  Future<String> sendNotification(
    String ownerId,
    String postId,
    String requestId,
    String profilePic,
    String username,
    String filename,
    String type,
  ) async {
    String res = 'error';
    try {
      String notificationId = const Uuid().v1();

      // set detail of notification
      String detail = '';
      switch (type) {
        case 'upload':
          detail = 'new post now !';
          break;
        case 'like':
          detail = 'liked your post.';
          break;
        case 'like_2':
          detail = 'liked your comment.';
          break;
        case 'comment':
          detail = 'commented on your post.';
          break;
        case 'request':
          detail = 'requested to download your file.';
          break;
        case 'allow':
          detail = 'allowed your request to download file.';
          break;
        case 'deny':
          detail = 'denied your request to download file.';
          break;
      }

      // add to notifications collection
      await _firebaseFirestore
          .collection('users')
          .doc(ownerId)
          .collection('notifications')
          .doc(notificationId)
          .set({
        'notificationId': notificationId,
        'postId': postId,
        'uid': ownerId,
        'requestId': requestId,
        'profilePic': profilePic,
        'username': username,
        'filename': filename,
        'detail': detail,
        'datePublished': DateTime.now(),
        'status': 'unread',
        'type': type,
      });

      await updateUnreadNotifications(ownerId);

      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // add requester uid to authorizedIds
  Future<void> addPermission(String postId, String requestId) async {
    DocumentSnapshot snap =
        await _firebaseFirestore.collection('posts').doc(postId).get();
    List authorizeds = (snap.data()! as dynamic)['authorizedUserIds'];
    if (!authorizeds.contains(requestId)) {
      await _firebaseFirestore.collection('posts').doc(postId).update({
        'authorizedUserIds': FieldValue.arrayUnion([requestId]),
      });
    }
  }

  // update status of notification
  Future<void> readNotification(
    String ownerId,
    String notificationId,
    String result,
  ) async {
    await _firebaseFirestore
        .collection('users')
        .doc(ownerId)
        .collection('notifications')
        .doc(notificationId)
        .update({
      'status': result,
    });
    await updateUnreadNotifications(ownerId);
  }

  // update counter for unread notifications
  Future<void> updateUnreadNotifications(String uid) async {
    int counter = 0;
    QuerySnapshot<Map<String, dynamic>> snapshots = await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();
    for (int i = 0; i < (snapshots as dynamic).docs.length; i++) {
      if (snapshots.docs[i].data()['status'] == 'unread') {
        counter++;
      }
    }
    await _firebaseFirestore.collection('users').doc(uid).update({
      'unreadNotifications': counter,
    });
  }

  /* // remove all notifications (will cause bug as this action will not stop)
  Future<void> removeNotifications(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .forEach((element) {
      for (QueryDocumentSnapshot docSnapshot in element.docs) {
        docSnapshot.reference.delete().then((value) => null);
      }
    });
  } */

  // subscribing or unsubscribing user
  Future<void> subscribeUser(String uid, String subscribeId) async {
    try {
      DocumentSnapshot snap =
          await _firebaseFirestore.collection('users').doc(uid).get();
      List subscribing = (snap.data()! as dynamic)['subscribing'];

      if (subscribing.contains(subscribeId)) {
        await _firebaseFirestore.collection('users').doc(subscribeId).update({
          'subscribers': FieldValue.arrayRemove([uid])
        });
        await _firebaseFirestore.collection('users').doc(uid).update({
          'subscribing': FieldValue.arrayRemove([subscribeId])
        });
      } else {
        await _firebaseFirestore.collection('users').doc(subscribeId).update({
          'subscribers': FieldValue.arrayUnion([uid])
        });
        await _firebaseFirestore.collection('users').doc(uid).update({
          'subscribing': FieldValue.arrayUnion([subscribeId])
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // update users to send notification when new post is uploaded
  Future<String> updateNotify(String ownerId, String uid) async {
    String res = '';
    try {
      DocumentSnapshot snap =
          await _firebaseFirestore.collection('users').doc(ownerId).get();
      List notify = (snap.data()! as dynamic)['notify'];

      if (notify.contains(uid)) {
        await _firebaseFirestore.collection('users').doc(ownerId).update({
          'notify': FieldValue.arrayRemove([uid])
        });
      } else {
        await _firebaseFirestore.collection('users').doc(ownerId).update({
          'notify': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // editing user profile
  Future<String> editProfile(
    String uid,
    String newUsername,
    String phone,
    String bio,
    Uint8List? profilePic,
  ) async {
    String res = 'error';
    List photoDetails = ['', ''];
    try {
      var userSnap =
          await _firebaseFirestore.collection('users').doc(uid).get();
      if (profilePic == null) {
        photoDetails.setAll(1, [await userSnap.data()!['photoUrl']]);
      } else {
        // delete old profilePic from Firebase Storage
        await StorageMethods().deleteProfilePicFromStorage(uid);

        // upload new profilePic to Firebase Storage
        photoDetails = await StorageMethods()
            .uploadFileToStorage('profilePics', profilePic, false);
      }

      if (RegExp(r'(^[0]{1}[1]{1}[1]{1}[0-9]{8}$)').hasMatch(phone) ||
          RegExp(r'(^[0]{1}[1]{1}[0-9]{1}[0-9]{7}$)').hasMatch(phone)) {
        // update user information
        await _firebaseFirestore.collection('users').doc(uid).update({
          'username': newUsername,
          'phone': phone,
          'bio': bio,
          'photoUrl': photoDetails[1],
        });

        // store postIds
        List postIds = userSnap.data()!['postIds'];
        // store commentIds
        List commentIds = userSnap.data()!['commentIds'];

        var postSnap = await _firebaseFirestore.collection('posts').get();
        for (int i = 0; i < postSnap.docs.length; i++) {
          String postId = postSnap.docs[i].data()['postId'];
          if (postIds.contains(postId)) {
            // edit posts details
            await _firebaseFirestore.collection('posts').doc(postId).update({
              'username': newUsername,
              'profImage': photoDetails[1],
            });
          }
          var commentSnap = await _firebaseFirestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .get();
          for (int j = 0; j < commentSnap.docs.length; j++) {
            String commentId = commentSnap.docs[j].data()['commentId'];
            if (commentIds.contains(commentId)) {
              // edit comments details
              await _firebaseFirestore
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .doc(commentId)
                  .update({
                'username': newUsername,
                'profilePic': photoDetails[1],
              });
            }
          }
        }

        var userSnaps = await _firebaseFirestore.collection('users').get();
        for (int i = 0; i < userSnaps.docs.length; i++) {
          String userId = userSnaps.docs[i].data()['uid'];
          var notiSnaps = await _firebaseFirestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .get();
          for (int j = 0; j < notiSnaps.docs.length; j++) {
            String notificationId = notiSnaps.docs[j].data()['notificationId'];
            var notiSnap = await _firebaseFirestore
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .doc(notificationId)
                .get();
            if (notiSnap.data()!['requestId'] == uid) {
              // edit notifications details
              await _firebaseFirestore
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .doc(notificationId)
                  .update({
                'username': newUsername,
                'profilePic': photoDetails[1],
              });
            }
          }
        }
        res = 'success';
      } else {
        res = 'Invalid phone, e.g. 01xxxxxxxx';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }
}
