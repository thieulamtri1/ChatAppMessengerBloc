import 'package:chat_app_messenger/bloc/login_bloc.dart';
import 'package:chat_app_messenger/chat/chat_screen.dart';
import 'package:chat_app_messenger/provider/google_sign_in.dart';
import 'package:chat_app_messenger/state/login_state.dart';
import 'package:chat_app_messenger/widget/background_painter.dart';
import 'package:chat_app_messenger/widget/sign_up_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LogInLogOutBloc, LoginState>(
        builder: (context, state){
          return  StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (state.isLogin) {
                print("State1: " + state.isLogin.toString());
                return buildLoading();
              } else if (snapshot.hasData) {
                print("State2: " + state.isLogin.toString());
                return ChatScreen();
              } else {
                print("State3: " + state.isLogin.toString());
                return SignUpWidget();
              }
            },
          );
        }
      ),
    );
  }

  Widget buildLoading() => Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: BackgroundPainter()),
          Center(child: CircularProgressIndicator()),
        ],
      );
}
