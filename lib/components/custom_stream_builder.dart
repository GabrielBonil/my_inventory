import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tg/components/loading.dart';
import 'package:tg/components/my_items.dart';

class CustomStreamBuilder extends StatefulWidget {
  final String caminho;
  final Function(String) updatePath;
  const CustomStreamBuilder({
    super.key,
    required this.caminho,
    required this.updatePath,
  });

  @override
  State<CustomStreamBuilder> createState() => _CustomStreamBuilderState();
}

class _CustomStreamBuilderState extends State<CustomStreamBuilder> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool subCollectionsExist = false;
  List<String> subColecoes = [];
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

        // Verifica se o documento auth.currentUser!.uid está presente
        if (snapshot.data!.docs.any((doc) => doc.id == auth.currentUser!.uid)) {
          var collectionsDoc = snapshot.data!.docs
              .firstWhere((element) => element.id == auth.currentUser!.uid);
          Map<String, dynamic> collectionsData = collectionsDoc.data();

          // Verifica se há o documento auth.currentUser!.uid e se tem subcoleções
          if (collectionsData.isNotEmpty) {
            subCollectionsExist = true;
            subColecoes = collectionsData['places'].cast<String>();
          }
        }

        return ListView(
          children: [
            if (subCollectionsExist && subColecoes.isNotEmpty)
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...subColecoes
                      .map(
                        (e) => GestureDetector(
                          onTap: () {
                            // print("Caminho: ${widget.caminho}");
                            String novoCaminho =
                                '${widget.caminho.toString()}/${auth.currentUser!.uid}/$e';
                            // print("Novo Caminho: $novoCaminho");

                            setState(() {
                              // outrosDocumentos.clear();
                              subColecoes.clear();
                            });

                            _handleNavigate(novoCaminho);
                          },
                          child: Container(
                            color: Colors.blue,
                            child: Center(
                              child: Text(e.toString()),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ...outrosDocumentos.map((e) => MyItems(document: e)).toList(),
          ],
        );
      },
    );
  }
}
