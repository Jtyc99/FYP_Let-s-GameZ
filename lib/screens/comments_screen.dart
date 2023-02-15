// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/models/user.dart';
import 'package:lets_gamez/providers/user_provider.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/widgets/comment_card.dart';
import 'package:provider/provider.dart';

class CommentsScreen extends StatefulWidget {
  final bool autofocus;
  final String postId;
  final String ownerId;
  final bool? newComment;
  const CommentsScreen({
    Key? key,
    required this.autofocus,
    required this.postId,
    required this.ownerId,
    this.newComment = false,
  }) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: !widget.newComment!
            ? AppBar(
                backgroundColor: mobileBackgroundColor,
                title: const Text('Comment'),
                centerTitle: false,
              )
            : AppBar(
                backgroundColor: mobileBackgroundColor,
                title: const Text('Comment'),
                centerTitle: true,
              ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .orderBy('datePublished')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return ScrollConfiguration(
              behavior: const ScrollBehavior(),
              child: GlowingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                color: primaryColor.withOpacity(0.5),
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) => CommentCard(
                    postId: widget.postId,
                    snap: snapshot.data!.docs[index].data(),
                  ),
                ),
              ),
            );
          },
        ),
        // for user to add comment
        bottomNavigationBar: SafeArea(
          child: Container(
            height: kToolbarHeight,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            padding: const EdgeInsets.only(
              left: 16,
              right: 8,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage(user.photoUrl),
                  radius: 18,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 8,
                    ),
                    child: TextField(
                      autofocus: widget.autofocus,
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Comment as ${user.username} ...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await FirestoreMethods().postComment(
                      widget.postId,
                      widget.ownerId,
                      user.uid,
                      user.photoUrl,
                      user.username,
                      _commentController.text,
                    );
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _commentController.clear();
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
