import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'auth.dart';

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
          Flexible(
            flex: 4,
            child: Image.network(
              'https://cdn0.iconfinder.com/data/icons/small-n-flat/24/678116-calendar-512.png', // Replace with your image URL
              fit: BoxFit.cover,
            ),
          ),
          Flexible(
            flex: 1,
              child: Center(
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0), // Adjust as needed
                    ),
                  ),
                  child: Text('Sign in with google'),
                  onPressed: () async {
                    dynamic result = await _auth.signInWithGoogle(context);
                    if (result == null) {
                      print('error sign in');
                    } else {
                      print('signed in');
                      print(result);
                    }
                  },
                ),
              )
            ),
        ],
      ),
    );
  }

}
