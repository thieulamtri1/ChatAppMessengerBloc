import 'package:chat_app_messenger/firebase/firebase_service.dart';
import 'package:chat_app_messenger/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'conversation_screen.dart';

class ChatCard extends StatefulWidget {
  String friendImage = "";
  String friendName = "";
  String friendEmail = "";
  String myId = "";
  String myEmail = "";
  String friendId = "";
  String friendToken = "";
  bool isNewMessage;

  ChatCard({
    this.myId,
    this.myEmail,
    this.friendId,
    this.friendName,
    this.friendEmail,
    this.friendImage,
    this.friendToken,
    this.isNewMessage,
  });

  @override
  _ChatCardState createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  final user = FirebaseAuth.instance.currentUser;
  FirebaseMethod firebaseMethod = FirebaseMethod();
  String chatRoomId = "";



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        createChatRoom();
        if(widget.isNewMessage == true){
          setState(() {
            widget.isNewMessage = false;
          });
        }

        MyApp.storage.setItem("emailChatting", widget.friendEmail);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ConversationScreen(
                      myId: widget.myId,
                      chatRoomId: chatRoomId,
                      friendEmail: widget.friendEmail,
                      friendName: widget.friendName,
                      friendImage: widget.friendImage,
                      friendToken: widget.friendToken,
                    )));
      },
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.friendImage),
                    maxRadius: 30,
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.friendName,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: widget.isNewMessage == true ? FontWeight.bold : null,
                              fontSize: widget.isNewMessage == true ? 17 : null,
                            ),
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          Text(
                            widget.friendEmail,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: widget.isNewMessage == true ? FontWeight.bold : null,
                              fontSize: widget.isNewMessage == true ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  createChatRoom() {
    List<String> users = [widget.myEmail, widget.friendEmail];
    chatRoomId = createChatRoomId(widget.myId, widget.friendId);
    Map<String, dynamic> chatRoom = {
      "users": users,
    };
    firebaseMethod.createChatRoom(chatRoomId, chatRoom);
  }

  createChatRoomId(myId, friendId) {
    String id;
    BigInt a = BigInt.parse(myId);
    BigInt b = BigInt.parse(friendId);
    if (a > b) {
      // swap two values
      var temp = friendId;
      friendId = myId;
      myId = temp;
      id = myId.toString() + " - " + friendId.toString();
    } else {
      id = myId.toString() + " - " + friendId.toString();
    }
    return id;
  }
}
