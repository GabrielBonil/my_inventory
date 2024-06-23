import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tg/components/loading.dart';
import 'package:tg/components/my_items.dart';

class CustomStreamBuilder extends StatefulWidget {
  final String caminho;
  final List<String> historicoTitulos;
  final Function(int) handlePathNavigate;
  final Function(String) longPressActive;
  final bool longPress;
  final Function(String) incrementSelecionado;
  final Function(String) decrementSelecionado;
  final Function() handleSelected;
  final List<String> selected;
  final Function(String) updateCurrentPath;
  final String currentPath;
  const CustomStreamBuilder({
    super.key,
    required this.caminho,
    required this.historicoTitulos,
    required this.handlePathNavigate,
    required this.longPressActive,
    required this.longPress,
    required this.incrementSelecionado,
    required this.decrementSelecionado,
    required this.handleSelected,
    required this.selected,
    required this.updateCurrentPath,
    required this.currentPath,
  });

  @override
  State<CustomStreamBuilder> createState() => _CustomStreamBuilderState();
}

class _CustomStreamBuilderState extends State<CustomStreamBuilder> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, dynamic> pastas = {};
  List<DocumentSnapshot> documentos = [];

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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Nenhum item encontrado.');
        }

        // Procurar o documento do usuário
        var userDoc = snapshot.data!.docs.firstWhere(
          (doc) => doc.id == auth.currentUser!.uid,
        );

        // Obter places do documento do usuário
        Map<String, dynamic> userDocData = userDoc.data();
        var places = userDocData['places'] as Map<String, dynamic>? ?? {};

        // Filtrar pastas que apontam para o currentPath atual
        pastas = Map<String, dynamic>.from(
          places
            ..removeWhere((key, value) =>
                value[auth.currentUser!.uid] != widget.currentPath),
        );

        // Ordenando pastas
        pastas = Map.fromEntries(pastas.entries.toList()
          ..sort((e1, e2) => e1.value['name']
              .toLowerCase()
              .compareTo(e2.value['name'].toLowerCase())));

        // Filtrar outros documentos que apontam para o currentPath atual
        var documentos = snapshot.data!.docs.where((doc) {
          if (doc.id != auth.currentUser!.uid) {
            Map<String, dynamic> data = doc.data();
            return data[auth.currentUser!.uid] == widget.currentPath;
          }
          return false;
        }).toList();

        //Ordenando itens
        documentos.sort((a, b) {
          var nameA = a['Nome'].toString().toLowerCase();
          var nameB = b['Nome'].toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

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
            if (pastas.isNotEmpty)
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...pastas.entries.map((e) {
                    bool isSelected = widget.selected.contains(e.key);

                    return GestureDetector(
                      onTap: () {
                        widget.handleSelected();
                        if (widget.selected.contains(e.key)) {
                          widget.decrementSelecionado(e.key);
                          return;
                        }
                        if (widget.longPress) {
                          widget.incrementSelecionado(e.key);
                          return;
                        }
                        widget.updateCurrentPath(e.key);
                        setState(() {
                          pastas.clear();
                        });
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
                                  Text(e.value['name']),
                                ],
                              ),
                              if (widget.longPress)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: SizedBox(
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_box_outlined
                                          : Icons.check_box_outline_blank_sharp,
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
            ...documentos.map(
              (e) {
                bool isSelected = widget.selected.contains(e.id);

                return Dismissible(
                  key: Key(e.id),
                  direction: !widget.longPress
                      ? DismissDirection.startToEnd
                      : DismissDirection.none,
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
                                .set(e.data());
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
                    ),
                  ),
                  child: MyItems(
                    document: e,
                    caminho: widget.caminho,
                    user: auth.currentUser!.uid,
                    longPress: widget.longPress,
                    longPressActive: widget.longPressActive,
                    incrementSelecionado: widget.incrementSelecionado,
                    decrementSelecionado: widget.decrementSelecionado,
                    handleSelected: widget.handleSelected,
                    selected: widget.selected,
                    isSelected: isSelected,
                  ),
                );
              },
            ).toList(),
          ],
        );
      },
    );
  }
}
