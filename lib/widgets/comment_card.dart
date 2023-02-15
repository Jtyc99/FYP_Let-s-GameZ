// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/models/user.dart' as model;
import 'package:lets_gamez/providers/user_provider.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:lets_gamez/widgets/like_animation.dart';
import 'package:provider/provider.dart';

class CommentCard extends StatefulWidget {
  final String postId;
  final snap;
  const CommentCard({Key? key, required this.postId, required this.snap})
      : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool isLikeAnimating = false;

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;
    String dateTime =
        transformDatePublished(widget.snap['datePublished'].toDate());

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                widget.snap['uid'] != FirebaseAuth.instance.currentUser!.uid
                    ? routeToProfile(context, widget.snap['uid'])
                    : null,
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(widget.snap['profilePic']),
              radius: 18,
            ),
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
                        TextSpan(
                          text: widget.snap['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: '   ${widget.snap['text']}',
                          style: const TextStyle(
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          dateTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        widget.snap['likes'].length >= 1
                            ? widget.snap['likes'].length == 1
                                ? Text(
                                    '${widget.snap['likes'].length} like',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: secondaryColor,
                                    ),
                                  )
                                : Text(
                                    '${widget.snap['likes'].length} likes',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: secondaryColor,
                                    ),
                                  )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: LikeAnimation(
              isAnimating: widget.snap['likes'].contains(user.uid),
              smallLike: true,
              child: IconButton(
                onPressed: () async {
                  await FirestoreMethods().likeComment(
                    widget.postId,
                    widget.snap['commentId'],
                    user.uid,
                    user.photoUrl,
                    user.username,
                    widget.snap['likes'],
                  );
                },
                icon: widget.snap['likes'].contains(user.uid)
                    ? const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 16,
                      )
                    : const Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
