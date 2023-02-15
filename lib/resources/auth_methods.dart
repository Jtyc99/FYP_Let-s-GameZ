// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/models/user.dart' as model;
import 'package:lets_gamez/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  // sign up user
  Future<String> signUpUser({
    required String username,
    required String email,
    required String phone,
    required String bio,
    required String password,
    required Uint8List file,
  }) async {
    String res = 'error';
    try {
      if (RegExp(r'(^[0]{1}[1]{1}[1]{1}[0-9]{8}$)').hasMatch(phone) ||
          RegExp(r'(^[0]{1}[1]{1}[0-9]{1}[0-9]{7}$)').hasMatch(phone)) {
        // register user
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        List photoDetails = await StorageMethods()
            .uploadFileToStorage('profilePics', file, false);

        // add user to firebase
        model.User _user = model.User(
          uid: cred.user!.uid,
          username: username,
          email: email,
          phone: phone,
          bio: bio,
          password: password,
          photoUrl: photoDetails[1],
          subscribers: [],
          subscribing: [],
          postIds: [],
          commentIds: [],
          unreadNotifications: 0,
          notify: [],
        );
        await _firestore.collection('users').doc(cred.user!.uid).set(
              _user.toJson(),
            );
        res = 'success';
      } else {
        res = 'Invalid phone, e.g. 01xxxxxxxx';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'unknown') {
        res = 'Required field(s)';
      } else if (e.code == 'email-already-in-use') {
        res = 'This email is already registered';
      } else if (e.code == 'invalid-email') {
        res = 'Invalid email, e.g. xxx@xxxx.xxx';
      } else if (e.code == 'weak-password') {
        res = 'Weak password';
      } else {
        res = e.toString();
      }
    }
    return res;
  }

  // login user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = 'error';
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      res = 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'unknown') {
        res = 'Required field(s)';
      } else if (e.code == 'user-not-found') {
        res = 'User not found';
      } else if (e.code == 'wrong-password') {
        res = 'Wrong password';
      } else {
        res = e.toString();
      }
    }
    return res;
  }

  // logout user
  Future<void> logoutUser() async {
    await _auth.signOut();
    _auth.idTokenChanges().listen((User? user) {
      if (user == null) {
        debugPrint('User is currently signed out!');
      } else {
        debugPrint('User is signed in!');
      }
    });
  }
}
