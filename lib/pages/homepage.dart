import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'textcomposer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _currentUser;
  static const String _googleWebClientId =
      '103811360320-u42ificivtfmo8frg59oag5e992vdopv.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _checkSignIn();
  }

  //Realizar login com o Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: _googleWebClientId);

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        // Usuário cancelou o fluxo de login
        return null;
      }

      // Obter os detalhes de autenticação do Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('O Google Sign-In não retornou um ID token.');
      }

      // Criar uma credencial do Firebase com o token de acesso do Google
      final credential = GoogleAuthProvider.credential(
        //accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Fazer login no Firebase com a credencial do Google
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e, st) {
      debugPrint('Erro ao autenticar com o Google: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<void> _checkSignIn() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      print("Usuário não autenticado. Iniciando login com o Google...");
      await signInWithGoogle();
    }

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<void> _sendMessage({XFile? image, String? text}) async {
    Map<String, dynamic> message = {};

    if (text != null) {
      message['text'] = text;
    } else {
      final storageRef = FirebaseStorage.instance.ref();
      final uploadTask = storageRef
          .child('images')
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(File(image!.path));
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
      appBar: AppBar(
        title: const Text('Chat Online', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar mensagens: ${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('Aguardando dados...'));
                }

                final documents = snapshot.data!.docs;
                if (documents.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma mensagem encontrada.'),
                  );
                }

                return ListView.builder(
                  itemCount: documents.length,
                  reverse: true, //inverter ordem das mensagens
                  itemBuilder: (context, index) {
                    final data =
                        documents[index].data() as Map<String, dynamic>?;
                    return ListTile(title: Text(data?['text'] ?? ''));
                  },
                );
              },
            ),
          ),
          SafeArea(child: TextComposer(_sendMessage)),
        ],
      ),
    );
  }
}
