import 'package:flutter/material.dart';
import 'package:gamestore/pages/area/area_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PopularGame extends StatefulWidget {
  const PopularGame({Key? key, required List<Area> areas}) : super(key: key);

  @override
  _PopularGameState createState() => _PopularGameState();
}

class _PopularGameState extends State<PopularGame> {
  List<Map<String, String>> areasData = [];

  @override
  void initState() {
    super.initState();
    fetchAreasData();
  }

  Future<List<Map<String, String>>> fetchAreas() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/areas');

    try {
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> areas = [];
        for (var area in data) {
          if (area['id'] == null) {
            print('Error: Area data does not contain an ID');
          } else {
            areas.add({
              'id': area['id'].toString(),
              'name': area['name'],
              'description': area['description'],
            });
          }
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

  Future<void> fetchAreasData() async {
    try {
      final areas = await fetchAreas();
      setState(() {
        areasData = areas;
      });
    } catch (error) {
      print('Erreur lors de la récupération des areas : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == areasData.length) {
            return GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/area');
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }
          final area = areasData[index];
          return GestureDetector(
            onTap: () {
              _showDeleteConfirmationDialog(area);
            },
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      area['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        _showToggleStatusDialog(area);
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (area['enabled'] == 'true') {
                              return Colors.red;
                            } else {
                              return Colors.green;
                            }
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                      ),
                      child: Text(
                          area['enabled'] == 'true' ? 'Désactivé' : 'Activé'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: ((context, index) => const SizedBox(
              width: 10,
            )),
        itemCount: areasData.length + 1,
      ),
    );
  }

  void _showToggleStatusDialog(Map<String, dynamic> area) {
    final bool isEnabled = area['enabled'] == 'true';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEnabled ? 'Désactiver Area' : 'Activer Area'),
          content: Text(
              'Voulez-vous vraiment ${isEnabled ? 'désactiver' : 'activer'} cette area ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _toggleAreaStatus(area);
                Navigator.of(context).pop();
              },
              child: Text(
                isEnabled ? 'Désactiver' : 'Activer',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<int>> fetchAreaIds() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/areas');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<int> areaIds = [];

      for (var area in data) {
        final int areaId = area['id'];
        areaIds.add(areaId);
      }

      return areaIds;
    } else {
      throw Exception('Failed to fetch area IDs: ${response.statusCode}');
    }
  }

  Future<bool> isAreaEnabled(String areaId) async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/area/status/$areaId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['enabled'];
    } else {
      throw Exception('Failed to fetch area status: ${response.statusCode}');
    }
  }

  Future<void> _toggleAreaStatus(Map<String, dynamic> area) async {
    final areaId = area['id'];
    if (areaId == null) {
      print('Error: Area ID is null');
      return;
    }

    final currentState = area['enabled'] == 'true';
    final action = currentState ? 'disable' : 'enable';
    final url = Uri.parse('${dotenv.env['BASE_URL']}/area/$action/$areaId');

    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          var index =
              areasData.indexWhere((element) => element['id'] == areaId);
          if (index != -1) {
            areasData[index]['enabled'] = (!currentState).toString();
          }
        });

        print('Area with ID $areaId has been successfully ${action}d.');
      } else {
        print('Failed to ${action} area: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while toggling the area status: $e');
    }
  }

  Future<void> _deleteArea(Map<String, dynamic> area) async {
    final areaId = area['id'];
    if (areaId == null) {
      print('Error: Area ID is null');
      return;
    }

    final url = Uri.parse('${dotenv.env['BASE_URL']}/delete_area/$areaId');

    try {
      final response = await http.delete(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        setState(() {
          areasData.removeWhere((element) => element['id'] == areaId);
        });

        print('Area with ID $areaId has been successfully deleted.');
      } else {
        print('Failed to delete area: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while deleting the area: $e');
    }
  }

  void _showDeleteConfirmationDialog(Map<String, String> area) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: const Text('Voulez-vous vraiment supprimer cette area ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteArea(area);
                Navigator.of(context).pop();
              },
              child:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
