// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:lets_gamez/resources/auth_methods.dart';
import 'package:lets_gamez/screens/login_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/global_variables.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:lets_gamez/widgets/text_field_input.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isPass1 = true;
  bool isPass2 = true;
  ByteData? imageData;
  Uint8List? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    rootBundle
        .load('assets/images/profile pic.png')
        .then((data) => setState(() => imageData = data));
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  void selectImage() async {
    Uint8List? image = await pickImage(ImageSource.gallery);
    setState(() {
      if (image != null) {
        _image = image;
      }
    });
  }

  void signUpUser() async {
    setState(() {
      _isLoading = true;
    });
    String res = '';
    if (_passwordController.text.isEmpty) {
      showSnackBar(context, 'Required field(s)', failColor);
    } else if (_passwordController.text.length < 6) {
      showSnackBar(context, 'Weak password', failColor);
    } else {
      if (_passwordController.text == _confirmPasswordController.text) {
        _image ??= imageData?.buffer.asUint8List();
        // produce digest from hashing password
        var key = utf8.encode('p@ssword');
        var bytes = utf8.encode(_passwordController.text);
        var hmacSha256 = Hmac(sha256, key);
        var digest = hmacSha256.convert(bytes);
        // sign up user
        res = await AuthMethods().signUpUser(
          username: _usernameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          bio: _bioController.text,
          password: digest.toString(),
          file: _image!,
        );
        setState(() {
          _isLoading = false;
        });

        if (res == 'success') {
          routeToMyApp(context);
          showSnackBar(context, 'Successfully signed up', successColor);
        } else {
          showSnackBar(context, res, failColor);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        res = 'Passwords do not match';
        showSnackBar(context, res, failColor);
      }
    }
  }

  void navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // column for holding widgets
    Column column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        !kIsWeb
            ? Flexible(
                flex: 2,
                child: Container(
                  height: 60,
                ))
            : Flexible(flex: 2, child: Container()),
        // circular widget for profile pic
        Stack(
          children: [
            _image != null
                ?
                // selected profile pic
                CircleAvatar(
                    radius: 64,
                    backgroundImage: MemoryImage(_image!),
                  )
                :
                // default profile pic
                const CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        AssetImage('assets/images/profile pic.png'),
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
        // text field input for email
        TextFieldInput(
          hintText: 'Email',
          textInputType: TextInputType.emailAddress,
          textEditingController: _emailController,
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
        const SizedBox(height: 24),
        // text field input for password
        TextFieldInput(
          hintText: 'Password',
          textInputType: TextInputType.text,
          textEditingController: _passwordController,
          isPass: isPass1,
          inkWell: InkWell(
            onTap: () {
              setState(() {
                isPass1 = !isPass1;
              });
            },
            child: isPass1
                ? const Icon(Icons.visibility_rounded)
                : const Icon(Icons.visibility_off_rounded),
          ),
        ),
        const SizedBox(height: 24),
        // text field input for confirm password
        TextFieldInput(
          hintText: 'Confirm Password',
          textInputType: TextInputType.text,
          textEditingController: _confirmPasswordController,
          isPass: isPass2,
          inkWell: InkWell(
            onTap: () {
              setState(() {
                isPass2 = !isPass2;
              });
            },
            child: isPass2
                ? const Icon(Icons.visibility_rounded)
                : const Icon(Icons.visibility_off_rounded),
          ),
        ),
        const SizedBox(height: 24),
        // sign up button
        InkWell(
          onTap: signUpUser,
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : const Text('Sign Up'),
          ),
        ),
        const SizedBox(height: 12),
        !kIsWeb
            ? Flexible(
                flex: 2,
                child: Container(
                  height: 60,
                ))
            : Flexible(flex: 2, child: Container()),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: const Text('Already have an account?'),
            ),
            GestureDetector(
              onTap: navigateToLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Container(
            padding: MediaQuery.of(context).size.width > webScreenSize
                ? EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.38)
                : const EdgeInsets.symmetric(horizontal: 32),
            width: double.infinity,
            child: !kIsWeb
                ? ScrollConfiguration(
                    behavior: const ScrollBehavior(),
                    child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.down,
                      color: secondaryColor.withOpacity(0.5),
                      child: SingleChildScrollView(
                        child: column,
                      ),
                    ),
                  )
                : column,
          ),
        ),
      ),
    );
  }
}
