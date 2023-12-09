// import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:login_app/provider/internet_provider.dart';
import 'package:login_app/provider/sign_in_provider.dart';
import 'package:login_app/screens/form.dart';
import 'package:login_app/screens/home_screen.dart';
import 'package:login_app/screens/sign_up_screen.dart';
import 'package:login_app/utils/config.dart';
import 'package:login_app/utils/next_screen.dart';
import 'package:login_app/utils/snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();
  final RoundedLoadingButtonController googleController = RoundedLoadingButtonController();
  final RoundedLoadingButtonController facebookController = RoundedLoadingButtonController();
  final RoundedLoadingButtonController emailButtonController = RoundedLoadingButtonController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
        padding:
          const EdgeInsets.only(left: 40, right: 40, top: 90, bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(image: AssetImage(Config.app_icon),
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20,),
                  Text("Welcome to my App", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),),
                  SizedBox(
                    height: 10,
                  ),
                  Text("Sign in or Sign up",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  FormContainerWidget(
                    controller: _emailController,
                    hintText: "Email",
                    isPasswordField: false,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  FormContainerWidget(
                    controller: _passwordController,
                    hintText: "Password",
                    isPasswordField: true,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  RoundedLoadingButton(
                  onPressed: (){
                    handleEmailSignIn();
                  },
                  controller: emailButtonController,
                  successColor: Colors.green,
                  width: MediaQuery.of(context).size.width * 0.80,
                  elevation: 0,
                  borderRadius: 25,
                  color: Colors.grey.shade800,
                  child: const Wrap(
                    children: [
                      
                      Text("Sign in",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  ),

                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundedLoadingButton(
                  onPressed: (){
                    handleGoogleSignIn();
                  },
                  controller: googleController,
                  successColor: Colors.red,
                  width: MediaQuery.of(context).size.width * 0.80,
                  elevation: 0,
                  borderRadius: 25,
                  color: Colors.red,
                  child: const Wrap(
                    children: [
                      Icon(
                        FontAwesomeIcons.google,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Text("Sign in with Google",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  RoundedLoadingButton(
                  onPressed: (){
                    handleFacebookSignIn();
                  },
                  controller: facebookController,
                  successColor: Colors.blue,
                  width: MediaQuery.of(context).size.width * 0.80,
                  elevation: 0,
                  borderRadius: 25,
                  color: Colors.blue,
                  child: const Wrap(
                    children: [
                      Icon(
                        FontAwesomeIcons.facebook,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Text("Sign in with Facebook",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  ),
                  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                            (route) => false,
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ],
            )



          ],)
        )
      ),
      
    );
  }

  //Function to sign in using email
  Future handleEmailSignIn() async{
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();
    //Check internet
    if(ip.hasInternet == false){
      openSnackbar(context, "Check your internet connection", Colors.red);
      emailButtonController.reset();
      
    }
    else{
      //Try signing in using firebase
      await sp.signInWithEmail(_emailController.text, _passwordController.text).then((value) {
        if(sp.hasError==true){
          openSnackbar(context, sp.errorCode.toString(), Colors.red);
          emailButtonController.reset();
        }
        else{
          //Check if user exists
          sp.checkUserExists().then((value) async{
            if(value==true){
              //Save data locally, show success, go to home page
              await sp.getUserDataFromFirestore(sp.uid).then((value) => sp.saveDataToSharedPreferences().then((value) => sp.setSignIn().then((value){
                emailButtonController.success();
                handleAfterSignIn();
              })));
            }
            else{
              openSnackbar(context, "User does not exist", Colors.red);
              emailButtonController.reset();
            }
          });
        }
      } );

    }
  }
  //Function to sign in using Facebook
  Future handleFacebookSignIn() async{
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();
    if(ip.hasInternet == false){
      //Check internet
      openSnackbar(context, "Check your internet connection", Colors.red);
      facebookController.reset();
      
    }
    else{
      await sp.signInWithFacebook().then((value) {
        if(sp.hasError==true){
          openSnackbar(context, sp.errorCode.toString(), Colors.red);
          facebookController.reset();
        }
        else{
          sp.checkUserExists().then((value) async{
            if(value==true){
              await sp.getUserDataFromFirestore(sp.uid).then((value) => sp.saveDataToSharedPreferences().then((value) => sp.setSignIn().then((value){
                facebookController.success();
                handleAfterSignIn();
              })));
            }
            else{
              //If signing in using facebook for first time
              //Save data in firestore, locally, show success, go to home page
              sp.saveDataToFirestore().then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value){
                    facebookController.success();
                    handleAfterSignIn();
                  })));
            }
          });
        }
      } );
    }
  }

  //Function to sign in using Google
  Future handleGoogleSignIn() async{
    final sp = context.read<SignInProvider>();
    final ip = context.read<InternetProvider>();
    await ip.checkInternetConnection();
    if(ip.hasInternet == false){
      openSnackbar(context, "Check your internet connection", Colors.red);
      googleController.reset();
      
    }
    else{
      await sp.signInWithGoogle().then((value) {
        if(sp.hasError==true){
          openSnackbar(context, sp.errorCode.toString(), Colors.red);
          googleController.reset();
        }
        else{
          sp.checkUserExists().then((value) async{
            if(value==true){
              await sp.getUserDataFromFirestore(sp.uid).then((value) => sp.saveDataToSharedPreferences().then((value) => sp.setSignIn().then((value){
                googleController.success();
                handleAfterSignIn();
              })));
            }
            else{
              //If signing in using google for first time
              //Save data in firestore, locally, show success, go to home page
              sp.saveDataToFirestore().then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value){
                    googleController.success();
                    handleAfterSignIn();
                  })));
            }
          });
        }
      } );
    }
  }

  //Navigate to Home Screen after login
  handleAfterSignIn(){
    Future.delayed(const Duration(milliseconds: 1000)).then((value){
      nextScreenReplace(context, const HomeScreen());
    });
  }
  
}
