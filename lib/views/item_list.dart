import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/my_items.dart';
import 'package:tg/components/my_list_view.dart';
import 'package:tg/components/loading.dart';

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

  @override
  void initState() {
    super.initState();
    if (auth.currentUser == null) {
      logado = false;
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items"),
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
          !logado
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.person),
                  itemBuilder: (BuildContext context) {
                    return ['Login', 'Cadastro'].map((e) {
                      return PopupMenuItem<String>(
                        value: e,
                        child: Text(e),
                      );
                    }).toList();
                  },
                  onSelected: (String value) {
                    switch (value) {
                      case 'Login':
                        setState(() {
                          Navigator.of(context).pushNamed('/user_login');
                        });
                        break;
                      case 'Cadastro':
                        setState(() {
                          Navigator.of(context).pushNamed('/user_register');
                        });
                        break;
                      default:
                    }
                  },
                )
              : PopupMenuButton<String>(
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
                          auth.signOut();
                        });
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/item_list',
                          ModalRoute.withName('/'),
                        );
                        break;
                      default:
                    }
                  },
                ),
        ],
      ),
      body: !logado
          ? const Text('Usuário não logado')
          : StreamBuilder(
              stream: firestore
                  .collection('users')
                  .doc(auth.currentUser!.uid)
                  // .where('uid', isEqualTo: auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loading();
                } else if (snapshot.hasError) {
                  return Text(
                    'Erro ao obter dados das itens: ${snapshot.error}',
                  );
                } else if (auth.currentUser == null) {
                  return const Text('Usuário não logado');
                } else if (!snapshot.hasData ||
                    !snapshot.data!.exists /*|| snapshot.data!.docs.isEmpty*/) {
                  return const Text('Não há itens a serem exibidas');
                }

                // return const Text("Ok");
                return StreamBuilder(
                  stream: firestore
                      .collection('users')
                      .doc(auth.currentUser!.uid)
                      .collection('items')
                      .snapshots(),
                  // stream: snapshot.data!.data()!['items'],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loading();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Erro ao obter dados dos itens: ${snapshot.error}',
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('Nenhum item encontrado.');
                    }

                    //Criando todos os documentos (exceto "collections"):
                    for (var doc in snapshot.data!.docs) {
                      // Se o ID do documento não for "collections", adiciona à lista
                      if (doc.id != 'collections') {
                        outrosDocumentos.add(doc);
                      }
                    }

                    // Verifica se o documento "collections" está presente
                    if (snapshot.data!.docs
                        .any((doc) => doc.id == 'collections')) {
                      var collectionsDoc = snapshot.data!.docs
                          .firstWhere((element) => element.id == 'collections');
                      Map<String, dynamic> collectionsData =
                          collectionsDoc.data();

                      // Verifica se há o documento "collections" e se tem subcoleções
                      if (collectionsData.isNotEmpty) {
                        subCollectionsExist = true;
                        subColecoes = collectionsData['places'].cast<String>();
                      }
                    }

                    return ListView(
                      children: [
                        if (subCollectionsExist)
                          GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              ...subColecoes
                                  .map(
                                    (e) => Container(
                                      color: Colors.blue,
                                      child: Center(
                                        child: Text(e.toString()),
                                      ),
                                    ),
                                  ).toList(),
                            ],
                          ),
                        ...outrosDocumentos
                            .map((e) => MyItems(document: e))
                            .toList(),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/item_create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
