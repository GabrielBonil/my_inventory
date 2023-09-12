import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tg/components/my_list_view.dart';

class ItemListPage extends StatefulWidget {
  List<String> filtrar;
  ItemListPage({super.key, required this.filtrar});
  
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
  var dropdownValue;

  @override
  void initState() {
    super.initState();
    print(widget.filtrar);
    dropdownValue = widget.filtrar[0];
    if (auth.currentUser == null) {
      logado = false;
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items"),
        actions: [
          //Botão Dropdown que organiza como vai ser ordenado os itens
          DropdownButton(
            focusColor: Colors.transparent,
            underline: const SizedBox.shrink(),
            value: dropdownValue,
            items: widget.filtrar.map((e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                dropdownValue = newValue;
              });
              finalizados = false;
              pendentes = false;
              switch (newValue) {
                case 'nome':
                  setState(() {
                    ordenarDropdown = 'name';
                  });
                  break;
                case 'prioridade':
                  setState(() {
                    ordenarDropdown = 'priorityIndex';
                  });
                  break;
                case 'data':
                  setState(() {
                    ordenarDropdown = 'date';
                  });
                  break;
                case 'finalizados':
                  setState(() {
                    finalizados = true;
                    ordenarDropdown = 'name';
                  });
                  break;
                case 'pendentes':
                  setState(() {
                    pendentes = true;
                    ordenarDropdown = 'name';
                  });
                  break;
                default:
              }
            },
          ),

          //Seta que inverte a ordem da organização dos itens (ascending and descending)
          IconButton(
            onPressed: () {
              setState(() {
                ordenarSeta = !ordenarSeta;
              });
            },
            icon: Icon(ordenarSeta ? Icons.arrow_upward : Icons.arrow_downward),
          ),

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
                  .collection('items')
                  .where('uid', isEqualTo: auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text(
                      'Erro ao obter dados das itens: ${snapshot.error}');
                } else if (auth.currentUser == null) {
                  return const Text('Usuário não logado');
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Não há itens a serem exibidas');
                }

                var tasks = snapshot.data!.docs;

                var listaTasks = [];
                for (var task in tasks) {
                  listaTasks.add(task);
                }

                var listaAux = [];
                if (finalizados || pendentes) {
                  if (finalizados) {
                    for (var task in listaTasks) {
                      if (task.data()['finished'] == true) {
                        listaAux.add(task);
                      }
                    }
                  } else {
                    for (var task in listaTasks) {
                      if (task.data()['finished'] == false) {
                        listaAux.add(task);
                      }
                    }
                  }
                  listaTasks = listaAux;
                }

                listaTasks.sort(
                    (a, b) => a[ordenarDropdown].compareTo(b[ordenarDropdown]));
                if (ordenarSeta) {
                  listaTasks = listaTasks.reversed.toList();
                }

                listaAux = [];
                if (pesquisar.isNotEmpty) {
                  for (var task in listaTasks) {
                    if (task
                        .data()['name']
                        .toLowerCase()
                        .contains(pesquisar.toLowerCase())) {
                      listaAux.add(task);
                    }
                  }
                  listaTasks = listaAux;
                }

                return MyListView(lista: listaTasks);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/item_create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
