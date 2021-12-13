import 'package:chat_app_messenger/event/login_event.dart';
import 'package:chat_app_messenger/state/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogInLogOutBloc extends Bloc<LogInLogOutEvent, LoginState> {
  final googleSignIn = GoogleSignIn();
  bool _isSigningIn;

  LogInLogOutBloc(initialState) : super(initialState) {
    on<Login>(onLogin);
    on<Logout>(onLogout);
  }

  Future onLogin(Login event, Emitter<LoginState> emit) async {
    _isSigningIn = true;
    emit(LoginState(_isSigningIn));
    print("Tri dep trai");
    final user = await googleSignIn.signIn();
    if (user == null) {
      _isSigningIn = false;
      return;
    } else {
      final googleAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      _isSigningIn = false;

      emit(LoginState(_isSigningIn));
    }
  }

  void onLogout(Logout event, Emitter<LoginState> emit) async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
  }


}
