import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/loading.dart';
import 'package:tg/components/custom_stream_builder.dart';
import 'package:tg/views/item_create.dart';
import 'package:tg/views/user_login.dart';

class ItemListPage extends StatefulWidget {
  // List<String> filtrar;
  const ItemListPage({
    super.key,
    /* required this.filtrar */
  });

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  bool logado = true;

  String ordenarDropdown = 'name';
  var ordenarSeta = false;
  var finalizados = false;
  var pendentes = false;
  String pesquisar = '';
  bool subCollectionsExist = false;
  late List<String> subColecoes;
  List<DocumentSnapshot> outrosDocumentos = [];
  late String caminho = 'users/${auth.currentUser!.uid}/items';

  void _updatePath(String novoCaminho) {
    setState(() {
      caminho = novoCaminho;
    });
  }

  @override
  void initState() {
    super.initState();
    if (auth.currentUser == null) {
      logado = false;
    }
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Itens"),
          actions: [
            //Pesquisa
            SizedBox(
              width: 200,
              child: TextField(
                decoration: const InputDecoration(
                  // labelText: 'Pesquisa',
                  hintText: 'Pesquisar',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    pesquisar = value;
                  });
                },
              ),
            ),

            //Login/Register/Logout
            PopupMenuButton<String>(
              icon: const Icon(Icons.person),
              itemBuilder: (BuildContext context) {
                return ['Logout'].map((e) {
                  return PopupMenuItem<String>(
                    value: e,
                    child: Text(e),
                  );
                }).toList();
              },
              onSelected: (String value) {
                switch (value) {
                  case 'Logout':
                    setState(() {
                      logado = false;
                      auth.signOut();
                    });
                    break;
                  default:
                }
              },
            ),
          ],
        ),
        body: !logado
            ? const Loading()
            : CustomStreamBuilder(caminho: caminho, updatePath: _updatePath),
        // StreamBuilder(
        //     stream: firestore
        //         .collection('users')
        //         .doc(auth.currentUser!.uid)
        //         // .where('uid', isEqualTo: auth.currentUser!.uid)
        //         .snapshots(),
        //     builder: (context, snapshot) {
        //       if (snapshot.connectionState == ConnectionState.waiting) {
        //         return const Loading();
        //       } else if (snapshot.hasError) {
        //         return Text(
        //           'Erro ao obter dados das itens: ${snapshot.error}',
        //         );
        //       } else if (auth.currentUser == null) {
        //         return const Text('Usuário não logado');
        //       } else if (!snapshot.hasData ||
        //           !snapshot.data!.exists /*|| snapshot.data!.docs.isEmpty*/) {
        //         return const Text('Não há itens a serem exibidas');
        //       }

        //       // String caminho = 'users/${auth.currentUser!.uid}/items';
        //       // return const Text("Ok");
        //       return CustomStreamBuilder(
        //           caminho: caminho, updatePath: Navigator.of(context));
        //     },
        //   ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ItemCreatePage(),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
