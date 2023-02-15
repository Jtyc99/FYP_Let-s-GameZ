// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // upload file to firebase
  Future<List<String>> uploadFileToStorage(
      String childName, Uint8List file, bool isPost) async {
    Reference ref =
        _storage.ref().child(childName).child(_auth.currentUser!.uid);

    String id = '';
    if (isPost) {
      id = const Uuid().v1();
      ref = ref.child(id);
    }

    UploadTask uploadTask = ref.putData(file);

    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return [id, downloadUrl];
  }

  // retrieve file from firebase
  Future<Uint8List> downloadFileFromStorage(String uid, String postId) async {
    Reference ref = _storage.ref().child('posts').child(uid).child(postId);
    Uint8List file = await ref.getData() as Uint8List;
    return file;
  }

  // delete file from firebase
  Future<void> deleteFileFromStorage(String uid, String postId) async {
    try {
      Reference ref = _storage.ref().child('posts').child(uid).child(postId);
      await ref.delete();
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  // delete profilePic from firebase
  Future<void> deleteProfilePicFromStorage(String uid) async {
    try {
      Reference ref = _storage.ref().child('profilePics').child(uid);
      await ref.delete();
    } on Exception catch (e) {
      print(e.toString());
    }
  }
}
