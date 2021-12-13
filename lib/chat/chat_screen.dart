import 'package:chat_app_messenger/bloc/dark_mode_bloc.dart';
import 'package:chat_app_messenger/bloc/login_bloc.dart';
import 'package:chat_app_messenger/event/dark_mode_event.dart';
import 'package:chat_app_messenger/event/login_event.dart';
import 'package:chat_app_messenger/state/dark_mode_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:chat_app_messenger/firebase/firebase_service.dart';
import 'package:chat_app_messenger/provider/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../provider/dark_mode.dart';
import 'chat_card.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController searchInput = TextEditingController();
  Stream chatRoomStream;
  FirebaseMethod firebaseMethod = new FirebaseMethod();
  final user = FirebaseAuth.instance.currentUser;
  String myInfo = "";
  String myId = "";
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String title = "";
  String token = "";
  bool isNewMessage = false;
  String emailWithNewMessage = "";

  @override
  void initState() {
    // createUser();
    getTokenAndCreateUser();
    getUser();
    getNotification();
  }

  getTokenAndCreateUser() async {
    await Firebase.initializeApp();
    token = await FirebaseMessaging.instance.getToken();
    print("fcmToken: " + token);
    createUser();
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    RemoteNotification notification = message.notification;
    print('Handling a background message ${message.messageId}');
    print(message.notification);
    print(message.data);
  }

  Future showNotification(NotiTitle, NotiBody) async {
    var androidDetails = new AndroidNotificationDetails(
        "channelId", "Local Notification", "channelDescription",
        importance: Importance.high);
    var iosDetails = new IOSNotificationDetails();
    var generalNotification =
        new NotificationDetails(android: androidDetails, iOS: iosDetails);
    await flutterLocalNotificationsPlugin.show(
        0, NotiTitle, NotiBody, generalNotification);
  }

  getNotification() {
    var initialzationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initialzationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      print("Notification title: " + notification.title);
      print("Notification body: " + notification.body);
      print("Notification data: " + message.data['email']);

      setState(() {
        title = notification.title;
        if (message.data['email'] == MyApp.storage.getItem("emailChatting")) {
          emailWithNewMessage = "";
        } else {
          emailWithNewMessage = message.data['email'];
        }
      });
      if (message.data['email'] != MyApp.storage.getItem("emailChatting")) {
        showNotification(notification.title, notification.body);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      print("Notification title: " + notification.title);
      print("Notification body: " + notification.body);
      setState(() {
        title = notification.title;
      });
    });
  }

  createUser() {
    String myInfo = user.providerData.toString();
    String myIdUnCut = myInfo.substring(
      myInfo.lastIndexOf(':') + 1,
    );
    myId = myIdUnCut.replaceAll(new RegExp(r'[^0-9]'), '');
    Map<String, String> userDataMap = {
      "userName": user.displayName,
      "userEmail": user.email,
      "userId": myId,
      "userImage": user.photoURL,
      "fcmToken": token,
    };
    firebaseMethod.createUser(user.email, userDataMap);
  }

  @override
  Widget build(BuildContext context) {
    final darkModeBloc = BlocProvider.of<DarkModeBloc>(context);
    final loginLogoutBloc = BlocProvider.of<LogInLogOutBloc>(context, listen: false);
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Chat ",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Spacer(),
                    SizedBox(width: 20),
                    BlocBuilder<DarkModeBloc, DarkModeState>(
                      builder: (context, state){
                        return Switch(
                          value: state.darkMode,
                          onChanged: (bool val) {
                            darkModeBloc.add(ChangeMode());
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeColor: Colors.green,
                        );
                      }
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.black),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.grey),
                      ),
                      onPressed: () {
                        loginLogoutBloc.add(Logout());
                      },
                      child: Text('Logout'),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                controller: searchInput,
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search),
                    color: Colors.grey.shade400,
                    iconSize: 25,
                    onPressed: () {},
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade100)),
                ),
              ),
            ),
            showChatRoomList(),
          ],
        ),
      ),
    );
  }

  Widget showChatRoomList() {
    return StreamBuilder(
      stream: chatRoomStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  return user.email != snapshot.data.docs[index]["userEmail"]
                      ? ChatCard(
                          isNewMessage: emailWithNewMessage ==
                                  snapshot.data.docs[index]["userEmail"]
                              ? true
                              : false,
                          myId: myId,
                          myEmail: user.email,
                          friendId: snapshot.data.docs[index]["userId"],
                          friendName: snapshot.data.docs[index]["userName"],
                          friendEmail: snapshot.data.docs[index]["userEmail"],
                          friendToken: snapshot.data.docs[index]["fcmToken"],
                          friendImage: snapshot.data.docs[index]["userImage"] ==
                                  null
                              ? "https://huyhoanhotel.com/wp-content/uploads/2016/05/765-default-avatar.png"
                              : snapshot.data.docs[index]["userImage"],
                        )
                      : SizedBox();
                })
            : Container();
      },
    );
  }

  getUser() async {
    await firebaseMethod.getAllUser().then((value) {
      setState(() {
        chatRoomStream = value;
      });
    });
  }
}
