// import 'dart:js_interop_unsafe';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:login_app/provider/internet_provider.dart';
import 'package:login_app/provider/sign_in_provider.dart';
import 'package:login_app/screens/form.dart';
import 'package:login_app/screens/home_screen.dart';
import 'package:login_app/screens/login_screen.dart';
import 'package:login_app/utils/config.dart';
import 'package:login_app/utils/next_screen.dart';
import 'package:login_app/utils/snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();
  // final RoundedLoadingButtonController googleController = RoundedLoadingButtonController();
  final RoundedLoadingButtonController signupController = RoundedLoadingButtonController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                  Text("Sign up",
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
                    controller: _usernameController,
                    hintText: "Username",
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
                  

                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundedLoadingButton(
                  onPressed: (){
                    handleSignUp();
                  },
                  controller: signupController,
                  successColor: Colors.green,
                  width: MediaQuery.of(context).size.width * 0.80,
                  elevation: 0,
                  borderRadius: 25,
                  color: Colors.grey.shade800,
                  child: const Wrap(
                    children: [
                      
                      Text("Sign up to our App",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?"),
                      SizedBox(
                        width: 5,
                      ),
                    GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                    child: const Text(
                      "Login",
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
  void handleSignUp() async {
    //Get user data using text controllers
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    //Create account using sign in provider
    final sp = context.read<SignInProvider>();
    await sp.signUpWithEmail(email, password, username).then((value) {
      if(sp.hasError==true){
          openSnackbar(context, sp.errorCode.toString(), Colors.red);
          signupController.reset();
        }
        else{
          //Save data to the firestore, and locally, show success, go to home page
          sp.saveDataToFirestore().then((value) => sp
                  .saveDataToSharedPreferences()
                  .then((value) => sp.setSignIn().then((value){
                    signupController.success();
                    handleAfterSignIn();
                  })));
        }
    });

    
  }
  handleAfterSignIn(){
    Future.delayed(const Duration(milliseconds: 1000)).then((value){
      nextScreenReplace(context, const HomeScreen());
    });
  }
  
}
