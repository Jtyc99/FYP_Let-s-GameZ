// ignore_for_file: no_leading_underscores_for_local_identifiers, avoid_print, use_build_context_synchronously, depend_on_referenced_packages
import 'dart:convert';
import 'dart:math';

import 'package:drop_shadow_image/drop_shadow_image.dart';
import 'package:encryptions/encryptions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lets_gamez/main.dart';
import 'package:lets_gamez/resources/auth_methods.dart';
import 'package:lets_gamez/screens/login_screen.dart';
import 'package:lets_gamez/screens/notification_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';

// customized buttons for page navigation
InkWell button(
  int? page,
  int pageButton,
  PageController? pageController,
  bool disable,
) {
  IconData icon = Icons.abc;
  String tip = '';
  Color color = disable
      ? secondaryColor.shade500
      : page == pageButton
          ? primaryColor
          : secondaryColor.shade500;
  switch (pageButton) {
    case 0:
      icon = Icons.home_rounded;
      tip = 'Feed';
      break;
    case 1:
      icon = Icons.search_rounded;
      tip = 'Search';
      break;
    case 2:
      icon = Icons.add_circle_rounded;
      tip = 'Upload';
      break;
    case 3:
      icon = Icons.person_rounded;
      tip = 'Profile';
      break;
  }

  return InkWell(
    onTap: () => disable ? null : navigationTapped(pageButton, pageController!),
    child: Row(
      children: [
        Icon(
          icon,
          color: color,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          tip,
          style: TextStyle(
            color: color,
          ),
        ),
      ],
    ),
  );
}

// navigate to different pages
void navigationTapped(int page, PageController pageController) {
  pageController.jumpToPage(page);
}

