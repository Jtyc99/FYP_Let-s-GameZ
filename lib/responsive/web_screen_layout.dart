import 'package:auto_reload/auto_reload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/screens/add_post_screen.dart';
import 'package:lets_gamez/screens/feed_screen.dart';
import 'package:lets_gamez/screens/profile_screen.dart';
import 'package:lets_gamez/screens/search_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';

class WebScreenLayout extends StatefulWidget {
  final bool autoReload;
  final int page;
  const WebScreenLayout({
    Key? key,
    required this.autoReload,
    this.page = 0,
  }) : super(key: key);

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

/* // original
class _MobileScreenLayoutState extends State<MobileScreenLayout> { */

// for auto reload
abstract class _AutoReloadState extends State<WebScreenLayout>
    implements AutoReloader {}

class _WebScreenLayoutState extends _AutoReloadState with AutoReloadMixin {
  @override
  // ignore: overridden_fields
  final Duration autoReloadDuration = const Duration(milliseconds: 500);

  int _page = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    if (widget.autoReload) {
      // for auto reload
      startAutoReload();
    }
    pageController = PageController();
    getData();
  }

  void getData() async {
    await FirestoreMethods()
        .updateUnreadNotifications(FirebaseAuth.instance.currentUser!.uid);
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.autoReload) {
      // for auto reload
      cancelAutoReload();
    }
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
      if (kIsWeb) {
        if (_page == 2) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  title: const Text(
                    'Currently this function is not supported on web yet 😭',
                    style: TextStyle(
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  actions: <Widget>[
                    Column(
                      children: [
                        const Divider(
                          color: secondaryColor,
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: const Text(
                              'I understand and wish to proceed',
                              style: TextStyle(
                                color: failColor,
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          color: secondaryColor,
                        ),
                        InkWell(
                          onTap: () => routeToMyApp(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: const Text(
                              'Back to Feed',
                              style: TextStyle(
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              });
        }
      }
      if (widget.autoReload) {
        // for auto reload
        if (_page == 3) {
          cancelAutoReload();
        } else {
          startAutoReload();
        }
      }
    });
  }

  // for auto reload
  @override
  void autoReload() {
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return scaffold(
      context,
      _page,
      pageController,
      PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          const FeedScreen(),
          const SearchScreen(),
          const AddPostScreen(),
          ProfileScreen(
            uid: FirebaseAuth.instance.currentUser!.uid,
          ),
        ],
      ),
    );
  }
}
