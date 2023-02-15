import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  final String? postId;
  final bool? newPost;
  const FeedScreen({
    Key? key,
    this.postId = '',
    this.newPost = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !newPost!
          ? AppBar(
              backgroundColor: mobileBackgroundColor,
              centerTitle: false,
              title: const Text('Feed'),
              shape: Border(
                bottom: BorderSide(color: secondaryColor.withOpacity(0.4)),
              ),
            )
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              centerTitle: true,
              title: const Text('Feed'),
              shape: Border(
                bottom: BorderSide(color: secondaryColor.withOpacity(0.4)),
              ),
            ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // for single post
          if (postId!.isNotEmpty) {
            int selected = 0;
            for (int i = 0; i < snapshot.data!.docs.length; i++) {
              if (snapshot.data!.docs[i].data()['postId'] == postId) {
                selected = i;
                break;
              }
            }
            // return single post
            return PostCard(
              snap: snapshot.data!.docs[selected].data(),
            );
          }

          // for all posts in feed screen
          return ScrollConfiguration(
            behavior: const ScrollBehavior(),
            child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: secondaryColor.withOpacity(0.5),
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) => PostCard(
                  snap: snapshot.data!.docs[index].data(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
