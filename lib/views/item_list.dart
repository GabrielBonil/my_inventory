import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/custom_stream_builder.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tg/views/item_create.dart';
import 'package:uuid/uuid.dart';
// import 'package:tg/components/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  late String caminho = 'users/${auth.currentUser!.uid}/MyInventory';
  String tituloPagina = 'MyInventory';
  List<String> historicoTitulos = ['MyInventory'];
  List<String> historicoNavegacao = [];
  bool returnable = false;
  final TextEditingController _subcollectionNameController =
      TextEditingController();

  void _updatePath(String novoCaminho) {
    setState(() {
      historicoNavegacao.add(caminho);
      caminho = novoCaminho;
      historicoTitulos.add(caminho.split('/').last);
    });
    updateTitle(caminho);
  }

  void voltar() {
    if (historicoNavegacao.isNotEmpty) {
      setState(() {
        caminho = historicoNavegacao.last;
      });
      historicoNavegacao.removeLast();
      updateTitle(caminho);
      historicoTitulos.removeLast();
    }
  }

  void _handlePathNavigate(int index) {

    var handleCaminho = "";

    if (index != historicoTitulos.length - 1) {
      // Remover itens do histórico até o índice especificado
      int itemsToRemove = historicoTitulos.length - 1 - index;
      for (var i = 0; i < itemsToRemove; i++) {
        handleCaminho = historicoNavegacao.last;
        historicoTitulos.removeLast();
        historicoNavegacao.removeLast();
      }

      setState(() {
        caminho = handleCaminho;
        updateTitle(caminho);
      });
    }
  }

  void home() {
    if (historicoNavegacao.isNotEmpty) {
      setState(() {
        caminho = 'users/${auth.currentUser!.uid}/MyInventory';
      });
      historicoNavegacao.clear();
      updateTitle(caminho);
      historicoTitulos = ['MyInventory'];
    }
  }

  void updateTitle(String caminho) {
    var newTitle = caminho.split('/');
    setState(() {
      tituloPagina = newTitle.last;
      if (historicoNavegacao.isNotEmpty) {
        returnable = true;
      } else {
        returnable = false;
      }
    });
  }

  void onSubcollectionCreated(String subcollectionName) {
    firestore.collection(caminho).doc(auth.currentUser!.uid).get().then((doc) {
      Map<String, String> places = {};

      if (doc.exists) {
        var existingPlaces = doc.get('places');
        if (existingPlaces is Map) {
          places = Map<String, String>.from(existingPlaces);
        }
      }

      if (!places.containsValue(subcollectionName)) {
        var uuid = const Uuid();
        var codigo = uuid.v4();

        places[codigo] = subcollectionName;

        firestore
            .collection(caminho)
            .doc(auth.currentUser!.uid)
            .set({'places': places});
        firestore
            .collection(caminho)
            .doc(auth.currentUser!.uid)
            .collection(codigo)
            .doc(auth.currentUser!.uid)
            .set({'places': {}});
      } else {
        Fluttertoast.showToast(
          msg: "Pasta $subcollectionName já existente",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  void onSubcollectionDeleted(String pasta) async {
    var doc =
        await firestore.collection(caminho).doc(auth.currentUser!.uid).get();
    late String placeToRemove;
    var places = doc.data();

    if (places != null) {
      places.forEach((key, value) {
        if (value == pasta) {
          placeToRemove = key;
        }
      });

      places.remove(placeToRemove);

      await firestore
          .collection(caminho)
          .doc(auth.currentUser!.uid)
          .update({'places': places});
    }
  }

  void onSubcollectionEdited(String novoNome, String nomeAtual) {
    String caminhoProvisorio = historicoNavegacao.last;

    setState(() {
      tituloPagina = novoNome;
    });

    firestore
        .collection(caminhoProvisorio)
        .doc(auth.currentUser!.uid)
        .get()
        .then((doc) {
      Map<String, String> places = doc.get('places');
      late String placeToEdit;

      places.forEach((key, value) {
        if (value == nomeAtual) {
          placeToEdit = key;
        }
      });

      if (!places.containsValue(novoNome)) {
        places[placeToEdit] = novoNome;

        firestore
            .collection(caminhoProvisorio)
            .doc(auth.currentUser!.uid)
            .set({'places': places});
      }
    });
  }

  AlertDialog _buildExitDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Please confirm'),
      content: const Text('Do you want to exit the app?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    updateTitle(caminho);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (historicoNavegacao.isNotEmpty) {
            voltar();
            return false;
          } else {
            bool? exitResult = await showDialog(
              context: context,
              builder: (context) => _buildExitDialog(context),
            );
            return exitResult ?? false;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(tituloPagina),
                // if (returnable)
                //   IconButton(
                //     onPressed: () => {
                //       showGeneralDialog(
                //         context: context,
                //         pageBuilder: (ctx, a1, a2) {
                //           return Container();
                //         },
                //         transitionBuilder: (ctx, a1, a2, child) {
                //           var curve = Curves.easeInOut.transform(a1.value);
                //           return Transform.scale(
                //             scale: curve,
                //             child: AlertDialog(
                //               title: Row(
                //                 mainAxisAlignment:
                //                     MainAxisAlignment.spaceBetween,
                //                 children: [
                //                   const Text("Editar Pasta"),
                //                   IconButton(
                //                     onPressed: () {
                //                       Navigator.of(context).pop();
                //                     },
                //                     icon: const Icon(Icons.close),
                //                   ),
                //                 ],
                //               ),
                //               content: TextField(
                //                 controller: _subcollectionNameController,
                //                 decoration: const InputDecoration(
                //                   labelText: 'Novo Nome',
                //                 ),
                //               ),
                //               actionsPadding: const EdgeInsets.only(
                //                   left: 16, right: 16, bottom: 20),
                //               actions: <Widget>[
                //                 Row(
                //                   mainAxisAlignment:
                //                       MainAxisAlignment.spaceBetween,
                //                   children: [
                //                     TextButton(
                //                       onPressed: () {
                //                         Navigator.pop(context);
                //                         onSubcollectionDeleted(tituloPagina);
                //                         _subcollectionNameController.clear();
                //                       },
                //                       child: const Text(
                //                         "Deletar",
                //                         style: TextStyle(
                //                           color: Colors.red,
                //                           fontSize: 17,
                //                         ),
                //                       ),
                //                     ),
                //                     TextButton(
                //                       onPressed: () {
                //                         String subcollectionName =
                //                             _subcollectionNameController.text;
                //                         if (subcollectionName.isNotEmpty) {
                //                           Navigator.pop(context);
                //                           onSubcollectionEdited(
                //                               subcollectionName, tituloPagina);
                //                         }
                //                         _subcollectionNameController.clear();
                //                       },
                //                       child: const Text(
                //                         "Editar",
                //                         style: TextStyle(
                //                           color: Colors.red,
                //                           fontSize: 17,
                //                         ),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ],
                //             ),
                //           );
                //         },
                //         transitionDuration: const Duration(milliseconds: 300),
                //       )
                //     },
                //     icon: const Icon(Icons.edit),
                //   ),
              ],
            ),
            leading: !returnable
                ? null
                : IconButton(
                    onPressed: voltar,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            actions: [
              //Home
              if (returnable)
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
            historicoTitulos: historicoTitulos,
            handlePathNavigate: _handlePathNavigate,
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
                  MaterialPageRoute(
                    builder: (context) => ItemCreatePage(caminho: caminho),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