// scaffold for web application
Scaffold scaffold(
  BuildContext context,
  int? page,
  PageController? pageController,
  Widget widget,
) {
  bool disable = false;
  if (page == null && pageController == null) {
    disable = true;
  }
  return Scaffold(
    body: Row(
      children: [
        Container(
          width: (MediaQuery.of(context).size.width / 4) - 16,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
            children: [
              Flexible(flex: 2, child: Container()),
              SizedBox(
                width: 200,
                height: 200,
                child: DropShadowImage(
                  offset: const Offset(10, 10),
                  scale: 1,
                  blurRadius: 12,
                  borderRadius: 20,
                  image: Image.asset('assets/images/logo.png'),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              // app name
              const Center(
                child: Text(
                  'Let\'s\nGameZ',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'PressStart2P-Regular',
                  ),
                ),
              ),
              const SizedBox(
                height: 80,
              ),
              button(page, 0, pageController, disable),
              const SizedBox(
                height: 20,
              ),
              button(page, 1, pageController, disable),
              const SizedBox(
                height: 20,
              ),
              button(page, 2, pageController, disable),
              const SizedBox(
                height: 20,
              ),
              button(page, 3, pageController, disable),
              Flexible(flex: 2, child: Container()),
              const SizedBox(
                height: 220,
              ),
              // change mode button
              InkWell(
                onTap: () {
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
                child: Row(
                  children: const [
                    Icon(
                      Icons.settings_rounded,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Switch mode',
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // logout button
              InkWell(
                onTap: () => showSignOutAlertBox(context),
                child: Row(
                  children: const [
                    Icon(
                      Icons.logout_rounded,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Logout',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(
          color: secondaryColor,
          thickness: 0.4,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 20),
          width: MediaQuery.of(context).size.width / 2,
          child: widget,
        ),
        const VerticalDivider(
          color: secondaryColor,
          thickness: 0.4,
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width / 4) - 16,
          child: NotificationScreen(
            uid: FirebaseAuth.instance.currentUser!.uid,
            page: page,
            pageController: pageController,
          ),
        ),
      ],
    ),
  );
}

// for picking profile picture
pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _file = await _imagePicker.pickImage(source: source);

  if (_file != null) {
    return await _file.readAsBytes();
  }
  print('No image is selected');
}

// for displaying snackbars
showSnackBar(BuildContext context, String text, Color color) {
  // remove current snackbar
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.grey.withOpacity(0.5),
      duration: const Duration(seconds: 2),
      content: Text(
        text,
        style: TextStyle(
          color: color,
        ),
      ),
    ),
  );
}

// for displaying discard posts or changes alert box
showDiscardAlertBox(BuildContext context, String type) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        title: Text(
          'Discard $type?',
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'If you go back now, you will lose any changes that you\'ve made.',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 12,
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
                onTap: () => routeToMyApp(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: const Text(
                    'Discard',
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
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel',
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
    },
  );
}

showSignOutAlertBox(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        title: const Text(
          'Logging out?',
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
                onTap: () async {
                  // logout user
                  await AuthMethods().logoutUser();
                  // redirect to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false);
                  showSnackBar(
                      context, 'Successfully logged out', successColor);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Divider(
                color: secondaryColor,
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: const Text(
                    'No',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

// for picking file to be uploaded
pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    return result;
  }
  print('No file is selected');
}

// generate random key and iv (params) for aes-256 encryption
List<Uint8List> generateParams() {
  Random random = Random.secure();
  final int max = pow(2, 32).toInt();
  Uint8List key =
      Uint8List.fromList(List<int>.generate(32, (i) => random.nextInt(max)));
  Uint8List iv =
      Uint8List.fromList(List<int>.generate(16, (i) => random.nextInt(max)));
  return [key, iv];
}

// encrypt Uint8List file
Future<Uint8List> encryptFile(List<Uint8List> params, Uint8List file) async {
  AES aes = AES.ofCBC(params[0], params[1], PaddingScheme.PKCS5Padding);
  Uint8List encrypted = await aes.encrypt(file);
  return encrypted;
}

// decrypt Uint8List file
Future<Uint8List> decryptFile(List<Uint8List> params, Uint8List file) async {
  AES aes = AES.ofCBC(params[0], params[1], PaddingScheme.PKCS5Padding);
  Uint8List decrypted = await aes.decrypt(file);
  return decrypted;
}

// encode params to String
String convertToString(Uint8List byte) {
  String str = base64Url.encode(byte);
  return str;
}

// decode params to Uint8List
Uint8List convertToUint8List(String str) {
  Uint8List byte = base64Url.decode(str);
  return byte;
}

// return translated datePublished
String transformDatePublished(DateTime dateTimePublished) {
  DateTime now = DateTime.now();
  String timePublished = '';

  Duration diff = now.difference(dateTimePublished);

  // for more than or equal to one year ago
  if (diff.inDays >= 365) {
    if (diff.inDays < 730) {
      timePublished = '1 year ago';
    } else {
      timePublished = DateFormat.yMMMMd().format(dateTimePublished);
    }
  } else {
    // for more than or equal to one month ago
    if (diff.inDays >= 30) {
      timePublished = '${diff.inDays ~/ 30}';
      if (int.parse(timePublished) == 1) {
        timePublished = '$timePublished month ago';
      } else {
        timePublished = '$timePublished months ago';
      }
    } else {
      // for more than or equal to one week ago
      if (diff.inDays >= 7) {
        timePublished = '${diff.inDays ~/ 30}';
        if (int.parse(timePublished) == 1) {
          timePublished = '$timePublished week ago';
        } else {
          timePublished = '$timePublished weeks ago';
        }
      } else {
        // for more than or equal to one day ago
        if (diff.inDays >= 1) {
          timePublished = '${diff.inDays}';
          if (int.parse(timePublished) == 1) {
            timePublished = '$timePublished day ago';
          } else {
            timePublished = '$timePublished days ago';
          }
        } else {
          // for more than or equal to one hour ago
          if (diff.inHours >= 1) {
            timePublished = '${diff.inHours}';
            if (int.parse(timePublished) == 1) {
              timePublished = '$timePublished hour ago';
            } else {
              timePublished = '$timePublished hours ago';
            }
          } else {
            // for more than or equal to one minute ago
            if (diff.inMinutes >= 1) {
              timePublished = '${diff.inMinutes}';
              if (int.parse(timePublished) == 1) {
                timePublished = '$timePublished minute ago';
              } else {
                timePublished = '$timePublished minutes ago';
              }
            } else {
              // for less than one minute
              timePublished = '${diff.inSeconds}';
              if (int.parse(timePublished) <= 5) {
                timePublished = '1 second ago';
              } else {
                timePublished = '$timePublished seconds ago';
              }
            }
          }
        }
      }
    }
  }
  return timePublished;
}
