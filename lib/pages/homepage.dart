import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'textcomposer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _sendMessage({String? text, File? image}) async {
    Map<String, dynamic> message = {};

    if (text != null) {
      message['text'] = text;
    }
    if (image != null) {
      final storageRef = FirebaseStorage.instance.ref();
      final uploadTask = storageRef
          .child('images')
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      String imageUrl = await snapshot.ref.getDownloadURL();
      message['image'] = imageUrl;
    }
    if (message.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc()
          .set(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Online'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(child: CircularProgressIndicator());
                  default:
                    List<DocumentSnapshot> documents = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true, //inverter ordem das mensagens
                      itemBuilder: (context, index) {
                        final data = documents[index].data() as Map<String, dynamic>?;
                        return ListTile(
                          title: Text(data?['text'] ?? ''),
                        );
                      },
                    );
                }
              },
            ),
            
          ),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
