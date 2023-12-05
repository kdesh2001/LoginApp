import 'package:flutter/material.dart';
import 'package:login_app/provider/sign_in_provider.dart';
import 'package:login_app/screens/home_screen.dart';
import 'package:login_app/screens/login_screen.dart';
import 'package:login_app/utils/config.dart';
import 'package:provider/provider.dart';
import 'dart:async';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState(){
    final sp = context.read<SignInProvider>();
    super.initState();
    Timer(const Duration(seconds: 2),(){
      sp.isSignedIn == false ? Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginScreen())):
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Image(
            image: AssetImage(Config.app_icon),
            height: 80,
            width: 80,
          )
        ),
        ),
    );
  }
}