// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/models/user.dart' as model;
import 'package:lets_gamez/providers/user_provider.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/global_variables.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:provider/provider.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  const EditPostScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List _customUserUids = [];
  final List<String> _customUserUsernames = [];
  final List oldauthorizedUserIds = [];
  final List authorizedUserIds = [];

  var postData = {};
  bool _subscribers = false;
  bool _subscribing = false;
  bool isEdited = false;
  bool isLoading = false;
  bool isEditing = false;

  // for custom user list alert dialog box
  Future<void> _displayAlertDialogBox(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              backgroundColor: secondaryColor,
              content: SizedBox(
                width: !kIsWeb
                    ? MediaQuery.of(context).size.width * 0.8
                    : MediaQuery.of(context).size.width / 3,
                height: MediaQuery.of(context).size.height * 0.58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // enter username
                    TextFormField(
                      controller: searchController,
                      decoration:
                          const InputDecoration(hintText: 'Search for a user'),
                    ),
                    // show users
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Text('Suggestion:'),
                    ),
                    SizedBox(
                      height: 190,
                      child: FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .where(
                              'username',
                              isGreaterThanOrEqualTo: searchController.text,
                            )
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return ScrollConfiguration(
                            behavior: const ScrollBehavior(),
                            child: GlowingOverscrollIndicator(
                              axisDirection: AxisDirection.down,
                              color: secondaryColor.withOpacity(0.5),
                              child: ListView.builder(
                                itemCount:
                                    (snapshot.data! as dynamic).docs.length,
                                itemBuilder: (context, index) {
                                  String uid = (snapshot.data! as dynamic)
                                      .docs[index]['uid'];
                                  String username = (snapshot.data! as dynamic)
                                      .docs[index]['username'];
                                  // dont display current user
                                  if (uid !=
                                      FirebaseAuth.instance.currentUser!.uid) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: primaryColor,
                                        backgroundImage: NetworkImage(
                                            (snapshot.data! as dynamic)
                                                .docs[index]['photoUrl']),
                                      ),
                                      title: Text(
                                        (snapshot.data! as dynamic).docs[index]
                                            ['username'],
                                      ),
                                      onTap: () {
                                        _customizeUserList(uid, username);
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _customizeUserList(String uid, String username) {
    // add user uid to selected list
    setState(() {
      if (!_customUserUids.contains(uid)) {
        _customUserUids.add(uid);
        _customUserUsernames.add(username);
      } else {
        showSnackBar(context, 'User has been added', successColor);
      }
    });
  }

  void editPost() async {
    setState(() {
      isEditing = true;
    });
    try {
      // add custom user list to authorized user list
      for (int i = 0; i < _customUserUids.length; i++) {
        if (!authorizedUserIds.contains(_customUserUids[i])) {
          authorizedUserIds.add(_customUserUids[i]);
        }
      }

      String res = await FirestoreMethods().editPost(
        widget.postId,
        authorizedUserIds,
        descriptionController.text,
      );

      if (res == 'success') {
        setState(() {
          isEditing = false;
        });
        showSnackBar(context, 'Successfully edited !', successColor);
      } else {
        setState(() {
          isEditing = false;
        });
        showSnackBar(context, res, failColor);
      }
    } catch (e) {
      showSnackBar(context, e.toString(), failColor);
    }
    routeToMyApp(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
      postData = postSnap.data()!;
      setState(() {
        descriptionController.text = postData['description'];

        // check if description is edited
        descriptionController.addListener(() {
          if (descriptionController.text != postData['description']) {
            isEdited = true;
          } else {
            isEdited = false;
          }
        });
        oldauthorizedUserIds.addAll(postData['authorizedUserIds']);
      });
      // add authorized usernames into custom users usernames
      int count = oldauthorizedUserIds.length;
      int i = 0;
      while (i < count) {
        var userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(oldauthorizedUserIds[i])
            .get();
        setState(() {
          _customizeUserList(oldauthorizedUserIds[i], userSnap['username']);
        });
        i++;
      }
    } catch (e) {
      showSnackBar(context, e.toString(), failColor);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    searchController.dispose();
    descriptionController.dispose();
  }

  void _handleTabSelection() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: isEdited
                ? () {
                    showDiscardAlertBox(context, 'changes');
                  }
                : () {
                    routeToMyApp(context);
                  },
          ),
          title: const Text('Edit Post'),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(flex: 2, child: Container()),
            // tab bar for options & description
            Theme(
              data: ThemeData(hintColor: secondaryColor),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(50), // Creates border
                    color: secondaryColor),
                isScrollable: true,
                labelColor: primaryColor,
                unselectedLabelColor: secondaryColor,
                tabs: [
                  // for 1st tab _tabController.index == 0
                  SizedBox(
                    height: 24,
                    width: 90,
                    child: Tab(
                      child: Center(
                        child: Text(
                          'Options',
                          style: TextStyle(
                            color: _tabController.index == 0
                                ? primaryColor
                                : secondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // for second tab _tabController.index == 1
                  SizedBox(
                    height: 24,
                    width: 90,
                    child: Tab(
                      child: Center(
                        child: Text(
                          'Description',
                          style: TextStyle(
                            color: _tabController.index == 0
                                ? secondaryColor
                                : primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // display for corresponding tab
            ScrollConfiguration(
              behavior: const ScrollBehavior(),
              child: GlowingOverscrollIndicator(
                axisDirection: AxisDirection.right,
                color: secondaryColor.withOpacity(0.5),
                child: Container(
                  height: 180,
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(6),
                      ),
                    ),
                    color: mobileBackgroundColor,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // options page
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Authorized user(s)'),
                          const Divider(
                            indent: 6,
                            endIndent: 6,
                            color: primaryColor,
                            thickness: 0.8,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  height: 120,
                                  width: MediaQuery.of(context).size.width >=
                                          webScreenSize
                                      ? (MediaQuery.of(context).size.width *
                                              0.14) -
                                          24
                                      : MediaQuery.of(context).size.width *
                                          0.42,
                                  child:
                                      // checkboxes
                                      Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: 0.8,
                                            child: Checkbox(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: const CircleBorder(),
                                              value: _subscribers,
                                              onChanged: (value) {
                                                setState(() {
                                                  _subscribers = value!;

                                                  // add subscribers to authorized user list
                                                  authorizedUserIds
                                                      .addAll(user.subscribers);
                                                });
                                              },
                                            ),
                                          ),
                                          const Text('Subscribers'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: 0.8,
                                            child: Checkbox(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: const CircleBorder(),
                                              value: _subscribing,
                                              onChanged: (value) {
                                                setState(() {
                                                  _subscribing = value!;

                                                  // add subscribing to authorized user list
                                                  authorizedUserIds
                                                      .addAll(user.subscribing);
                                                });
                                              },
                                            ),
                                          ),
                                          const Text('Subscribing'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const VerticalDivider(
                                  color: secondaryColor,
                                  thickness: 0.4,
                                ),
                                Container(
                                  height: 120,
                                  width: MediaQuery.of(context).size.width >=
                                          webScreenSize
                                      ? (MediaQuery.of(context).size.width *
                                              0.14) -
                                          24
                                      : MediaQuery.of(context).size.width *
                                          0.42,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // button to customized user list
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            searchController.clear();
                                          });
                                          _displayAlertDialogBox(context);
                                        },
                                        child: Container(
                                          height: 30,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          decoration: const ShapeDecoration(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                            ),
                                            color: blueColor,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Customize user list',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // display custom user list
                                      SizedBox(
                                        height: 75,
                                        child: ScrollConfiguration(
                                          behavior: const ScrollBehavior(),
                                          child: GlowingOverscrollIndicator(
                                            axisDirection: AxisDirection.down,
                                            color:
                                                secondaryColor.withOpacity(0.5),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount:
                                                  _customUserUsernames.length,
                                              itemBuilder: ((context, index) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.3,
                                                      child: ListTile(
                                                        dense: true,
                                                        visualDensity:
                                                            const VisualDensity(
                                                          vertical: -4,
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 0,
                                                          horizontal: 0,
                                                        ),
                                                        minVerticalPadding: 0,
                                                        title: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .fromLTRB(
                                                                  10, 2, 0, 0),
                                                          child: Text(
                                                            _customUserUsernames[
                                                                index],
                                                            textScaleFactor:
                                                                1.2,
                                                          ),
                                                        ),
                                                        trailing:
                                                            Transform.scale(
                                                          scale: 0.9,
                                                          child: IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_forever_rounded,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                _customUserUids
                                                                    .removeAt(
                                                                        index);
                                                                _customUserUsernames
                                                                    .removeAt(
                                                                        index);
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                  ],
                                                );
                                              }),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // decription page
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Center(
                          child: TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Write your caption ...',
                              border: InputBorder.none,
                            ),
                            // max length of text input
                            maxLength: 50,
                            // max line shown at once
                            maxLines: 5,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // submit changes button
            InkWell(
              onTap: () async {
                editPost();
              },
              child: Container(
                width: 200,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(4),
                    ),
                  ),
                  color: blueColor,
                ),
                child: isEditing
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
            Flexible(flex: 2, child: Container()),
          ],
        ),
      ),
    );
  }
}
