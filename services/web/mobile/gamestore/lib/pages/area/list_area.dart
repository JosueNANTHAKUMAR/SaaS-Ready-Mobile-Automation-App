import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AreaListDialog extends StatelessWidget {
  const AreaListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<Map<String, String>>>(
          future: fetchAreas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return _buildErrorContent(context, snapshot.error.toString());
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return _buildEmptyContent(context);
            } else if (snapshot.hasData) {
              final areas = snapshot.data!;
              return _buildListContent(context, areas);
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Erreur"),
        Text("Une erreur s'est produite : $errorMessage"),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Fermer",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Liste des areas créées"),
        const Text("Aucune area n'a été créée."),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Fermer",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildListContent(
      BuildContext context, List<Map<String, String>> areas) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Liste des areas créées"),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              return ListTile(
                title: Text(area['name'] ?? ''),
                subtitle: Text(area['description'] ?? ''),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Fermer",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        )
      ],
    );
  }

  Future<List<Map<String, String>>> fetchAreas() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/areas');

    try {
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> areas = [];
        for (var area in data) {
          areas.add({
            'name': area['name'],
            'description': area['description'],
          });
        }
        return areas;
      } else {
        throw Exception('Failed to fetch areas: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('An error occurred while fetching areas: $error');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    String token = await fetchToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'x-access-tokens': token,
    };
    return Future.value(headers);
  }

  Future<String> fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    return token ?? '';
  }
}
