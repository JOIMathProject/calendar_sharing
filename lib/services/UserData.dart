import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserData extends ChangeNotifier {
  GoogleSignIn? googleUser;
  String? google_uid;
  String? uid;
  String? uname;
  String? uicon;
  String? refreshToken;
  String? mailAddress;
  List<FriendInformation> friends = [];

  void updateGoogleUser(GoogleSignIn? newGoogleUser) {
    googleUser = newGoogleUser;
    notifyListeners();
  }
  void updateUserInfo(UserInformation userInfo) {
    google_uid = userInfo.google_uid;
    uid = userInfo.uid;
    uname = userInfo.uname;
    uicon = userInfo.uicon;
    refreshToken = userInfo.refreshToken;
    mailAddress = userInfo.mailAddress;
    cacheUserInfo();
    notifyListeners();
  }
  void updateFriends(List<FriendInformation> newFriends) {
    friends = newFriends;
    notifyListeners();
  }
  void cacheUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_uid', google_uid ?? '');
    await prefs.setString('uid', uid ?? '');
    await prefs.setString('uname', uname ?? '');
    await prefs.setString('uicon', uicon ?? '');
    await prefs.setString('refreshToken', refreshToken ?? '');
    await prefs.setString('mailAddress', mailAddress ?? '');
  }

  Future<void> loadUserInfoFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    google_uid = prefs.getString('google_uid');
    uid = prefs.getString('uid');
    uname = prefs.getString('uname');
    uicon = prefs.getString('uicon');
    refreshToken = prefs.getString('refreshToken');
    mailAddress = prefs.getString('mailAddress');
    notifyListeners();
  }
}