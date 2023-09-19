import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/custom_stream_builder.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tg/views/item_create.dart';
// import 'package:tg/components/loading.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  bool subCollectionsExist = false;
  late List<String> subColecoes;
  List<DocumentSnapshot> outrosDocumentos = [];
  late String caminho = 'users/${auth.currentUser!.uid}/items';
  List<String> historicoNavegacao = [];
  final TextEditingController _subcollectionNameController =
      TextEditingController();

  void _updatePath(String novoCaminho) {
    setState(() {
      historicoNavegacao.add(caminho);
      caminho = novoCaminho;
    });
  }

  void voltar() {
    if (historicoNavegacao.isNotEmpty) {
      setState(() {
        caminho = historicoNavegacao.last;
      });
      historicoNavegacao.removeLast();
    }
  }

  void home() {
    if (historicoNavegacao.isNotEmpty) {
      setState(() {
        caminho = 'users/${auth.currentUser!.uid}/items';
      });
      historicoNavegacao.clear();
    }
  }

  void onSubcollectionCreated(String subcollectionName) {
    firestore.collection(caminho).doc('collections').get().then((doc) {
      List<dynamic> places = [];

      if (doc.exists) {
        places = doc.get('places');
      }

      if (!places.contains(subcollectionName)) {
        places.add(subcollectionName);
        firestore
            .collection(caminho)
            .doc('collections')
            .set({'places': places});
        firestore
            .collection(caminho)
            .doc('collections')
            .collection(subcollectionName)
            .doc('collections')
            .set({'places': []});
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Itens"),
          leading: IconButton(
            onPressed: voltar,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            //Home
            IconButton(
              onPressed: home,
              icon: const Icon(Icons.home_rounded),
            ),
            //Logout
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
                      auth.signOut();
                    });
                    break;
                  default:
                }
              },
            ),
          ],
        ),
        body: CustomStreamBuilder(
          caminho: caminho,
          updatePath: _updatePath,
        ),
        floatingActionButton: SpeedDial(
          backgroundColor: Colors.black,
          overlayColor: Colors.black,
          overlayOpacity: 0.4,
          spacing: 12,
          spaceBetweenChildren: 12,
          // icon: Icons.add,
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.folder),
              label: 'Pasta',
              onTap: () => {
                showGeneralDialog(
                  context: context,
                  pageBuilder: (ctx, a1, a2) {
                    return Container();
                  },
                  transitionBuilder: (ctx, a1, a2, child) {
                    var curve = Curves.easeInOut.transform(a1.value);
                    return Transform.scale(
                      scale: curve,
                      child: AlertDialog(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Criar Pasta"),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        content: TextField(
                          controller: _subcollectionNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Pasta',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              String subcollectionName =
                                  _subcollectionNameController.text;
                              if (subcollectionName.isNotEmpty) {
                                Navigator.pop(context);
                                onSubcollectionCreated(subcollectionName);
                              }
                              _subcollectionNameController.clear();
                            },
                            child: const Text(
                              "Criar",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                )
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.add),
              label: 'Item',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ItemCreatePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
