import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/textcomposer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/chatmessage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _currentUser;
  String? _lastAuthenticatedUserId;
  static const String _googleWebClientId =
      '103811360320-u42ificivtfmo8frg59oag5e992vdopv.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _checkSignIn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        checkUser();
      }
    });
  }

  Map<String, dynamic> message = {};

  //Realizar login com o Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      // Inicializar o Google Sign-In com o client ID do web
      await googleSignIn.initialize(serverClientId: _googleWebClientId);
      // Iniciar o fluxo de autenticação do Google
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        // Usuário cancelou o fluxo de login
        return null;
      }

      // Obter os detalhes de autenticação do Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

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

  Future<void> checkUser() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Usuário não autenticado. Iniciando login com o Google...',
          ),
        ),
      );
      debugPrint("Usuário não autenticado. Iniciando login com o Google...");
      await signInWithGoogle();
    }
  }

  Future<void> _checkSignIn() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    _lastAuthenticatedUserId = _currentUser?.uid;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user != null) {
        _lastAuthenticatedUserId = user.uid;
      }
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  Future<void> _sendMessage({XFile? image, String? text}) async {
    await checkUser();

    if (_currentUser == null) return;

    message = {
      'uid': _currentUser!.uid,
      'username': _currentUser!.displayName,
      'userPhotoUrl': _currentUser!.photoURL,
      'timestamp': FieldValue.serverTimestamp(),
    };

    _currentUser!.displayName != null
        ? message['senderName'] = _currentUser!.displayName
        : message['senderName'] = 'Usuário Anônimo';

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
        title: Text(
          _currentUser?.displayName == null
              ? 'Chat Online'
              : 'Olá, ${_currentUser?.displayName}!',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade300,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .orderBy('timestamp', descending: true)
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
                    return ChatMessage(
                      //text: data?['text'] ?? '',
                      isMine:
                          data?['uid'] ==
                          (_currentUser?.uid ?? _lastAuthenticatedUserId),
                      data: data ?? {},
                    );
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
