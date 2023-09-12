import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  var mostrarSenha = false;
  String email = '';
  String password = '';

  FirebaseAuth auth = FirebaseAuth.instance;

  String? validarSenha(String? value) {
    if (value == null || value.isEmpty || value.length < 6) {
      return 'O campo deve ter pelo menos 6 caracteres.';
    }

    setState(() {
      password = value;
    });
    return null;
  }

  String? validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'O campo não pode estar vazio';
    }

    if (!EmailValidator.validate(value)) {
      return 'Digite um E-mail valido!';
    }

    setState(() {
      email = value;
    });
    return null;
  }

  var formKey = GlobalKey<FormState>();

  void logar(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        // Navigator.of(context).popAndPushNamed('/item_list'); //Talvez tenha que mudar o tipo de troca depois
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/item_list',
          ModalRoute.withName('/'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            //E-mail
            TextFormField(
              maxLength: 50,
              decoration: const InputDecoration(
                // icon: Icon(Icons.people_alt_rounded),
                hintText: "E-mail",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              onSaved: (newValue) {},
              // autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validarEmail,
            ),

            //Senha
            TextFormField(
              obscureText: !mostrarSenha,
              maxLength: 50,
              decoration: InputDecoration(
                // icon: Icon(Icons.lock),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                hintText: "Senha",
                suffixIcon: IconButton(
                  icon: Icon(
                      mostrarSenha ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      mostrarSenha = !mostrarSenha;
                    });
                  },
                ),
              ),
              validator: validarSenha,
              // autovalidateMode: AutovalidateMode.onUserInteraction,
            ),

            //Botão Logar
            SizedBox(
              width: MediaQuery.of(context).size.width -
                  40, //width: double.infinity,
              child: ElevatedButton(
                onPressed: () => logar(context),
                child: const Text("Logar"),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width -
                  40, //width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popAndPushNamed('/user_register'),
                child: const Text("Registrar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}