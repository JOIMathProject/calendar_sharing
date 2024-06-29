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
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Sign in to Omikuji'),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20,horizontal: 50),
        child: ElevatedButton(
            child: Text('Sign in with google'),
            onPressed:()async{
              dynamic result = await _auth.signInWithGoogle(context);
              if(result == null){
                print('error sign in');
              }else{
                print('signed in');
                print(result);
              }
            }
        ),
      ),
    );
  }

}
