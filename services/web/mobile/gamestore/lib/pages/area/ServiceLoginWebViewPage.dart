import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebViewPage extends StatefulWidget {
  final String oauthLink;

  WebViewPage({required this.oauthLink, required this.id, Key? key})
      : super(key: key);
  final int id;

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _controller;
  String? code;

  Future<String> fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    return token ?? '';
  }

  Future<void> postCodeToServer(String code) async {
    final String baseUrl = '${dotenv.env['BASE_URL']}';
    final String endpoint = '$baseUrl/auth/services';
    String token = await fetchToken();

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'x-access-tokens': token,
      },
      body: jsonEncode({
        'id': widget.id,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      print("Success: ${response.body}");
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> postGoogleAuthCode(String code) async {
    final String baseUrl = '${dotenv.env['BASE_URL']}';
    final String endpoint = '$baseUrl/auth/register';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String accessToken = responseData['access_token'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print(
            "Erreur lors de la récupération du token d'accès Google : ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        print("Erreur lors de la récupération du token d'accès Google : $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N)')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith('http://localhost:8081/callback')) {
              Uri uri = Uri.parse(request.url);
              code = uri.queryParameters['code'] ?? "";
              if (request.url.contains('google')) {
                await postGoogleAuthCode(code!);
                return NavigationDecision.prevent;
              } else {
                await postCodeToServer(code!);
                Navigator.pop(context);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _controller?.loadRequest(Uri.parse(widget.oauthLink));
  }

  void connectService() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification'),
      ),
      body: WebViewWidget(
        controller: _controller!,
      ),
    );
  }
}
