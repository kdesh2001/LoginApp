import 'package:flutter/material.dart';
import 'package:login_app/provider/sign_in_provider.dart';
import 'package:login_app/screens/login_screen.dart';
import 'package:login_app/utils/next_screen.dart';
import 'package:provider/provider.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future getData() async{
    final sp = context.read<SignInProvider>();
    sp.getDataFromSharedPreferences();
  }
  @override
  void initState(){
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.read<SignInProvider>();
    //Display user info
    return Scaffold(
      body: Center(
        child:
            Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage("${sp.imageUrl}"),
              ),
              const SizedBox(
                height: 20,
              ),
              Text("Welcome ${sp.name}!", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
              const SizedBox(
                height: 20,
              ),
              Text("${sp.email}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),),
              const SizedBox(
                height: 20,
              ),
              Text("You have logged in using ${sp.provider}.", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),),
              const SizedBox(
                height: 30,
              ),
              ElevatedButton(onPressed: (){
                sp.userSignOut(); //Handle sign out
                nextScreenReplace(context, const LoginScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
              ),
               child: const Text("Sign out", style: TextStyle(color: Colors.white),))
            ],
          ),
          
      )
    );
  }
}