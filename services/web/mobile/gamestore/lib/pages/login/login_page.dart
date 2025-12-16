import 'dart:convert';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gamestore/pages/area/ServiceLoginWebViewPage.dart';
import 'package:gamestore/pages/register/register.dart';
import 'package:gamestore/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glassmorphism/glassmorphism.dart';

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
  bool isLoading = false;

  void SignUserInput(BuildContext context) async {
    setState(() => isLoading = true);
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
        final jsonResponse = jsonDecode(response.body);
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
      } else {
        setState(() {
          showEmailError = true;
          showPasswordError = true;
        });
      }
    } catch (e) {
      print("Erreur lors de la connexion: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: FadeInLeft(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: FadeInRight(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondary.withOpacity(0.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withOpacity(0.3),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Glassmorphic Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Image.asset('assets/logo.png'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: GlassmorphicContainer(
                        width: double.infinity,
                        height: 550,
                        borderRadius: 20,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                            stops: const [0.1, 1],
                        ),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Welcome Back",
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Sign in to continue",
                                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                              ),
                              const SizedBox(height: 30),
                              
                              // Inputs
                              _buildTextField(usernameController, "Username", Icons.person),
                              const SizedBox(height: 15),
                              _buildTextField(passwordController, "Password", Icons.lock, isPassword: true),
                              
                              if (showEmailError || showPasswordError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    'Invalid credentials',
                                    style: TextStyle(color: AppTheme.error),
                                  ),
                                ),
                                
                              const SizedBox(height: 30),
                              
                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : () => SignUserInput(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text("Sign In", style: TextStyle(fontSize: 18)),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Social & Register
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text("OR", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              GestureDetector(
                                onTap: () async {
                                  String googleAuthURL = await getGoogleAuthURL();
                                  if (googleAuthURL.isNotEmpty) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => WebViewPage(oauthLink: googleAuthURL, id: 1),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Image.asset('assets/google.png', height: 30),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    children: [
                                      TextSpan(
                                        text: "Register",
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
