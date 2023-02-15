// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';

class NotificationCard extends StatefulWidget {
  final snap;
  final int? page;
  final PageController? pageController;
  const NotificationCard({
    Key? key,
    required this.snap,
    this.page,
    this.pageController,
  }) : super(key: key);

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool isLikeAnimating = false;
  String status = 'read';

  void showNotificationDetail() async {
    bool exist = false;
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('posts').get();
    for (int i = 0; i < snapshot.docs.length; i++) {
      // check if post still exists
      if (snapshot.docs[i].data()['postId'] == widget.snap['postId']) {
        exist = true;
        break;
      }
    }
    if (exist) {
      switch (widget.snap['type']) {
        case 'upload':
          routeToSinglePostScreen(
            context,
            widget.snap['postId'],
          );
          break;
        case 'like':
          routeToSinglePostScreen(
            context,
            widget.snap['postId'],
          );
          break;
        case 'like_2':
          routeToCommentScreen(
            context,
            false,
            widget.snap['postId'],
            widget.snap['uid'],
          );
          break;
        case 'comment':
          routeToCommentScreen(
            context,
            false,
            widget.snap['postId'],
            widget.snap['uid'],
          );
          break;
        case 'request':
          if (widget.snap['status'] == 'unread') {
            // ask user to allow or deny request
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                  },
                  child: AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    title: const Text(
                      'Request to download file',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    content: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'You have a request to download ',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryColor,
                            ),
                          ),
                          TextSpan(
                            text: '${widget.snap['filename']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const TextSpan(
                            text: ' from ',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryColor,
                            ),
                          ),
                          TextSpan(
                            text: '@${widget.snap['username']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      Column(
                        children: [
                          const Divider(
                            color: secondaryColor,
                          ),
                          // give permission
                          InkWell(
                            onTap: () async {
                              await FirestoreMethods().addPermission(
                                widget.snap['postId'],
                                widget.snap['requestId'],
                              );
                              await FirestoreMethods().readNotification(
                                widget.snap['uid'],
                                widget.snap['notificationId'],
                                'allowed',
                              );
                              Navigator.of(context).pop();

                              DocumentSnapshot snap = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(widget.snap['uid'])
                                  .get();
                              String profilePic =
                                  (snap.data()! as dynamic)['photoUrl'];
                              String username =
                                  (snap.data()! as dynamic)['username'];
                              await FirestoreMethods().sendNotification(
                                widget.snap['requestId'],
                                widget.snap['postId'],
                                widget.snap['uid'],
                                profilePic,
                                username,
                                '',
                                'allow',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: const Text(
                                'Allow',
                                style: TextStyle(
                                  color: successColor,
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            color: secondaryColor,
                          ),
                          // give permission
                          InkWell(
                            onTap: () async {
                              await FirestoreMethods().readNotification(
                                widget.snap['uid'],
                                widget.snap['notificationId'],
                                'unread',
                              );
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            color: secondaryColor,
                          ),
                          // deny permission
                          InkWell(
                            onTap: () async {
                              await FirestoreMethods().readNotification(
                                widget.snap['uid'],
                                widget.snap['notificationId'],
                                'denied',
                              );
                              Navigator.of(context).pop();

                              DocumentSnapshot snap = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(widget.snap['uid'])
                                  .get();
                              String profilePic =
                                  (snap.data()! as dynamic)['photoUrl'];
                              String username =
                                  (snap.data()! as dynamic)['username'];
                              await FirestoreMethods().sendNotification(
                                widget.snap['requestId'],
                                widget.snap['postId'],
                                widget.snap['uid'],
                                profilePic,
                                username,
                                '',
                                'deny',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: const Text(
                                'Deny',
                                style: TextStyle(
                                  color: failColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
          break;
        case 'allow':
          routeToSinglePostScreen(
            context,
            widget.snap['postId'],
          );
          break;
        case 'deny':
          routeToSinglePostScreen(
            context,
            widget.snap['postId'],
          );
          break;
      }
      await FirestoreMethods().readNotification(
        widget.snap['uid'],
        widget.snap['notificationId'],
        status,
      );
    } else {
      showSnackBar(context, 'Post not found 😭', failColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateTime =
        transformDatePublished(widget.snap['datePublished'].toDate());

    return InkWell(
      onTap: showNotificationDetail,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
          children: [
            widget.snap['status'] == 'unread'
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Badge(
                      badgeColor: Colors.red,
                      animationType: BadgeAnimationType.slide,
                    ),
                  )
                : const SizedBox.shrink(),
            CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(widget.snap['profilePic']),
              radius: 18,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          widget.snap['type'] == 'upload'
                              ? const TextSpan(
                                  text: 'Check out ',
                                  style: TextStyle(
                                    color: primaryColor,
                                  ),
                                )
                              : const TextSpan(
                                  text: '',
                                ),
                          TextSpan(
                            text: widget.snap['username'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          TextSpan(
                            text: ' ${widget.snap['detail']}',
                            style: const TextStyle(
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateTime,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            widget.snap['type'] != 'request'
                ? widget.snap['status'] == 'unread'
                    ? TextButton(
                        onPressed: () async {
                          await FirestoreMethods().readNotification(
                            widget.snap['uid'],
                            widget.snap['notificationId'],
                            'read',
                          );
                        },
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(
                            fontSize: 12,
                            color: blueColor,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.double,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
