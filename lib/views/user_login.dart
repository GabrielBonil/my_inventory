import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  var mostrarSenha = false;
  bool registrar = false;
  String email = '';
  String password = '';
  String confirmPassword = '';

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? validarSenha(String? value) {
    if (value == null || value.isEmpty || value.length < 6) {
      return 'O campo deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  String? validarConfirmacaoSenha(String? value) {
    if (value != password) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  String? validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'O campo não pode estar vazio';
    }
    if (!EmailValidator.validate(value)) {
      return 'Digite um E-mail válido!';
    }
    return null;
  }

  var formKey = GlobalKey<FormState>();

  void logar(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      try {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Erro ao fazer login: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  void register(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      try {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String usuario = auth.currentUser!.uid;
        // Lógica de pastas:
        await firestore
            .collection('users')
            .doc(usuario)
            .collection('MyInventory')
            .doc(usuario)
            .set({'places': {}});

        // Lógica dos modelos:
        Map<String, dynamic> modeloPadrao = {
          "Padrão": {"Nome": "Descrição"},
          "Nome e Quantidade": {
            "Nome": "Descrição",
            "Quantidade": "Número Inteiro"
          },
        };

        await firestore.collection('users').doc(usuario).set(modeloPadrao);
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Erro ao fazer registro: ${e.toString()}",
          timeInSecForIosWeb: 5,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(registrar ? "Registrar" : "Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Form(
              key: formKey,
              child: Column(
                children: [
                  // E-mail
                  TextFormField(
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: "E-mail",
                      hintText: "E-mail",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: validarEmail,
                    onSaved: (value) {
                      email = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Senha
                  TextFormField(
                    obscureText: !mostrarSenha,
                    maxLength: 50,
                    decoration: InputDecoration(
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      labelText: "Senha",
                      hintText: "Senha",
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            mostrarSenha = !mostrarSenha;
                          });
                        },
                      ),
                    ),
                    validator: validarSenha,
                    onChanged: (value) {
                      password = value;
                    },
                    onSaved: (value) {
                      password = value!;
                    },
                  ),
                  if (registrar) ...[
                    const SizedBox(height: 20),
                    // Confirmar Senha
                    TextFormField(
                      obscureText: !mostrarSenha,
                      maxLength: 50,
                      decoration: InputDecoration(
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        labelText: "Confirmar Senha",
                        hintText: "Confirmar Senha",
                        suffixIcon: IconButton(
                          icon: Icon(
                            mostrarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              mostrarSenha = !mostrarSenha;
                            });
                          },
                        ),
                      ),
                      validator: validarConfirmacaoSenha,
                      onSaved: (value) {
                        confirmPassword = value!;
                      },
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                // Botão Logar ou Registrar
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (registrar) {
                        register(context);
                      } else {
                        logar(context);
                      }
                    },
                    child: Text(registrar ? "Registrar" : "Logar"),
                  ),
                ),
                const SizedBox(height: 20),
                // Alternar entre login e registro
                TextButton(
                  onPressed: () {
                    setState(() {
                      registrar = !registrar;
                    });
                  },
                  child: Text(
                    registrar
                        ? "Já tem uma conta? Clique aqui para Logar"
                        : "Não tem uma conta? Clique aqui para criar uma!",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
