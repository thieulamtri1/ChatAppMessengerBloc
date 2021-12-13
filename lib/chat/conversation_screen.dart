import 'dart:convert';
import 'dart:io';

import 'package:chat_app_messenger/api/firebase_api.dart';
import 'package:chat_app_messenger/firebase/firebase_service.dart';
import 'package:chat_app_messenger/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'conversation_appBar.dart';
import 'package:http/http.dart' as http;

class ConversationScreen extends StatefulWidget {
  final String chatRoomId;
  final String friendName;
  final String friendEmail;
  final String friendImage;
  final String friendToken;
  final String myId;

  ConversationScreen({
    this.chatRoomId,
    this.friendName,
    this.friendEmail,
    this.friendImage,
    this.friendToken,
    this.myId,
  });

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  FirebaseMethod firebaseMethod = FirebaseMethod();
  TextEditingController messageInput = TextEditingController();
  Stream chatMessageStream;
  String prevUserId;
  final user = FirebaseAuth.instance.currentUser;
  String myImage = "";
  String myEmail = "";
  final storage = FirebaseStorage.instance;
  UploadTask task;
  File file;

  @override
  void initState() {
    getConversationMessage();
    myImage = user.photoURL;
    myEmail = user.email;
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print("Thoát conversation screen");
    MyApp.storage.setItem("emailChatting", "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConversationAppBar(
          image: widget.friendImage,
          name: widget.friendName,
          phone: widget.friendEmail),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(),
          ),
          SizedBox(height: 20),
          sendMessageArea(),
        ],
      ),
    );
  }

  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result == null) return;
    final path = result.files.single.path;
    print("PATH: " + path);
    setState(() => file = File(path));
    uploadFile();
  }

  Future uploadFile() async {
    if (file == null) return;

    String fileName = file.path.split('/').last;
    final destination = '${user.email}/$fileName';

    task = FirebaseApi.uploadFile(destination, file);
    setState(() {});

    if (task == null) return;

    final snapshot = await task.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();

    print('Download-Link: $urlDownload');
    sendMessage(urlDownload);
  }

  sendMessageArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      height: 70,
      color: Colors.grey[300],
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: selectFile,
            icon: Icon(Icons.image),
          ),
          Expanded(
            child: TextField(
              controller: messageInput,
              decoration: InputDecoration(
                hintText: 'Send a message..',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.only(left: 15, bottom: 11, top: 11, right: 15),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25,
            color: Theme.of(context).primaryColor,
            onPressed: () {
              sendMessage("");
            },
          ),
        ],
      ),
    );
  }

  ChatMessageList() {
    return StreamBuilder(
      stream: chatMessageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                reverse: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  final bool isMe =
                      snapshot.data.docs[index]["sendBy"] == widget.myId;
                  final bool isSameUser =
                      prevUserId == snapshot.data.docs[index]["sendBy"];
                  prevUserId = snapshot.data.docs[index]["sendBy"];
                  return _chatBubble(snapshot.data.docs[index]["message"], isMe,
                      isSameUser, snapshot.data.docs[index]["imageUrl"]);
                },
              )
            : Container();
      },
    );
  }

  getConversationMessage() async {
    await firebaseMethod
        .getConversationMessage(widget.chatRoomId)
        .then((value) {
      setState(() {
        chatMessageStream = value;
      });
    });
  }

  static Future<bool> sendFcmMessage(
      String title, String message, token, email) async {
    try {
      var url = 'https://fcm.googleapis.com/fcm/send';
      var header = {
        "Content-Type": "application/json",
        "Authorization":
            "key=AAAANXJz4sg:APA91bGJatnhKYvjCPoLW3S_UY-Q_uZxssiYcDQXKzjjMwuv5HGMKJFq26sfxYVIaKzsrIDQ2cIfR17rHsQYKCKpORGC9xRjjR9tkPLfLfnS6srv6HI12fW15TQinR7z31732L8cyJ9o",
      };
      var request = {
        'notification': {'title': title, 'body': message},
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'email': email,
        },
        'to': token,
      };

      var response = await http.post(Uri.parse(url),
          headers: header, body: json.encode(request));
      return true;
    } catch (e, s) {
      print(e);
      return false;
    }
  }

  sendMessage(imageUrl) {
    print(messageInput.text);
    if (messageInput.text.isNotEmpty || imageUrl != "") {
      Map<String, dynamic> messageMap = {
        "message": messageInput.text,
        "sendBy": widget.myId,
        "time": DateTime.now().millisecondsSinceEpoch,
        "imageUrl": imageUrl,
      };
      firebaseMethod.addConversationMessage(widget.chatRoomId, messageMap);
      sendFcmMessage(widget.friendName + " đã gửi tin nhắn cho bạn", messageInput.text == "" ?  "[Picture]" : messageInput.text  , widget.friendToken, myEmail);
      messageInput.text = "";

    }
  }

  _chatBubble(String text, bool isMe, bool isSameUser, String imageUrl) {
    if (isMe) {
      return Padding(
        padding: EdgeInsets.only(right: 20),
        child: Column(
          children: <Widget>[
            imageUrl == ""
                ? Container(
                    alignment: Alignment.topRight,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 300,
                      height: 200,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      // padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(20),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(
                            imageUrl,
                          ),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      // child: Text(
                      //   text,
                      //   style: TextStyle(
                      //     color: Colors.black54,
                      //   ),
                      // ),
                    ),
                  ),
            !isSameUser
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.7),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundImage: NetworkImage(myImage == null
                              ? "https://huyhoanhotel.com/wp-content/uploads/2016/05/765-default-avatar.png"
                              : myImage),
                        ),
                      ),
                    ],
                  )
                : Container(
                    child: null,
                  ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: 20),
        child: Column(
          children: <Widget>[
            imageUrl == ""
                ? Container(
                    alignment: Alignment.topLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(
                            imageUrl,
                          ),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 300,
                      height: 200,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      // padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                          bottomLeft: Radius.circular(5),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(
                            imageUrl,
                          ),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      // child: Text(
                      //   text,
                      //   style: TextStyle(
                      //     color: Colors.black54,
                      //   ),
                      // ),
                    ),
                  ),
            !isSameUser
                ? Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundImage: NetworkImage(widget.friendImage ==
                                  null
                              ? "https://huyhoanhotel.com/wp-content/uploads/2016/05/765-default-avatar.png"
                              : widget.friendImage),
                        ),
                      ),
                    ],
                  )
                : Container(
                    child: null,
                  ),
          ],
        ),
      );
    }
  }
}
