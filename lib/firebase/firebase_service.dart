import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseMethod {

  uploadUserInfo(userInfoMap) async{
    FirebaseFirestore.instance.collection("users").add(userInfoMap);
  }

  createChatRoom(String chatRoomId, chatRoomMap) async{
    await Firebase.initializeApp();
    FirebaseFirestore.instance
        .collection("ChatRoom")
        .doc(chatRoomId)
        .set(chatRoomMap)
        .catchError((e) {
      print(e.toString());
    });
  }

  createUser(String userEmail, userInfo) async{
    await Firebase.initializeApp();
    FirebaseFirestore.instance
        .collection("User")
        .doc(userEmail)
        .set(userInfo)
        .catchError((e) {
      print(e.toString());
    });
  }

  getAllUser() async {
    await Firebase.initializeApp();
    return await FirebaseFirestore.instance
        .collection("User")
        .snapshots();
  }



  addConversationMessage(String chatRoomId, messageMap) async{
    await Firebase.initializeApp();
    FirebaseFirestore.instance
        .collection("ChatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .add(messageMap)
        .catchError((e) {
      print(e.toString());
    });
  }

  getConversationMessage(String chatRoomId) async {
    await Firebase.initializeApp();
    return await FirebaseFirestore.instance
        .collection("ChatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }



}