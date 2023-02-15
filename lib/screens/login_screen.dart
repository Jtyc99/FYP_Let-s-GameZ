// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drop_shadow_image/drop_shadow_image.dart';
import 'package:lets_gamez/resources/auth_methods.dart';
import 'package:lets_gamez/screens/signup_screen.dart';
import 'package:lets_gamez/utils/colors.dart';
import 'package:lets_gamez/utils/global_variables.dart';
import 'package:lets_gamez/utils/routes.dart';
import 'package:lets_gamez/utils/utils.dart';
import 'package:lets_gamez/widgets/text_field_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPass = true;
  bool _isLoading = false;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController.repeat(reverse: true);
    _animation = Tween(begin: 2.0, end: 30.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animation.removeListener(() {});
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void loginUser() async {
    setState(() {
      _isLoading = true;
    });
    // produce digest from hashing password
    var key = utf8.encode('p@ssword');
    var bytes = utf8.encode(_passwordController.text);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);

    String res = await AuthMethods()
        .loginUser(email: _emailController.text, password: digest.toString());
    setState(() {
      _isLoading = false;
    });

    if (res == 'success') {
      routeToMyApp(context);
      showSnackBar(context, 'Successfully logged in', successColor);
    } else {
      showSnackBar(context, res, failColor);
    }
  }

  void navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // animating app name
    var animatedTextKit = AnimatedTextKit(
      animatedTexts: [
        ColorizeAnimatedText(
          'Let\'s GameZ',
          speed: const Duration(seconds: 3),
          textStyle: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 32,
            fontFamily: 'PressStart2P-Regular',
            shadows: [
              Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 6.0,
                color: primaryColor,
              ),
            ],
          ),
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
          ],
        ),
      ],
      isRepeatingAnimation: true,
      repeatForever: true,
    );
    // column for holding widgets
    Column column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        !kIsWeb
            ? Flexible(
                flex: 2,
                child: Container(
                  height: 80,
                ),
              )
            : Flexible(flex: 2, child: Container()),
        // logo
        Stack(
          children: [
            Positioned(
              top: 80,
              left: 60,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor,
                      blurRadius: _animation.value,
                      spreadRadius: _animation.value,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 80,
                  height: 80,
                ),
              ),
            ),
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
          ],
        ),
        const SizedBox(height: 24),
        // app name
        !kIsWeb
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 85.5),
                child: animatedTextKit,
              )
            : const Center(
                child: Text(
                  'Let\'s\nGameZ',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'PressStart2P-Regular',
                  ),
                ),
              ),
        const SizedBox(height: 48),
        // text field input for email
        TextFieldInput(
          hintText: 'Email',
          textInputType: TextInputType.emailAddress,
          textEditingController: _emailController,
        ),
        const SizedBox(height: 24),
        // text field input for password
        TextFieldInput(
          hintText: 'Password',
          textInputType: TextInputType.text,
          textEditingController: _passwordController,
          isPass: isPass,
          inkWell: InkWell(
            onTap: () {
              setState(() {
                isPass = !isPass;
              });
            },
            child: isPass
                ? const Icon(Icons.visibility_rounded)
                : const Icon(Icons.visibility_off_rounded),
          ),
        ),
        const SizedBox(height: 24),
        // login button
        InkWell(
          onTap: loginUser,
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
                : const Text('Login'),
          ),
        ),
        const SizedBox(height: 12),
        !kIsWeb
            ? Flexible(
                flex: 2,
                child: Container(
                  height: 80,
                ))
            : Flexible(flex: 2, child: Container()),
        // transitioning to signing up
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: const Text('Don\'t have an account?'),
            ),
            GestureDetector(
              onTap: navigateToSignUp,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Sign up',
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
