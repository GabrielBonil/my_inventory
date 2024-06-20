import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/custom_stream_builder.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tg/views/item_create.dart';
import 'package:uuid/uuid.dart';
// import 'package:tg/components/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tg/components/destination_selector.dart';

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
  bool longPress = false;
  int selecionado = 0;
  String nomeEditado = '';
  List<String> selected = [];

  void _longPressActive(String key) {
    setState(() {
      longPress = true;
    });
    incrementSelecionado(key);
  }

  void handleSelected() {
    if (selecionado == 0) {
      selected = [];
    }
  }

  void incrementSelecionado(String key) {
    setState(() {
      selecionado += 1;
      selected.add(key);
    });
  }

  void decrementSelecionado(String key) {
    setState(() {
      selected.remove(key);
      selecionado -= 1;
      if (selecionado == 0) {
        longPress = false;
      }
    });
  }

  void _updatePath(String novoCaminho) {
    setState(() {
      historicoNavegacao.add(caminho);
      caminho = novoCaminho;
      // historicoTitulos.add(caminho.split('/').last);
      var temporaryKey = caminho.split('/').last;
      firestore
          .collection(historicoNavegacao.last)
          .doc(auth.currentUser!.uid)
          .get()
          .then((doc) {
        Map<String, String> places = {};

        if (doc.exists) {
          var existingPlaces = doc.get('places');
          if (existingPlaces is Map) {
            places = Map<String, String>.from(existingPlaces);
          }
        }
        if (places.containsKey(temporaryKey)) {
          String? value = places[temporaryKey];
          if (value != null) {
            historicoTitulos.add(value);
          }
        }
      });
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
    if (longPress){
      return;
    }
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
    var temporaryKey = caminho.split('/').last;
    String newTitle = caminho.split('/').last;
    // print(newTitle);
    //var newTitle = caminho.split('/');
    if (!historicoNavegacao.isNotEmpty) {
      setState(() {
        tituloPagina = newTitle;
      });
    } else {
      firestore
          .collection(historicoNavegacao.last)
          .doc(auth.currentUser!.uid)
          .get()
          .then((doc) {
        Map<String, String> places = {};

        if (doc.exists) {
          var existingPlaces = doc.get('places');
          if (existingPlaces is Map) {
            places = Map<String, String>.from(existingPlaces);
          }
        }
        if (places.containsKey(temporaryKey)) {
          String? value = places[temporaryKey];
          if (value != null) {
            setState(() {
              newTitle = value;
              tituloPagina = newTitle;
            });
          }
        }
      });
    }

    setState(() {
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

        //Adicionando na lista de lugares (do documento)
        firestore
            .collection(caminho)
            .doc(auth.currentUser!.uid)
            .set({'places': places});
        //Adicionando a collection o uid, criando o documento com o Authcode e a lista de places desse lugar
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

  void onSubcollectionsMoved(List<String> selectedUids) async {
  // Abrir o modal de seleção de destino
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return DestinationSelector(
        selectedUids: selectedUids,
        onDestinationSelected: (String destinationPath) {
          moveSubcollections(selectedUids, destinationPath);
        },
      );
    },
  );
}

void moveSubcollections(List<String> selectedUids, String destinationPath) async {
  var doc = await firestore.collection(caminho).doc(auth.currentUser!.uid).get();
  var places = doc.get('places');

  Map<String, String> movedPlaces = {};

  if (places != null) {
    for (String uid in selectedUids) {
      if (places.containsKey(uid)) {
        movedPlaces[uid] = places[uid];
        places.remove(uid);
      }
    }

    await firestore.collection(caminho).doc(auth.currentUser!.uid).update({'places': places});

    var destinationDoc = await firestore.collection(destinationPath).doc(auth.currentUser!.uid).get();
    var destinationPlaces = destinationDoc.exists ? destinationDoc.get('places') : {};

    movedPlaces.forEach((uid, name) {
      destinationPlaces[uid] = name;
    });

    await firestore.collection(destinationPath).doc(auth.currentUser!.uid).set({'places': destinationPlaces});

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subcoleções movidas para $destinationPath')),
    );
  }
}

  void onSubcollectionsDeleted(List<String> uids) async {
    var doc =
        await firestore.collection(caminho).doc(auth.currentUser!.uid).get();
    var places = doc.get('places');

    Map<String, String> deletedPlaces = {};

    if (places != null) {
      for (String uid in uids) {
        if (places.containsKey(uid)) {
          String deletedName = places[uid];
          deletedPlaces[uid] = deletedName;
          places.remove(uid);
        }
      }

      setState(() {
        longPress = false;
        selecionado = 0;
        selected = [];
      });

      await firestore
          .collection(caminho)
          .doc(auth.currentUser!.uid)
          .update({'places': places});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Arquivos excluídos'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              // Restaurar as subcoleções
              deletedPlaces.forEach((uid, name) {
                places[uid] = name;
              });

              await firestore
                  .collection(caminho)
                  .doc(auth.currentUser!.uid)
                  .update({'places': places});
            },
          ),
        ),
      );
    }
  }

  void onSubcollectionEdited(String novoNome, String idAtual) async {
    await firestore
        .collection(caminho)
        .doc(auth.currentUser!.uid)
        .get()
        .then((doc) {
      Map<String, dynamic> places = doc.get('places');
      if (!places.containsValue(novoNome)) {
        places[idAtual] = novoNome;

        firestore
            .collection(caminho)
            .doc(auth.currentUser!.uid)
            .set({'places': places});
      } else {
        Fluttertoast.showToast(
          msg: "Nome $novoNome já em uso",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      novoNome = '';
    });
  }

  Widget editSelecionado(
    TextEditingController editController,
  ) {
    return TextField(
      controller: editController,
      decoration: const InputDecoration(
        labelText: 'Novo nome',
        hintText: 'Novo nome',
      ),
      onChanged: (value) => nomeEditado = value,
    );
  }

  void editLongPress(String valor, String uid) {
    final TextEditingController editController =
        TextEditingController(text: valor.toString());
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
                const Text("Editar Nome"),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    nomeEditado = '';
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: editSelecionado(editController),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        onSubcollectionsDeleted(selected);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Deletar",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        onSubcollectionEdited(editController.text, uid);
                        decrementSelecionado(uid);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "Editar",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  AlertDialog _buildExitDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmação de Saída'),
      content: const Text('Deseja sair do aplicativo?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Não'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Sim',
            style: TextStyle(color: Colors.red),
          ),
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
          if (longPress) {
            setState(() {
              longPress = false;
              selecionado = 0;
              selected = [];
            });
            return false;
          } else if (historicoNavegacao.isNotEmpty) {
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
            title: !longPress
                ? Text(tituloPagina)
                : Row(
                    children: [
                      //Editar LongPress individualmente
                      Text("Selecionado $selecionado"),
                      if (selecionado == 1)
                        IconButton(
                          onPressed: () {
                            return editLongPress(nomeEditado, selected[0]);
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                        ),
                      //Deletar todos no LongPress
                      IconButton(
                        onPressed: () {
                          onSubcollectionsDeleted(selected);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      //Mover LongPress
                      IconButton(
                        onPressed: () {
                          onSubcollectionsMoved(selected);
                        },
                        icon: const Icon(
                          Icons.drive_file_move_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
            leading: !longPress
                ? !returnable
                    ? null
                    : IconButton(
                        onPressed: voltar,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                : IconButton(
                    onPressed: () {
                      setState(() {
                        longPress = false;
                        selecionado = 0;
                        selected = [];
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
            actions: [
              //Home
              // if (returnable)
              //   IconButton(
              //     onPressed: home,
              //     icon: const Icon(Icons.home_rounded),
              //   ),
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
            longPressActive: _longPressActive,
            longPress: longPress,
            incrementSelecionado: incrementSelecionado,
            decrementSelecionado: decrementSelecionado,
            handleSelected: handleSelected,
            selected: selected,
          ),
          floatingActionButton: SpeedDial(
            backgroundColor: Colors.black,
            overlayColor: Colors.black,
            overlayOpacity: 0.4,
            spacing: 12,
            spaceBetweenChildren: 12,
            visible: !longPress,
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
                                  color: Colors.blue,
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
              SpeedDialChild(
                child: const Icon(Icons.menu_book_outlined),
                label: 'Modelo',
                // onTap: () => Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => ItemCreatePage(caminho: caminho),
                //   ),
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
