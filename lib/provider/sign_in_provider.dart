import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class SignInProvider extends ChangeNotifier{
  //Creating Authentication instances for Email, Facebook and Google
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FacebookAuth facebookAuth = FacebookAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: "860174849717-m0gblats1qbmt6pua0dtj7b7kv364r0m.apps.googleusercontent.com",
      );
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;
  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorCode;
  String? get errorCode => _errorCode;

  String? _provider;
  String? get provider => _provider;

  String? _uid;
  String? get uid => _uid;

  String? _name;
  String? get name => _name;

  String? _email;
  String? get email => _email;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;


  SignInProvider(){
    checkSignInUser();
  }
  //Sign in state
  Future checkSignInUser() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _isSignedIn = s.getBool("signed_in")?? false;
    notifyListeners();
  }
  Future setSignIn() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.setBool("signed_in", true);
    _isSignedIn = true;
    notifyListeners();
  }

  //Sign in with Google, gets token from google and signs in to firebase auth
  Future signInWithGoogle() async {
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount != null){
      try {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // signing to firebase user instance
        final User userDetails =
            (await firebaseAuth.signInWithCredential(credential)).user!;

        // now save all values
        _name = userDetails.displayName;
        _email = userDetails.email;
        _imageUrl = userDetails.photoURL;
        _provider = "GOOGLE";
        _uid = userDetails.uid;
        notifyListeners();
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          //In case the email is already in use for different provider
          case "account-exists-with-different-credential":
            _errorCode =
                "You already have an account with us. Use correct provider";
            _hasError = true;
            notifyListeners();
            break;

          case "null":
            _errorCode = "Some unexpected error while trying to sign in";
            _hasError = true;
            notifyListeners();
            break;
          default:
            _errorCode = e.toString();
            _hasError = true;
            notifyListeners();
        }
      }
    }
    else{
      _hasError=true;
      notifyListeners();
    }
  }

  //Sign in using facebook
  Future signInWithFacebook() async {
    final LoginResult result = await facebookAuth.login();
    //Get user profile
    final graphResponse = await http.get(
    Uri.parse('https://graph.facebook.com/v2.12/me?fields=name,picture.width(800).height(800),first_name,last_name,email&access_token=${result.accessToken!.token}'));
    final profile = jsonDecode(graphResponse.body);
    if(result.status==LoginStatus.success){
      try{
        //Sign in to firestore using credentials/tokens
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
        //Get user data
        await firebaseAuth.signInWithCredential(credential);
        _name=profile['name'];
        _email=profile['email'];
        _imageUrl=profile['picture']['data']['url'];
        _uid=profile['id'];
        _provider="FACEBOOK";
        _hasError=false;
        notifyListeners();
      }on FirebaseAuthException catch (e) {
        switch (e.code) {
          case "account-exists-with-different-credential":
            _errorCode =
                "You already have an account with us. Use correct provider";
            _hasError = true;
            notifyListeners();
            break;

          case "null":
            _errorCode = "Some unexpected error while trying to sign in";
            _hasError = true;
            notifyListeners();
            break;
          default:
            _errorCode = e.toString();
            _hasError = true;
            notifyListeners();
        }
      }
    }
    else{
      _hasError=true;
      notifyListeners();
    }
  }

  //Sign in using email
  Future signInWithEmail(String email, String password) async {
    try{
      UserCredential credential =await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      //Retreive user data
      _name = (credential.user!).displayName;
      _email = (credential.user!).email;
      _imageUrl = (credential.user!).photoURL;
      _provider = "Email";
      _uid=(credential.user!).uid;
      
      notifyListeners();
    }on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        
        _errorCode = 'Invalid email or password';
        _hasError = true;
        notifyListeners();
      } else {
        _errorCode = e.toString();
        _hasError = true;
        notifyListeners();
        
      }

    }

    
  }
  
  //Sign up using email
  Future signUpWithEmail(String email, String password, String username) async {
    try {
      //Create new user
      UserCredential uc = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      //Add data
      _name=username;
      _email=email;
      _provider="EMAIL";
      _uid=(uc.user!).uid;
      _imageUrl="https://static.vecteezy.com/system/resources/thumbnails/020/765/399/small/default-profile-account-unknown-icon-black-silhouette-free-vector.jpg";
      
      notifyListeners();
      
    } on FirebaseAuthException catch (e) {

      if (e.code == 'email-already-in-use') {
        _errorCode = "Email is already registered";
        _hasError = true;
        notifyListeners();
        
      } else {
        _errorCode = e.toString();
        _hasError = true;
        notifyListeners();
        
      }
    }
    return null;

    
  }

  //Sign out
  Future userSignOut() async{
    //Sign out all the authentication instances
    await firebaseAuth.signOut();
    await googleSignIn.signOut();
    await facebookAuth.logOut();
    _isSignedIn=false;
    notifyListeners();
    //Clear data
    clearStoredData();

  }
  Future clearStoredData() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.clear();
  }

  //retreive data from firestore database
  Future getUserDataFromFirestore(uid) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get()
        .then((DocumentSnapshot snapshot) => {
              _uid = snapshot['uid'],
              _name = snapshot['name'],
              _email = snapshot['email'],
              _imageUrl = snapshot['image_url'],
              _provider = snapshot['provider'],
            });
  }

  //Saving data to firestore
  Future saveDataToFirestore() async {
    final DocumentReference r =
        FirebaseFirestore.instance.collection("users").doc(uid);
    await r.set({
      "name": _name,
      "email": _email,
      "uid": _uid,
      "image_url": _imageUrl!,
      "provider": _provider,
    });
    notifyListeners();
  }

  //Save data locally
  Future saveDataToSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    await s.setString('name', _name!);
    await s.setString('email', _email!);
    await s.setString('uid', _uid!);
    await s.setString('image_url', _imageUrl!);
    await s.setString('provider', _provider!);
    notifyListeners();
  }

  //Get data locally
  Future getDataFromSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _name = s.getString('name');
    _email = s.getString('email');
    _imageUrl = s.getString('image_url');
    _uid = s.getString('uid');
    _provider = s.getString('provider');
    notifyListeners();
  }
  Future<bool> checkUserExists() async{
    DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if(snap.exists){
      
      return true;
    }
    else{
      
      return false;
    }
  }
}