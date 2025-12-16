import 'package:flutter/material.dart';
import 'package:gamestore/pages/area/area_data.dart';
import 'package:gamestore/theme/app_theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
              'enabled': area['enabled'].toString(),
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
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == areasData.length) {
            return GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/area');
              },
              child: GlassmorphicContainer(
                width: 160,
                height: 200,
                borderRadius: 20,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.primary.withOpacity(0.1),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(Icons.add, size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Create New",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            );
          }
          final area = areasData[index];
          return GestureDetector(
            onTap: () {
              _showDeleteConfirmationDialog(area);
            },
            child: GlassmorphicContainer(
              width: 280,
              height: 200,
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            area['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: area['enabled'] == 'true'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: area['enabled'] == 'true'
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.red.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            area['enabled'] == 'true' ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              color: area['enabled'] == 'true'
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        area['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showToggleStatusDialog(area);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: area['enabled'] == 'true'
                              ? Colors.red.withOpacity(0.8)
                              : Colors.green.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          area['enabled'] == 'true' ? 'Disable' : 'Enable',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: ((context, index) => const SizedBox(width: 15)),
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
          backgroundColor: AppTheme.surface,
          title: Text(isEnabled ? 'Disable Area' : 'Enable Area', style: const TextStyle(color: Colors.white)),
          content: Text(
              'Do you really want to ${isEnabled ? 'disable' : 'enable'} this area?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                _toggleAreaStatus(area);
                Navigator.of(context).pop();
              },
              child: Text(
                isEnabled ? 'Disable' : 'Enable',
                style: TextStyle(color: isEnabled ? AppTheme.error : AppTheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // ... (Keep existing logic methods: fetchAreaIds, isAreaEnabled, _toggleAreaStatus, _deleteArea, _showDeleteConfirmationDialog but update dialog styles)
  
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
          backgroundColor: AppTheme.surface,
          title: const Text('Delete Confirmation', style: TextStyle(color: Colors.white)),
          content: const Text('Do you really want to delete this area?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                await _deleteArea(area);
                Navigator.of(context).pop();
              },
              child:
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        );
      },
    );
  }
}
