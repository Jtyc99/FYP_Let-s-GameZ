// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'package:auto_reload/auto_reload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animator/flutter_animator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lets_gamez/main.dart';
import 'package:lets_gamez/models/user.dart' as model;
import 'package:lets_gamez/providers/user_provider.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:lets_gamez/widgets/like_animation.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

// for auto reload
abstract class _AutoReloadState extends State<PostCard>
    implements AutoReloader {}

class _PostCardState extends _AutoReloadState with AutoReloadMixin {
  @override
  // ignore: overridden_fields
  final Duration autoReloadDuration = const Duration(seconds: 5);

  bool isLikeAnimating = false;
  int commentLength = 0;
  bool isDownloading = false;

  @override
  void initState() {
    getComments();
    super.initState();
    if (getAutoReload()) {
      // for auto reload
      startAutoReload();
    }
  }

  Future<void> _displayDialogBox(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        content: Builder(builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  routeToEditPostScreen(context, widget.snap['postId']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const Divider(
                color: secondaryColor,
              ),
              InkWell(
                onTap: () async {
                  FirestoreMethods().deletePost(
                    widget.snap['uid'],
                    widget.snap['postId'],
                  );
                  routeToMyApp(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14,
                      color: failColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void downloadFile() async {
    setState(() {
      isDownloading = true;
    });
    try {
      List<String> res = await FirestoreMethods().downloadPost(
          widget.snap['uid'], widget.snap['postId'], widget.snap['filename']);
      if (res[0] == 'success') {
        setState(() {
          isDownloading = false;
        });
        showSnackBar(context, 'Successfully downloaded !', successColor);
      } else {
        setState(() {
          isDownloading = false;
        });
        showSnackBar(context, res[0], failColor);
        print(res[0]);
      }
    } on Exception catch (e) {
      showSnackBar(context, e.toString(), failColor);
    }
  }

  void requestDownload(String postId) async {
    var userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    var userData = userSnap.data()!;

    final GlobalKey<AnimatorWidgetState> basicAnimation =
        GlobalKey<AnimatorWidgetState>();

    // check if status of request if request exists
    String status = '';
    QuerySnapshot<Map<String, dynamic>> snaps = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.snap['uid'])
        .collection('notifications')
        .get();
    for (int i = 0; i < snaps.docs.length; i++) {
      if (snaps.docs[i].data()['postId'] == postId &&
          snaps.docs[i].data()['requestId'] == userData['uid'] &&
          snaps.docs[i].data()['type'] == 'request') {
        status = snaps.docs[i].data()['status'];
        break;
      }
    }

    // ask user to ask permission from post owner
    Widget toast = Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        color: secondaryColor,
      ),
      child: status != 'unread'
          ? status == 'denied'
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: Text('Your request has been denied'),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ask permission to download file?'),
                    Bounce(
                      key: basicAnimation,
                      child: IconButton(
                        icon: const Icon(
                          Icons.check_box_rounded,
                          color: Colors.greenAccent,
                        ),
                        onPressed: () async {
                          FToast().init(context).removeCustomToast();
                          try {
                            String res =
                                await FirestoreMethods().sendNotification(
                              widget.snap['uid'],
                              widget.snap['postId'],
                              userData['uid'],
                              userData['photoUrl'],
                              userData['username'],
                              widget.snap['filename'],
                              'request',
                            );

                            if (res == 'success') {
                              showSnackBar(context, 'Successfully requested !',
                                  successColor);
                            } else {
                              showSnackBar(context, res, failColor);
                            }
                          } catch (e) {
                            showSnackBar(context, e.toString(), failColor);
                          }
                        },
                      ),
                    ),
                  ],
                )
          : const Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: Text('Your request is still pending'),
            ),
    );
    // remove current toast message
    FToast().init(context).removeCustomToast();
    FToast().init(context).showToast(
          child: toast,
          toastDuration: const Duration(seconds: 5),
        );
  }

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLength = snap.docs.length;
      setStateIfMounted();
    } catch (e) {
      print(e.toString());
    }
  }

  void setStateIfMounted() {
    if (mounted) setState(() {});
  }

  // for auto reload
  @override
  void dispose() {
    super.dispose();
    if (getAutoReload()) {
      cancelAutoReload();
    }
  }

  // for auto reload
  @override
  void autoReload() {
    getComments();
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;
    String dateTime =
        transformDatePublished(widget.snap['datePublished'].toDate());

    bool isAuthorized = widget.snap['authorizedUserIds']
        .contains(FirebaseAuth.instance.currentUser!.uid);

    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Column(
        children: [
          // header section
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => widget.snap['uid'] !=
                          FirebaseAuth.instance.currentUser!.uid
                      ? routeToProfile(context, widget.snap['uid'])
                      : null,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage(
                      widget.snap['profImage'],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.snap['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FirebaseAuth.instance.currentUser!.uid == widget.snap['uid']
                    ? IconButton(
                        onPressed: () => _displayDialogBox(context),
                        icon: const Icon(Icons.more_vert_rounded),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onDoubleTap: () async {
              await FirestoreMethods().likePost(
                user.uid,
                user.photoUrl,
                user.username,
                widget.snap['postId'],
                widget.snap['uid'],
                widget.snap['likes'],
              );
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 80,
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(20),
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    color: secondaryColor,
                  ),
                  child: Center(
                    child: Text(
                      widget.snap['filename'],
                      maxLines: 2,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 0.45 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          // show linear progress indicator when downloading
          isDownloading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
          // like, comment, share, download section
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user.uid),
                smallLike: true,
                child: IconButton(
                  onPressed: () async {
                    await FirestoreMethods().likePost(
                      user.uid,
                      user.photoUrl,
                      user.username,
                      widget.snap['postId'],
                      widget.snap['uid'],
                      widget.snap['likes'],
                    );
                  },
                  icon: widget.snap['likes'].contains(user.uid)
                      ? const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                        )
                      : const Icon(
                          Icons.favorite_border_rounded,
                        ),
                ),
              ),
              IconButton(
                onPressed: () => routeToCommentScreen(
                  context,
                  true,
                  widget.snap['postId'],
                  widget.snap['uid'],
                ),
                icon: const Icon(
                  Icons.comment_outlined,
                ),
              ),
              FirebaseAuth.instance.currentUser!.uid != widget.snap['uid']
                  ? Expanded(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          onPressed: isAuthorized
                              ? !kIsWeb
                                  // if authorized, download file if using android
                                  ? () => downloadFile()
                                  // show error if using web
                                  : () => showSnackBar(
                                      context,
                                      'Currently this function is not supported on web yet 😭',
                                      failColor)
                              : // else ask user whether request to be authorized or not
                              () => requestDownload(widget.snap['postId']),
                          icon: const Icon(
                            Icons.file_download_rounded,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          // description and number of comments section
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  child: widget.snap['likes'].length > 0
                      ? widget.snap['likes'].length > 1
                          ? Text(
                              '${widget.snap['likes'].length} likes',
                              style: Theme.of(context).textTheme.bodyText2,
                            )
                          : Text(
                              '${widget.snap['likes'].length} like',
                              style: Theme.of(context).textTheme.bodyText2,
                            )
                      : const SizedBox.shrink(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 8,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: primaryColor,
                      ),
                      children: [
                        TextSpan(
                          text: widget.snap['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '   ${widget.snap['description']}',
                        ),
                      ],
                    ),
                  ),
                ),
                commentLength != 0
                    ? InkWell(
                        onTap: () => routeToCommentScreen(
                          context,
                          false,
                          widget.snap['postId'],
                          widget.snap['uid'],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            commentLength == 1
                                ? 'View all $commentLength comment'
                                : 'View all $commentLength comments',
                            style: const TextStyle(
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox.shrink(),
                      ),
                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    dateTime,
                    style: const TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
