import 'package:chat_app_messenger/event/dark_mode_event.dart';
import 'package:chat_app_messenger/state/dark_mode_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DarkModeBloc extends Bloc<DarkModeEvent, DarkModeState>{
  bool darkMode;

  DarkModeBloc(DarkModeState initialState) : super(initialState){
    darkMode = initialState.darkMode;
    on<ChangeMode>(_onChangeMode);
  }

  void _onChangeMode(ChangeMode event, Emitter<DarkModeState> emit) {
    darkMode = !darkMode;
    emit(DarkModeState(darkMode));
  }
}