// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lets_gamez/resources/firestore_methods.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:lets_gamez/widgets/text_field_input.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  var userData = {};
  Uint8List? _image;
  bool isLoading = false;
  bool isEdited = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      userData = userSnap.data()!;
      setState(() {
        _usernameController.text = userData['username'];
        _phoneController.text = userData['phone'];
        _bioController.text = userData['bio'];

        // check if profile is edited
        _usernameController.addListener(() {
          if (_usernameController.text != userData['username']) {
            isEdited = true;
          } else {
            isEdited = false;
          }
        });
        _phoneController.addListener(() {
          if (_phoneController.text != userData['phone']) {
            isEdited = true;
          } else {
            isEdited = false;
          }
        });
        _bioController.addListener(() {
          if (_bioController.text != userData['bio']) {
            isEdited = true;
          } else {
            isEdited = false;
          }
        });
      });
    } catch (e) {
      showSnackBar(context, e.toString(), failColor);
    }
    setState(() {
      isLoading = false;
    });
  }

  void selectImage() async {
    Uint8List? image = await pickImage(ImageSource.gallery);
    setState(() {
      if (image != null) {
        _image = image;
      }
    });
  }

  void editUser() async {
    setState(() {
      isEditing = true;
    });
    // edit user profile
    String res = await FirestoreMethods().editProfile(
      FirebaseAuth.instance.currentUser!.uid,
      _usernameController.text,
      _phoneController.text,
      _bioController.text,
      _image,
    );
    setState(() {
      isEditing = false;
    });

    if (res == 'success') {
      routeToMyApp(context);
      showSnackBar(context, 'Successfully edited profile', successColor);
    } else {
      showSnackBar(context, res, failColor);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: mobileBackgroundColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => isEdited
                      ? showDiscardAlertBox(context, 'changes')
                      : Navigator.of(context).pop(),
                ),
                title: const Text('Edit Profile'),
                centerTitle: true,
              ),
              body: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                height: double.infinity,
                width: double.infinity,
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior(),
                  child: GlowingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    color: secondaryColor.withOpacity(0.5),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          kIsWeb
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                )
                              : const SizedBox(
                                  height: 40,
                                ),
                          Stack(
                            children: [
                              _image != null
                                  ?
                                  // selected profile pic
                                  CircleAvatar(
                                      radius: 64,
                                      backgroundColor: Colors.grey,
                                      backgroundImage: MemoryImage(_image!),
                                    )
                                  :
                                  // default profile pic
                                  CircleAvatar(
                                      radius: 64,
                                      backgroundColor: Colors.grey,
                                      backgroundImage: NetworkImage(
                                        userData['photoUrl'],
                                      ),
                                    ),
                              Positioned(
                                bottom: -10,
                                left: 80,
                                child: IconButton(
                                  onPressed: selectImage,
                                  icon: const Icon(
                                    Icons.add_a_photo_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // text field input for username
                          TextFieldInput(
                            hintText: 'Username',
                            textInputType: TextInputType.text,
                            textEditingController: _usernameController,
                            maxLength: 20,
                          ),
                          const SizedBox(height: 24),
                          // text field input for phone
                          TextFieldInput(
                            hintText: 'Phone',
                            textInputType: TextInputType.number,
                            textEditingController: _phoneController,
                          ),
                          const SizedBox(height: 24),
                          // text field input for bio
                          TextFieldInput(
                            hintText: 'Bio',
                            textInputType: TextInputType.multiline,
                            textEditingController: _bioController,
                            maxLength: 50,
                            maxLines: 3,
                          ),
                          kIsWeb
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                )
                              : const SizedBox(
                                  height: 60,
                                ),
                          // submit button
                          InkWell(
                            onTap: editUser,
                            child: Container(
                              width: double.infinity,
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
                          kIsWeb
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                )
                              : const SizedBox(
                                  height: 40,
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
