import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tg/components/loading.dart';
import 'package:tg/components/my_items.dart';

class CustomStreamBuilder extends StatefulWidget {
  final String caminho;
  final Function(String) updatePath;
  final List<String> historicoTitulos;
  final Function(int) handlePathNavigate;
  final Function(String) longPressActive;
  final bool longPress;
  final Function(String) incrementSelecionado;
  final Function(String) decrementSelecionado;
  final Function() handleSelected;
  final List<String> selected;
  const CustomStreamBuilder({
    super.key,
    required this.caminho,
    required this.updatePath,
    required this.historicoTitulos,
    required this.handlePathNavigate,
    required this.longPressActive,
    required this.longPress,
    required this.incrementSelecionado,
    required this.decrementSelecionado,
    required this.handleSelected,
    required this.selected,
  });

  @override
  State<CustomStreamBuilder> createState() => _CustomStreamBuilderState();
}

class _CustomStreamBuilderState extends State<CustomStreamBuilder> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool subCollectionsExist = false;
  Map<String, String> subColecoes = {};
  List<DocumentSnapshot> outrosDocumentos = [];

  void _handleNavigate(String novoCaminho) {
    widget.updatePath(novoCaminho);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestore.collection(widget.caminho).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loading();
        } else if (snapshot.hasError) {
          return Text('Erro ao obter dados dos itens: ${snapshot.error}');
        }
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty && snapshot.data!.docs.isEmpty) {
          return const Text('Nenhum item encontrado.');
        }

        //Criando todos os documentos (exceto auth.currentUser!.uid):
        outrosDocumentos = [];
        for (var doc in snapshot.data!.docs) {
          // Se o ID do documento não for auth.currentUser!.uid, adiciona à lista
          if (doc.id != auth.currentUser!.uid) {
            outrosDocumentos.add(doc);
          }
        }

        //Ordenando itens
        outrosDocumentos.sort((a, b) {
          var nameA = a['Nome'].toString().toLowerCase();
          var nameB = b['Nome'].toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        // Verifica se o documento auth.currentUser!.uid está presente
        if (snapshot.data!.docs.any((doc) => doc.id == auth.currentUser!.uid)) {
          var collectionsDoc = snapshot.data!.docs
              .firstWhere((element) => element.id == auth.currentUser!.uid);
          Map<String, dynamic> collectionsData = collectionsDoc.data();

          // Verifica se há o documento auth.currentUser!.uid e se tem subcoleções
          if (collectionsData.isNotEmpty) {
            subCollectionsExist = true;

            // subColecoes = collectionsData['places'].values.cast<String>().toList();
            subColecoes = Map<String, String>.from(collectionsData['places']);

            //Ordenando Pastas
            // subColecoes.sort();
            subColecoes = Map.fromEntries(subColecoes.entries.toList()
              ..sort((e1, e2) => e1.value.compareTo(e2.value)));
          }
        }

        return ListView(
          children: [
            //Pathing
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...widget.historicoTitulos.asMap().entries.map(
                        (e) => TextButton(
                          onPressed: () => widget.handlePathNavigate(e.key),
                          child: Text(e.value),
                        ),
                      ),
                ],
              ),
            ),
            // Text('${widget.historicoTitulos}'),
            if (subCollectionsExist && subColecoes.isNotEmpty)
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...subColecoes.entries.map((e) {
                    bool isSelected = widget.selected.contains(e.key);

                    return GestureDetector(
                      onTap: () {
                        widget.handleSelected();
                        if (widget.selected.contains(e.key)) {
                          widget.decrementSelecionado(e.key);
                        } else {
                          if (!widget.longPress) {
                            String novoCaminho = '${widget.caminho.toString()}/${auth.currentUser!.uid}/${e.key}';

                            setState(() {
                              subColecoes.clear();
                            });

                            _handleNavigate(novoCaminho);
                          } else {
                            widget.incrementSelecionado(e.key);
                          }
                        }
                      },
                      onLongPress: () {
                        widget.handleSelected();
                        if (widget.selected.contains(e.key)) {
                          widget.decrementSelecionado(e.key);
                        } else {
                          widget.longPressActive(e.key);
                        }
                      },
                      child: LayoutBuilder(
                        builder: (p0, p1) {
                          double iconSize = p1.maxHeight * 0.7;
                          return Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder,
                          size: iconSize,
                          color: Colors.blue,
                        ),
                        Text(e.value.toString()),
                      ],
                    ),
                    if (widget.longPress)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: SizedBox(
                          child: Icon(
                            isSelected ? Icons.check_box_outlined : Icons.check_box_outline_blank_sharp,
                            size: iconSize * 0.25,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            // ...outrosDocumentos.map((e) => MyItems(document: e)).toList(),
            ...outrosDocumentos
                .map(
                  (e) => Dismissible(
                    key: Key(e.id),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      FirebaseFirestore.instance
                          .collection(widget.caminho)
                          .doc(e.id)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Item deletado'),
                          action: SnackBarAction(
                            label: 'DESFAZER',
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection(widget.caminho)
                                  .doc(e.id)
                                  .set(e.data() as Map<String, dynamic>);
                              // setState(() {
                              //   items.add(doc);
                              // });
                            },
                          ),
                        ),
                      );
                    },
                    background: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: Colors.transparent,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Icon(Icons.delete_outlined, color: Colors.red),
                        ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: const [
                        //     Padding(
                        //       padding: EdgeInsets.all(16.0),
                        //       child:
                        //           Icon(Icons.delete_outlined, color: Colors.red),
                        //     ),
                        //     Padding(
                        //       padding: EdgeInsets.all(16.0),
                        //       child:
                        //           Icon(Icons.delete_outlined, color: Colors.red),
                        //     ),
                        //   ],
                        // ),
                      ),
                    ),
                    child: MyItems(
                      document: e,
                      caminho: widget.caminho,
                    ),
                  ),
                )
                .toList(),
          ],
        );
      },
    );
  }
}
