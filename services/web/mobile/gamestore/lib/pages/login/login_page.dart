import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gamestore/pages/area/ServiceLoginWebViewPage.dart';
import 'package:gamestore/pages/register/register.dart';
import './components/my_button.dart';
import './components/my_textfield.dart';
import './components/square_tile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool showEmailError = false;
  bool showPasswordError = false;

  void SignUserInput(BuildContext context) async {
    final String url = '${dotenv.env['BASE_URL']}/login';

    final String email = usernameController.text;
    final String password = passwordController.text;

    final Map<String, String> data = {
      "email": email,
      "password": password,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: <String, String>{
          "Content-Type": "application/json",
          'Accept': '*/*'
        },
      );

      if (response.statusCode == 200) {
        print("Authentification réussie");
        final jsonResponse = jsonDecode(response.body);
        print(jsonResponse);
        final String? token = jsonResponse["access_token"];
        if (token != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setString('email', usernameController.text);
        }
        setState(() {
          showEmailError = false;
          showPasswordError = false;
        });
        Navigator.pushReplacementNamed(context, '/home');
      } else if (response.statusCode == 400) {
        final errorMessage = jsonDecode(response.body)["error"];
        print("Erreur d'authentification : $errorMessage");
        setState(() {
          showEmailError = true;
        });
      }
    } catch (e) {
      print("Erreur lors de la connexion: $e");
    }
  }

  Future<String> fetchToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return Column(
    mainAxisAlignment: MainAxisAlignment.center,      children: <Widget>[
        const SizedBox(
          height: 50,
        ),
        Image.asset(
          'assets/logo.png',
          height: 100,
        ),
        const SizedBox(
          height: 15,
        ),
        buildWelcomeText(),
        const SizedBox(height: 15),
        buildUsernameTextField(),
        if (showEmailError)
          const Text(
            'Email incorrect. Veuillez réessayer.',
            style: TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 10),
        buildPasswordTextField(),
        if (showPasswordError)
          const Text(
            'Mot de passe incorrect. Veuillez réessayer.',
            style: TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 15),
        buildSignInButton(context),
        const SizedBox(height: 25),
        buildDividerRow(),
        const SizedBox(height: 25),
        buildSocialMediaRow(context),
        const SizedBox(
          width: 50,
        ),
        buildRegisterRow(context),
      ],
    );
  }

  Widget buildWelcomeText() {
    return Text(
      "Bienvenue sur CENTRALIZE",
      style: TextStyle(color: Colors.grey[600], fontSize: 24),
    );
  }

  Widget buildUsernameTextField() {
    return MyTextField(
      controller: usernameController,
      hintText: "Nom d'utilisateur",
      obscureText: false,
    );
  }

  Widget buildPasswordTextField() {
    return MyTextField(
      controller: passwordController,
      hintText: "Mot de passe",
      obscureText: true,
    );
  }

  Widget buildSignInButton(BuildContext context) {
    return MyButton(
      onTap: () => SignUserInput(context),
    );
  }

  Widget buildDividerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: 0.5,
              color: Colors.grey[400],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text('Ou Continuer Avec',
                style: TextStyle(color: Colors.grey[700])),
          ),
          Expanded(
            child: Divider(
              thickness: 0.5,
              color: Colors.grey[400],
            ),
          )
        ],
      ),
    );
  }

  Future<String> getGoogleAuthURL() async {
    final String baseUrl = '${dotenv.env['BASE_URL']}';
    final String endpoint = '$baseUrl/auth/register/url';

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final String googleAuthUrl = jsonDecode(response.body)['url'];
        return googleAuthUrl;
      } else {
        print(
            "Erreur lors de la récupération de l'URL d'authentification Google : ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print(
          "Erreur lors de la récupération de l'URL d'authentification Google : $e");
      return '';
    }
  }

  Widget buildSocialMediaRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 25),
        GestureDetector(
          onTap: () async {
            String googleAuthURL = await getGoogleAuthURL();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    WebViewPage(oauthLink: googleAuthURL, id: 1),
              ),
            );
          },
          child: const SquareTile(imagePath: 'assets/google.png'),
        ),
      ],
    );
  }

  Widget buildRegisterRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pas encore membre ?',
            style: TextStyle(
              height: 5,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          const Text(
            'Inscrivez-vous maintenant !',
            style: TextStyle(
              height: 5,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
