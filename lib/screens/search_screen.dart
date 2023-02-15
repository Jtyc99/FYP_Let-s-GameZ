import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lets_gamez/screens/profile_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/global_variables.dart';
import 'package:lets_gamez/utils/utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isShowUsers = false;

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          title: TextFormField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Search for a user'),
            onFieldSubmitted: (String _) {
              setState(() {
                isShowUsers = true;
              });
            },
          ),
        ),
        body: ScrollConfiguration(
          behavior: const ScrollBehavior(),
          child: GlowingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            color: secondaryColor.withOpacity(0.5),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Text('Suggestion:'),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 168,
                    child: FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          // show all users for default
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
                                // dont display current user
                                if (uid !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      backgroundImage: NetworkImage(
                                          (snapshot.data! as dynamic)
                                              .docs[index]['photoUrl']),
                                    ),
                                    title: Text(
                                      (snapshot.data! as dynamic).docs[index]
                                          ['username'],
                                    ),
                                    onTap: () {
                                      if (MediaQuery.of(context).size.width >=
                                          webScreenSize) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => scaffold(
                                              context,
                                              null,
                                              null,
                                              PageView(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                children: [
                                                  ProfileScreen(uid: uid),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfileScreen(uid: uid),
                                          ),
                                        );
                                      }
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
        ),
      ),
    );
  }
}
