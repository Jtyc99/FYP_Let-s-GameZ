import 'package:flutter/material.dart';
import 'package:lets_gamez/main.dart';
import 'package:lets_gamez/responsive/mobile_screen_layout.dart';
import 'package:lets_gamez/responsive/responsive_layout_screen.dart';
import 'package:lets_gamez/responsive/web_screen_layout.dart';
import 'package:lets_gamez/screens/comments_screen.dart';
import 'package:lets_gamez/screens/edit_post_screen.dart';
import 'package:lets_gamez/screens/edit_profile_screen.dart';
import 'package:lets_gamez/screens/feed_screen.dart';
import 'package:lets_gamez/screens/profile_screen.dart';
import 'package:lets_gamez/utils/global_variables.dart';
import 'package:lets_gamez/utils/utils.dart';

void routeToMyApp(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ResponsiveLayout(
          webScreenLayout: WebScreenLayout(
            autoReload: autoReload,
          ),
          mobileScreenLayout: MobileScreenLayout(
            autoReload: autoReload,
          ),
        ),
      ),
      (route) => false);
}

void routeToProfile(
  BuildContext context,
  String uid,
) {
  if (MediaQuery.of(context).size.width >= webScreenSize) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => scaffold(
          context,
          null,
          null,
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ProfileScreen(
                uid: uid,
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          uid: uid,
        ),
      ),
    );
  }
}

void routeToSinglePostScreen(
  BuildContext context,
  String postId,
) {
  if (MediaQuery.of(context).size.width >= webScreenSize) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => scaffold(
          context,
          null,
          null,
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              FeedScreen(
                postId: postId,
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeedScreen(
          postId: postId,
        ),
      ),
    );
  }
}

void routeToCommentScreen(
  BuildContext context,
  bool autofocus,
  String postId,
  String ownerId,
) {
  if (MediaQuery.of(context).size.width >= webScreenSize) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => scaffold(
          context,
          null,
          null,
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              CommentsScreen(
                autofocus: autofocus,
                postId: postId,
                ownerId: ownerId,
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          autofocus: autofocus,
          postId: postId,
          ownerId: ownerId,
        ),
      ),
    );
  }
}

void routeToEditPostScreen(
  BuildContext context,
  String postId,
) {
  if (MediaQuery.of(context).size.width >= webScreenSize) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => scaffold(
          context,
          null,
          null,
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              EditPostScreen(
                postId: postId,
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          postId: postId,
        ),
      ),
    );
  }
}

void routeToEditProfileScreen(
  BuildContext context,
) {
  if (MediaQuery.of(context).size.width >= webScreenSize) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => scaffold(
          context,
          null,
          null,
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              EditProfileScreen(),
            ],
          ),
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: ((context) => const EditProfileScreen()),
      ),
    );
  }
}
