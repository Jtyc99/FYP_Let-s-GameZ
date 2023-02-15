// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
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

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // for uploaded file
  Uint8List? _file;
  String _fileName = 'Upload file';
  final List _customUserUids = [];
  final List<String> _customUserUsernames = [];
  final List authorizedUserIds = [];

  bool _isReading = false;
  bool _subscribers = false;
  bool _subscribing = false;
  bool _isPosting = false;

  void selectFile() async {
    setState(() {
      _isReading = true;
    });
    // load file details
    FilePickerResult? result = await pickFile();
    setState(() {
      if (result != null) {
        if (kIsWeb) {
          // load file for web
          _file = result.files.first.bytes;
        } else {
          // load file for android emulator
          String? path = result.files.first.path;
          if (path != null) {
            File file = File(path);
            _file = file.readAsBytesSync();
          }
        }
        // load file name
        _fileName = result.files.first.name;
      }
      _isReading = false;
    });
  }

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
        showSnackBar(context, 'User has been added', failColor);
      }
    });
  }

  void postFile(
    String uid,
    String username,
    String profImage,
    String profilePic,
  ) async {
    setState(() {
      _isPosting = true;
    });
    try {
      // add custom user list to authorized user list
      for (int i = 0; i < _customUserUids.length; i++) {
        if (!authorizedUserIds.contains(_customUserUids[i])) {
          authorizedUserIds.add(_customUserUids[i]);
        }
      }

      // upload post
      List<String> res = await FirestoreMethods().uploadPost(
        uid,
        profImage,
        username,
        _fileName,
        _file!,
        authorizedUserIds,
        descriptionController.text,
      );

      setState(() {
        _isPosting = false;
      });

      // send notification about new post to all users who have turned on notification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then((value) {
        List receiverIds = value.data()!['notify'];
        for (int i = 0; i < receiverIds.length; i++) {
          FirestoreMethods().sendNotification(
            receiverIds[i],
            res[1],
            uid,
            profilePic,
            username,
            _fileName,
            'upload',
          );
        }
      });

      if (res[0] == 'success') {
        showSnackBar(context, 'Successfully posted !', successColor);
        routeToMyApp(context);
      } else {
        showSnackBar(context, res[0], failColor);
      }
    } catch (e) {
      showSnackBar(context, e.toString(), Colors.red);
    }
  }

  void sendNotifications(
    List receiverIds,
    String postId,
    String uid,
    String profilePic,
    String username,
    String filename,
    String type,
  ) async {
    while (receiverIds.isNotEmpty) {
      await FirestoreMethods().sendNotification(
        receiverIds[0],
        postId,
        uid,
        profilePic,
        username,
        filename,
        type,
      );
      receiverIds.removeAt(0);
    }
  }

  /* void clearFile() {
    setState(() {
      _fileName = 'Upload file';
      _file = null;
    });
  } */

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
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
          leading: _file != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => showDiscardAlertBox(context, 'post'),
                )
              : null,
          title: const Text('Post to'),
          centerTitle: false,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _file == null
                ? Center(
                    child: Container(
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        color: secondaryColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _file != null
                                  ? const Icon(Icons.done_rounded)
                                  : const Icon(Icons.note_add_rounded),
                              const SizedBox(width: 20),
                              _isReading
                                  ? SizedBox(
                                      width: MediaQuery.of(context)
                                                  .size
                                                  .width >=
                                              webScreenSize
                                          ? MediaQuery.of(context).size.width *
                                              0.14
                                          : MediaQuery.of(context).size.width *
                                              0.41,
                                      child: const LinearProgressIndicator(),
                                    )
                                  : SizedBox(
                                      width: MediaQuery.of(context)
                                                  .size
                                                  .width >=
                                              webScreenSize
                                          ? MediaQuery.of(context).size.width *
                                              0.14
                                          : MediaQuery.of(context).size.width *
                                              0.41,
                                      child: Text(
                                        _fileName,
                                        maxLines: 3,
                                      ),
                                    ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: !_isReading ? selectFile : null,
                            child: Container(
                              width: 100,
                              alignment: Alignment.center,
                              decoration: ShapeDecoration(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                color: !_isReading
                                    ? blueColor
                                    : Colors.grey.shade600,
                              ),
                              child: const Text('Choose file'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ScrollConfiguration(
                    behavior: const ScrollBehavior(),
                    child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.down,
                      color: secondaryColor.withOpacity(0.5),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _isPosting
                                ? const LinearProgressIndicator()
                                : Container(),
                            const SizedBox(height: 24),
                            // load file area
                            Container(
                              height: 80,
                              padding: const EdgeInsets.all(20),
                              decoration: const ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                color: secondaryColor,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      _file != null
                                          ? const Icon(Icons.done_rounded)
                                          : const Icon(Icons.note_add_rounded),
                                      const SizedBox(width: 20),
                                      _isReading
                                          ? SizedBox(
                                              width: MediaQuery.of(context)
                                                          .size
                                                          .width >=
                                                      webScreenSize
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.14
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.41,
                                              child:
                                                  const LinearProgressIndicator(),
                                            )
                                          : SizedBox(
                                              width: MediaQuery.of(context)
                                                          .size
                                                          .width >=
                                                      webScreenSize
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.14
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.41,
                                              child: Text(
                                                _fileName,
                                                maxLines: 3,
                                              ),
                                            ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: !_isReading ? selectFile : null,
                                    child: Container(
                                      width: 100,
                                      alignment: Alignment.center,
                                      decoration: ShapeDecoration(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        color: !_isReading
                                            ? blueColor
                                            : Colors.grey.shade600,
                                      ),
                                      child: const Text('Choose file'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            // tab bar for options & description
                            Theme(
                              data: ThemeData(hintColor: secondaryColor),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        50), // Creates border
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                SizedBox(
                                                  height: 120,
                                                  width: MediaQuery.of(context)
                                                              .size
                                                              .width >=
                                                          webScreenSize
                                                      ? (MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.14) -
                                                          24
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.42,
                                                  child:
                                                      // checkboxes
                                                      Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Transform.scale(
                                                            scale: 0.8,
                                                            child: Checkbox(
                                                              materialTapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap,
                                                              shape:
                                                                  const CircleBorder(),
                                                              value:
                                                                  _subscribers,
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _subscribers =
                                                                      value!;

                                                                  // add subscribers to authorized user list
                                                                  authorizedUserIds
                                                                      .addAll(user
                                                                          .subscribers);
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const Text(
                                                              'Subscribers'),
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
                                                              shape:
                                                                  const CircleBorder(),
                                                              value:
                                                                  _subscribing,
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _subscribing =
                                                                      value!;

                                                                  // add subscribing to authorized user list
                                                                  authorizedUserIds
                                                                      .addAll(user
                                                                          .subscribing);
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const Text(
                                                              'Subscribing'),
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
                                                  width: MediaQuery.of(context)
                                                              .size
                                                              .width >=
                                                          webScreenSize
                                                      ? (MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.14) -
                                                          24
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.42,
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 11,
                                                      vertical: 1),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // button to customized user list
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            searchController
                                                                .clear();
                                                          });
                                                          _displayAlertDialogBox(
                                                              context);
                                                        },
                                                        child: Container(
                                                          height: 30,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.4,
                                                          decoration:
                                                              const ShapeDecoration(
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(
                                                                Radius.circular(
                                                                    8),
                                                              ),
                                                            ),
                                                            color: blueColor,
                                                          ),
                                                          child: const Center(
                                                            child: Text(
                                                              'Customize user list',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // display custom user list
                                                      SizedBox(
                                                        height: 75,
                                                        child:
                                                            ScrollConfiguration(
                                                          behavior:
                                                              const ScrollBehavior(),
                                                          child:
                                                              GlowingOverscrollIndicator(
                                                            axisDirection:
                                                                AxisDirection
                                                                    .down,
                                                            color: secondaryColor
                                                                .withOpacity(
                                                                    0.5),
                                                            child: ListView
                                                                .builder(
                                                              shrinkWrap: true,
                                                              itemCount:
                                                                  _customUserUsernames
                                                                      .length,
                                                              itemBuilder:
                                                                  ((context,
                                                                      index) {
                                                                return Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.3,
                                                                      child:
                                                                          ListTile(
                                                                        dense:
                                                                            true,
                                                                        visualDensity:
                                                                            const VisualDensity(
                                                                          vertical:
                                                                              -4,
                                                                        ),
                                                                        contentPadding:
                                                                            const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              0,
                                                                          horizontal:
                                                                              0,
                                                                        ),
                                                                        minVerticalPadding:
                                                                            0,
                                                                        title:
                                                                            Padding(
                                                                          padding: const EdgeInsets.fromLTRB(
                                                                              10,
                                                                              2,
                                                                              0,
                                                                              0),
                                                                          child:
                                                                              Text(
                                                                            _customUserUsernames[index],
                                                                            textScaleFactor:
                                                                                1.2,
                                                                          ),
                                                                        ),
                                                                        trailing:
                                                                            Transform.scale(
                                                                          scale:
                                                                              0.9,
                                                                          child:
                                                                              IconButton(
                                                                            icon:
                                                                                const Icon(
                                                                              Icons.delete_forever_rounded,
                                                                            ),
                                                                            onPressed:
                                                                                () {
                                                                              setState(() {
                                                                                _customUserUids.removeAt(index);
                                                                                _customUserUsernames.removeAt(index);
                                                                              });
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            5),
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
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 0, 20, 10),
                                        child: Center(
                                          child: TextField(
                                            controller: descriptionController,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Write your caption ...',
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
                            const SizedBox(height: 40),
                            InkWell(
                              onTap: kIsWeb
                                  // show error if using web
                                  ? () => showSnackBar(
                                      context,
                                      'Currently this function is not supported on web yet 😭',
                                      failColor)
                                  : () => _file != null
                                      // define who to receive notification when new post is uploaded
                                      ? postFile(user.uid, user.username,
                                          user.photoUrl, user.photoUrl)
                                      : null,
                              child: Container(
                                width: 240,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: ShapeDecoration(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  color: _file != null
                                      ? blueColor
                                      : secondaryColor,
                                ),
                                child: const Text('Encrypt and Post'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
