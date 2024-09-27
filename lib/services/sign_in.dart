import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screen/wrapper.dart';
import 'auth.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[

          Spacer(
            flex: 3,
          ),
          Flexible(
            flex: 3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Sando',
                  style: TextStyle(
                    fontFamily: 'SmglMediumbold',
                    fontWeight: FontWeight.bold,
                    fontSize: 110.0,
                    color: GlobalColor.MainCol,
                  ),
                ),
              ),
            ),
          ),Flexible(
            flex: 4,
            child: FractionallySizedBox(
              widthFactor: .8,
              child: Image.asset(
                'assets/image/icon_transparent.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Spacer(
            flex: 1,
          ),
          Flexible(
            flex: 1,
            child: Center(
              child: Container(
                width: 300.0, // Desired width
                height: 70.0, // Desired height
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(5), // Adjust as needed
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // This makes the Row width the same as the children
                    children: <Widget>[
                      Icon(FontAwesomeIcons.google,
                          color: GlobalColor.SubCol), // Google icon
                      SizedBox(width: 10), // Spacing between the icon and text
                      Text('Googleでサインイン',
                          style: TextStyle(color: GlobalColor.SubCol)),
                    ],
                  ),
                  onPressed: () async {
                    dynamic result = await _auth.signInWithGoogle(context);
                    if (result == null) {
                      print('error sign in');
                    } else {
                      print('signed in');
                      print(result);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Wrapper()),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Spacer(
            flex: 4,
          ),
        ],
      ),
    );
  }
}
