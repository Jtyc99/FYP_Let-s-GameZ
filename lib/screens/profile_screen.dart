// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/main.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/global_variables.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:lets_gamez/widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isCurrentUser = true;
  var userData = {};
  bool notificationOn = false;
  int postLen = 0;
  int subscribers = 0;
  int subscribing = 0;
  bool isSubscribing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser!.uid != widget.uid) {
      isCurrentUser = false;
    } else {
      isCurrentUser = true;
    }
    getData();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      userData = userSnap.data()!;
      subscribers = userSnap.data()!['subscribers'].length;
      subscribing = userSnap.data()!['subscribing'].length;

      isSubscribing = userSnap
          .data()!['subscribers']
          .contains(FirebaseAuth.instance.currentUser!.uid);

      // get post length
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();
      postLen = postSnap.docs.length;
      setState(() {});
    } catch (e) {
      showSnackBar(context, e.toString(), failColor);
    }
    setState(() {
      isLoading = false;
      notificationOn =
          userData['notify'].contains(FirebaseAuth.instance.currentUser!.uid);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            // refresh screen on pull (mainly for subsribers and subscribing)
            onRefresh: getData,
            child: SizedBox(
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: mobileBackgroundColor,
                  title: Text(
                    userData['username'],
                  ),
                  centerTitle: isCurrentUser ? false : true,
                  actions: !isCurrentUser
                      ? [
                          // notify current user when new post is uploaded
                          IconButton(
                            onPressed: () async {
                              String res =
                                  await FirestoreMethods().updateNotify(
                                userData['uid'],
                                FirebaseAuth.instance.currentUser!.uid,
                              );
                              var userSnap = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.uid)
                                  .get();
                              setState(() {
                                notificationOn = userSnap
                                    .data()!['notify']
                                    .contains(
                                        FirebaseAuth.instance.currentUser!.uid);
                              });
                              if (res == 'success') {
                                if (notificationOn) {
                                  showSnackBar(
                                      context,
                                      'You have successfully turned on notification for new posts from this user',
                                      successColor);
                                } else {
                                  showSnackBar(
                                      context,
                                      'You have successfully turned off notification for new posts from this user',
                                      successColor);
                                }
                              } else {
                                showSnackBar(context, res, failColor);
                              }
                            },
                            icon: notificationOn
                                ? const Icon(Icons.notifications_active_rounded)
                                : const Icon(Icons.notifications_none_rounded),
                          ),
                        ]
                      : MediaQuery.of(context).size.width <= webScreenSize
                          ? [
                              // switch mode
                              IconButton(
                                onPressed: () {
                                  if (getAutoReload()) {
                                    // if current mode is auto-reload, set to normal mode
                                    setAutoReload(false);
                                    setMode('NORMAL');
                                  } else {
                                    // if current mode is normal, set to auto-reload mode
                                    setAutoReload(true);
                                    setMode('AUTO-RELOAD');
                                  }
                                  routeToMyApp(context);
                                  showSnackBar(
                                      context,
                                      'Successfully switched to ${getMode()} mode',
                                      successColor);
                                },
                                icon: const Icon(Icons.settings_rounded),
                                tooltip: 'Switch mode',
                              ),
                              IconButton(
                                onPressed: () => showSignOutAlertBox(context),
                                icon: const Icon(Icons.logout_rounded),
                              ),
                            ]
                          : [],
                ),
                body: ScrollConfiguration(
                  behavior: const ScrollBehavior(),
                  child: GlowingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    color: secondaryColor.withOpacity(0.5),
                    child: ListView(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: MediaQuery.of(context).size.width >
                                      webScreenSize
                                  ? MediaQuery.of(context).size.width * 0.02
                                  : MediaQuery.of(context).size.width * 0.05),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    backgroundImage: NetworkImage(
                                      userData['photoUrl'],
                                    ),
                                    radius: 40,
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width >
                                            webScreenSize
                                        ? MediaQuery.of(context).size.width *
                                            0.05
                                        : MediaQuery.of(context).size.width *
                                            0.05,
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            buildStateColumn(postLen, 'posts'),
                                            buildStateColumn(
                                                subscribers, 'subscribers'),
                                            buildStateColumn(
                                                subscribing, 'subscribing'),
                                          ],
                                        ),
                                        kIsWeb
                                            ? const SizedBox(
                                                height: 10,
                                              )
                                            : const SizedBox.shrink(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            FirebaseAuth.instance.currentUser!
                                                        .uid ==
                                                    widget.uid
                                                ? CustomButton(
                                                    function: () =>
                                                        routeToEditProfileScreen(
                                                            context),
                                                    backgroundColor:
                                                        mobileBackgroundColor,
                                                    borderColor: secondaryColor,
                                                    text: 'Edit Profile',
                                                    textColor: primaryColor,
                                                  )
                                                : isSubscribing
                                                    ? CustomButton(
                                                        function: () async {
                                                          await FirestoreMethods()
                                                              .subscribeUser(
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser!
                                                                      .uid,
                                                                  userData[
                                                                      'uid']);
                                                          setState(() {
                                                            isSubscribing =
                                                                false;
                                                            subscribers--;
                                                          });
                                                        },
                                                        backgroundColor:
                                                            secondaryColor,
                                                        borderColor:
                                                            secondaryColor,
                                                        text: 'Unsubscribe',
                                                        textColor: primaryColor,
                                                      )
                                                    : CustomButton(
                                                        function: () async {
                                                          await FirestoreMethods()
                                                              .subscribeUser(
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser!
                                                                      .uid,
                                                                  userData[
                                                                      'uid']);
                                                          setState(() {
                                                            isSubscribing =
                                                                true;
                                                            subscribers++;
                                                          });
                                                        },
                                                        backgroundColor:
                                                            blueColor,
                                                        borderColor: blueColor,
                                                        text: 'Subscribe',
                                                        textColor: primaryColor,
                                                      ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  userData['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  userData['bio'],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: secondaryColor,
                          thickness: 0.3,
                        ),
                        FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('posts')
                              .where('uid', isEqualTo: widget.uid)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if ((snapshot.data! as dynamic).docs.length == 0) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: SizedBox(
                                  height: 300,
                                  child: Column(
                                    children: [
                                      Flexible(flex: 2, child: Container()),
                                      Container(
                                        alignment: Alignment.topCenter,
                                        child: const Text(
                                          'No post yet 😭',
                                          style: TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      Flexible(flex: 2, child: Container()),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: GridView.builder(
                                scrollDirection: Axis.vertical,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount:
                                    (snapshot.data! as dynamic).docs.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 5,
                                  childAspectRatio: 1,
                                ),
                                itemBuilder: (context, index) {
                                  DocumentSnapshot snap =
                                      (snapshot.data! as dynamic).docs[index];

                                  return InkWell(
                                    onTap: () => routeToSinglePostScreen(
                                      context,
                                      snap['postId'],
                                    ),
                                    child: Container(
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
                                          snap['filename'],
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  // for number of posts, subsribers and subscribing
  Column buildStateColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
