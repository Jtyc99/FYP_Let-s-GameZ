import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
/* import 'package:lets_gamez/resources/firestore_methods.dart'; */
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/widgets/notification_card.dart';

class NotificationScreen extends StatelessWidget {
  final String uid;
  final int? page;
  final PageController? pageController;
  const NotificationScreen({
    Key? key,
    required this.uid,
    this.page,
    this.pageController,
  }) : super(key: key);

  /* // method to clear notifications (with bug)
  void clearNotifications() async {
    FirestoreMethods().removeNotifications(uid);
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Notifications'),
        /* // icon button to clear all notifications
        actions: [
          IconButton(
            onPressed: clearNotifications,
            icon: const Icon(Icons.delete_forever_rounded),
          ),
        ], */
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if ((snapshot.data! as dynamic).docs.length == 0) {
            return const Center(
              child: Text(
                'No new notification yet 😭',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            );
          }

          return ScrollConfiguration(
            behavior: const ScrollBehavior(),
            child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: secondaryColor.withOpacity(0.5),
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) => NotificationCard(
                  snap: snapshot.data!.docs[index].data(),
                  page: page,
                  pageController: pageController,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
