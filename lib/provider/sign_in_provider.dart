import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInProvider extends ChangeNotifier{
  // final FirebaseFirestore firestore = FirebaseFirestore.instance;
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

  // UserMetadata? _metadata;
  // UserMetadata? get metadata => _metadata;

  SignInProvider(){
    checkSignInUser();
  }
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
        // _metadata = userDetails.metadata;
        notifyListeners();
      } on FirebaseAuthException catch (e) {
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

  Future signInWithEmail(String email, String password) async {
    try{
      UserCredential credential =await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      _name = (credential.user!).displayName;
      _email = (credential.user!).email;
      _imageUrl = (credential.user!).photoURL;
      _provider = "Email";
      // _uid = (credential.user).uid;
      notifyListeners();
    }on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        // showToast(message: 'Invalid email or password.');
        _errorCode = 'Invalid email or password';
        _hasError = true;
        notifyListeners();
      } else {
        _errorCode = e.toString();
        _hasError = true;
        notifyListeners();
        // showToast(message: 'An error occurred: ${e.code}');
      }

    }

    
  }
  // postDetails() async{
  //   final FirebaseFirestore firestore = FirebaseFirestore.instance;
  //   User? user = firebaseAuth.currentUser;
  // }

  Future signUpWithEmail(String email, String password, String username) async {
    try {
      UserCredential uc = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      _name=username;
      _email=email;
      _provider="EMAIL";
      _uid=(uc.user!).uid;
      _imageUrl="";
      
      notifyListeners();
      
    } on FirebaseAuthException catch (e) {

      if (e.code == 'email-already-in-use') {
        _errorCode = "Email is already registered";
        _hasError = true;
        notifyListeners();
        // showToast(message: 'The email address is already in use.');
      } else {
        _errorCode = e.toString();
        _hasError = true;
        notifyListeners();
        // showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;

    
  }

  Future userSignOut() async{
    await firebaseAuth.signOut();
    await googleSignIn.signOut();
    _isSignedIn=false;
    notifyListeners();

  }
  Future clearStoredData() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.clear();
  }
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

  Future saveDataToSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    await s.setString('name', _name!);
    await s.setString('email', _email!);
    await s.setString('uid', _uid!);
    await s.setString('image_url', _imageUrl!);
    await s.setString('provider', _provider!);
    notifyListeners();
  }

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
      // print("Existing user");
      return true;
    }
    else{
      // print("New user");
      return false;
    }
  }
}