import 'package:auto_reload/auto_reload.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/screens/add_post_screen.dart';
import 'package:lets_gamez/screens/feed_screen.dart';
import 'package:lets_gamez/screens/notification_screen.dart';
import 'package:lets_gamez/screens/profile_screen.dart';
import 'package:lets_gamez/screens/search_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';

class MobileScreenLayout extends StatefulWidget {
  final bool autoReload;
  const MobileScreenLayout({
    Key? key,
    required this.autoReload,
  }) : super(key: key);

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

/* // original
class _MobileScreenLayoutState extends State<MobileScreenLayout> { */

// for auto reload
abstract class _AutoReloadState extends State<MobileScreenLayout>
    implements AutoReloader {}

class _MobileScreenLayoutState extends _AutoReloadState with AutoReloadMixin {
  @override
  // ignore: overridden_fields
  final Duration autoReloadDuration = const Duration(milliseconds: 500);

  int num = 0;

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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      setState(() {
        num = value.data()!['unreadNotifications'];
      });
    });
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

  // navigate to different pages
  void navigationTapped(int page) {
    pageController.jumpToPage(page);
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
        if (_page == 3 || _page == 4) {
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
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          const FeedScreen(),
          const SearchScreen(),
          const AddPostScreen(),
          NotificationScreen(
            uid: FirebaseAuth.instance.currentUser!.uid,
          ),
          ProfileScreen(
            uid: FirebaseAuth.instance.currentUser!.uid,
          ),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: mobileBackgroundColor,
        items: [
          // home page
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_rounded,
              color: _page == 0 ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          // search page
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search_rounded,
              color: _page == 1 ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          // add post page
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_rounded,
              color: _page == 2 ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          // notification page
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_rounded,
                  color: _page == 3 ? primaryColor : secondaryColor,
                ),
                // show notification badge for unread notifications
                num != 0
                    ? Positioned(
                        right: 0,
                        child: Badge(
                          badgeColor: Colors.red,
                          animationType: BadgeAnimationType.slide,
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          // profile page
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_rounded,
              color: _page == 4 ? primaryColor : secondaryColor,
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
        ],
        onTap: navigationTapped,
      ),
    );
  }
}
