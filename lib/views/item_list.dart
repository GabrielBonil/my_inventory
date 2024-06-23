// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myinventory/components/custom_stream_builder.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:myinventory/views/item_create.dart';
import 'package:uuid/uuid.dart';
// import 'package:myinventory/components/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:myinventory/components/destination_selector.dart';
import 'package:myinventory/views/item_model.dart';

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
  late String caminho = 'users/$user/MyInventory';
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
  late String currentPath = user;
  late String user = auth.currentUser!.uid;

  void updateCurrentPath(String uid) async {
    setState(() {
      historicoNavegacao.add(currentPath);
      currentPath = uid;
    });
    updateTitle(currentPath);
    var currentName = await getFolderName(currentPath);
    historicoTitulos.add(currentName);
  }

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

  void voltar() {
    if (historicoNavegacao.isNotEmpty) {
      setState(() {
        currentPath = historicoNavegacao.last;
      });
      historicoNavegacao.removeLast();
      updateTitle(currentPath);
      historicoTitulos.removeLast();
    }
  }

  void _handlePathNavigate(int index) {
    if (longPress) {
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
        currentPath = handleCaminho;
        updateTitle(currentPath);
      });
    }
  }

  void home() {
    if (historicoNavegacao.isNotEmpty) {
      setState(() {
        currentPath = user;
      });
      historicoNavegacao.clear();
      updateTitle(currentPath);
      historicoTitulos = ['MyInventory'];
    }
  }

  void updateTitle(String currentPath) async {
    if (currentPath == user) {
      setState(() {
        tituloPagina = "MyInventory";
      });
    } else {
      var title = await getFolderName(currentPath);
      setState(() {
        tituloPagina = title;
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

  Future<String> getFolderName(String uid) async {
    var doc =
        await FirebaseFirestore.instance.collection(caminho).doc(user).get();
    var places = doc.data()?['places'] ?? {};
    return places[uid]?['name'] ?? '';
  }

  Future<String> getDocumentName(String uid) async {
    var doc =
        await FirebaseFirestore.instance.collection(caminho).doc(uid).get();
    return doc.data()?['Nome'] ?? '';
  }

  void handleEdit(String newName, String id) async {
    DocumentSnapshot doc = await firestore.collection(caminho).doc(id).get();
    if (doc.exists) {
      saveItemName(id, newName);
      return;
    }
    onSubcollectionEdited(newName, id);
  }

  void handleDelete(List<String> ids) async {
    List<String> docIds = [];
    List<String> folderIds = [];

    for (String id in ids) {
      DocumentSnapshot doc = await firestore.collection(caminho).doc(id).get();
      if (doc.exists) {
        docIds.add(id);
      } else {
        folderIds.add(id);
      }
    }

    // Mover documentos (itens) para a "Lixeira"
    for (String id in docIds) {
      var itemRef = firestore.collection(caminho).doc(id);

      await itemRef.update({user: 'Lixeira'});
    }

    // Mover pastas (subcoleções) para a "Lixeira"
    var userDoc = await firestore.collection(caminho).doc(user).get();
    if (userDoc.exists) {
      Map<String, dynamic> places =
          Map<String, dynamic>.from(userDoc.get('places'));

      for (String id in folderIds) {
        if (places.containsKey(id)) {
          places[id][user] = 'Lixeira';
        }
      }

      await firestore.collection(caminho).doc(user).set({'places': places});
    }

    resetLongPress();

    // Exibir Snackbar com opção de desfazer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exclusão realizada'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            // Restaurar pastas deletadas
            var userDoc = await firestore.collection(caminho).doc(user).get();
            if (userDoc.exists) {
              Map<String, dynamic> places =
                  Map<String, dynamic>.from(userDoc.get('places'));

              for (String id in folderIds) {
                places[id][user] = currentPath;
              }

              await firestore
                  .collection(caminho)
                  .doc(user)
                  .set({'places': places});
            }

            // Restaurar itens da "Lixeira"
            for (String id in docIds) {
              var itemRef = firestore.collection(caminho).doc(id);
              await itemRef.update(
                  {user: currentPath}); // Restaurar para o usuário atual
            }
          },
        ),
      ),
    );
  }

  Future<void> handleMove(String destinationPath, List<String> ids) async {
    var userDoc = await firestore.collection(caminho).doc(user).get();
    Map<String, dynamic> places = {};
    if (userDoc.exists) {
      places = Map<String, dynamic>.from(userDoc.get('places'));
    }

    for (String id in ids) {
      DocumentSnapshot doc = await firestore.collection(caminho).doc(id).get();
      if (doc.exists) {
        await firestore
            .collection(caminho)
            .doc(id)
            .update({auth.currentUser!.uid: destinationPath});
      } else {
        if (places.containsKey(id)) {
          places[id][auth.currentUser!.uid] = destinationPath;
        }
      }
    }

    if (userDoc.exists) {
      await firestore.collection(caminho).doc(user).set({'places': places});
    }
  }

  void saveItemName(String itemId, String newName) {
    var itemRef = firestore.collection(caminho).doc(itemId);
    itemRef.update({'Nome': newName});
  }

  void onSubcollectionCreated(String subcollectionName) {
    firestore.collection(caminho).doc(user).get().then((doc) {
      Map<String, dynamic> places = {};

      if (doc.exists) {
        var existingPlaces = doc.get('places');
        if (existingPlaces is Map) {
          places = Map<String, dynamic>.from(existingPlaces);
        }
      }

      if (!places.values.any((place) => place['name'] == subcollectionName)) {
        var uuid = const Uuid();
        var codigo = uuid.v4();

        places[codigo] = {'name': subcollectionName, user: currentPath};

        firestore.collection(caminho).doc(user).set({'places': places});
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DestinationSelector(
          selectedUids: selectedUids,
          onDestinationSelected: (String destinationPath) {
            move(selectedUids, destinationPath);
          },
        );
      },
    );
  }

  void move(List<String> selectedUids, String destinationPath) async {
    await handleMove(destinationPath, selectedUids);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Itens e pastas movidos'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            await handleMove(auth.currentUser!.uid, selectedUids);
          },
        ),
      ),
    );

    resetLongPress();
  }

  void resetLongPress() {
    setState(() {
      longPress = false;
      selecionado = 0;
      selected = [];
    });
  }

  void onSubcollectionsDeleted(List<String> uids) async {
    var doc = await firestore.collection(caminho).doc(user).get();
    if (doc.exists) {
      Map<String, dynamic> places =
          Map<String, dynamic>.from(doc.get('places'));
      Map<String, dynamic> deletedPlaces = {};

      for (String uid in uids) {
        if (places.containsKey(uid)) {
          deletedPlaces[uid] = places[uid];
          places.remove(uid);
        }
      }

      resetLongPress();

      await firestore.collection(caminho).doc(user).set({'places': places});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subcoleções excluídas'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              places.addAll(deletedPlaces);
              await firestore
                  .collection(caminho)
                  .doc(user)
                  .set({'places': places});
            },
          ),
        ),
      );
    }
  }

  void onSubcollectionEdited(String novoNome, String idAtual) async {
    var doc = await firestore.collection(caminho).doc(user).get();
    if (doc.exists) {
      Map<String, dynamic> places =
          Map<String, dynamic>.from(doc.get('places'));

      if (!places.values.any((place) => place['name'] == novoNome)) {
        places[idAtual]['name'] = novoNome;

        await firestore.collection(caminho).doc(user).set({'places': places});
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
    }
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

  void editLongPress(String uid) async {
    var valor = await getFolderName(uid);

    // ignore: unrelated_type_equality_checks
    if (valor == "") valor = await getDocumentName(uid);

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
                        handleDelete(selected);
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
                        handleEdit(editController.text, uid);
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

  // @override
  // void initState() {
  //   super.initState();
  //   updateCurrentPath(user);
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (longPress) {
            resetLongPress();
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: selecionado == 1
                            ? Text("$selecionado item")
                            : Text("$selecionado itens"),
                      ),
                      if (selecionado == 1)
                        IconButton(
                          onPressed: () {
                            return editLongPress(selected[0]);
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                        ),
                      //Deletar todos no LongPress
                      IconButton(
                        onPressed: () {
                          handleDelete(selected);
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
                      resetLongPress();
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
            historicoTitulos: historicoTitulos,
            handlePathNavigate: _handlePathNavigate,
            longPressActive: _longPressActive,
            longPress: longPress,
            incrementSelecionado: incrementSelecionado,
            decrementSelecionado: decrementSelecionado,
            handleSelected: handleSelected,
            selected: selected,
            updateCurrentPath: updateCurrentPath,
            currentPath: currentPath,
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
                    builder: (context) => ItemCreatePage(
                      caminho: caminho,
                      currentPath: currentPath,
                    ),
                  ),
                ),
              ),
              SpeedDialChild(
                child: const Icon(Icons.menu_book_outlined),
                label: 'Modelo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ModelManagementPage(),
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
