import 'package:flutter/material.dart';
import 'package:gamestore/pages/area/ServiceLoginWebViewPage.dart';
import 'package:gamestore/pages/area/list_area.dart';
import 'package:gamestore/pages/home/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateAreaPage extends StatefulWidget {
  const CreateAreaPage({Key? key}) : super(key: key);

  @override
  createState() => CreateAreaPageState();
}

Future<void> storeAreaName(String areaName) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('name', areaName);
}

class CreateAreaPageState extends State<CreateAreaPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<dynamic> servicesData = [];
  dynamic selectedService;
  dynamic selectedReactionService;
  final Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> parameters = {
    'name': '',
    'description': '',
    'actions': [],
    'reactions': [],
  };
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    fetchServicesData();
  }

  Future<void> fetchServicesData() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/services');

    try {
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          servicesData = data;
        });
      } else {
        _showErrorDialog(
            'Erreur lors de la récupération des services: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog('Une erreur s\'est produite: $error');
    }
  }

  Future<String> _fetchOAuthLink(int serviceId) async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/auth/services/$serviceId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final oauthLink = json.decode(response.body)['url'];
      if (oauthLink != null) {
        return oauthLink;
      } else {
        throw Exception('OAuth link is null');
      }
    } else {
      throw Exception('Failed to fetch OAuth link for service $serviceId');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage())),
        ),
        title: const Text("Create Area"),
        backgroundColor: Colors.grey[600],
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AreaListDialog();
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        hintText: 'Entrez un nom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          parameters['name'] = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Entrez un nom !.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Entrez une description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          parameters['description'] = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<dynamic>(
                      value: selectedService,
                      items: servicesData.map((service) {
                        return DropdownMenuItem<dynamic>(
                          value: service,
                          child: Text(service['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      hint: const Text("Sélectionnez un Service"),
                      onChanged: (dynamic value) async {
                        setState(() {
                          selectedService = value;
                          selectedReactionService = null;
                          parameters['actions'] = [];
                          parameters['reactions'] = [];
                        });
                        if (value['subscribable'] == true) {
                          String? oauthLink;
                          int id = value['id'];
                          try {
                            oauthLink = await _fetchOAuthLink(value['id']);
                            // ignore: unnecessary_null_comparison
                            if (oauthLink != null) {
                              // ignore: use_build_context_synchronously
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebViewPage(
                                      oauthLink:
                                          oauthLink ?? 'Valeur par défaut',
                                      id: id),
                                ),
                              );
                            } else {
                              _showErrorDialog('Le lien OAuth est nul.');
                            }
                          } catch (error) {
                            _showErrorDialog(
                                'Erreur lors de la récupération du lien OAuth: $error');
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Entrez un service.';
                        }
                        return null;
                      },
                    ),
                    if (selectedService != null)
                      DropdownButtonFormField<dynamic>(
                        value: selectedReactionService,
                        items: servicesData.map((service) {
                          return DropdownMenuItem<dynamic>(
                            value: service,
                            child: Text(service['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        hint: const Text("Sélectionnez un service"),
                        onChanged: (dynamic value) async {
                          setState(() {
                            selectedReactionService = value;
                            parameters['actions'] = [];
                            parameters['reactions'] = [];
                          });
                          if (value['subscribable'] == true) {
                            String? oauthLink;
                            int id = value['id'];
                            try {
                              oauthLink = await _fetchOAuthLink(value['id']);
                              // ignore: unnecessary_null_comparison
                              if (oauthLink != null) {
                                // ignore: use_build_context_synchronously
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebViewPage(
                                        oauthLink:
                                            oauthLink ?? 'Valeur par défaut',
                                        id: id),
                                  ),
                                );
                              } else {
                                _showErrorDialog('Le lien OAuth est nul.');
                              }
                            } catch (error) {
                              _showErrorDialog(
                                  'Erreur lors de la récupération du lien OAuth: $error');
                            }
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Entrez un service !';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (selectedService != null && selectedReactionService != null)
              Column(
                children: [
                  _buildActionDropdown(),
                  _buildReactionDropdown(),
                  _buildParameterFields(),
                ],
              ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _submitArea,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Créer une AREA"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDropdown() {
    if (selectedService != null) {
      final actions = selectedService['actions'] as List<dynamic>;
      final actionDropdownItems = actions.map((action) {
        return DropdownMenuItem<dynamic>(
          value: action,
          child: Text(action['name'] ?? 'Unknown'),
        );
      }).toList();

      return DropdownButtonFormField<dynamic>(
        value:
            parameters['actions'].isNotEmpty ? parameters['actions'][0] : null,
        items: actionDropdownItems,
        hint: const Text("Sélectionnez une Action"),
        onChanged: (dynamic value) {
          setState(() {
            parameters['actions'] = [value];
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Entrez une Action !';
          }
          return null;
        },
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildReactionDropdown() {
    if (selectedReactionService != null) {
      final reactions = selectedReactionService['reactions'] as List<dynamic>;
      final reactionDropdownItems = reactions.map((reaction) {
        return DropdownMenuItem<dynamic>(
          value: reaction,
          child: Text(reaction['name'] ?? 'Unknown'),
        );
      }).toList();

      return DropdownButtonFormField<dynamic>(
        value: parameters['reactions'].isNotEmpty
            ? parameters['reactions'][0]
            : null,
        items: reactionDropdownItems,
        hint: const Text("Sélectionnez une Reaction"),
        onChanged: (dynamic value) {
          setState(() {
            parameters['reactions'] = [value];
            parameters['reactionParameters'] = [];
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Entrez une Réaction.';
          }
          return null;
        },
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Widget _buildParameterField(dynamic param) {
    TextEditingController controller = _getControllerForParam(param);

    String type = param['type'];

    if (type.startsWith("selector:")) {
      List<String> options = type.substring(10, type.length - 1).split(', ');

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(param['name'] ?? 'Nom inconnu'),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: param['value'],
                decoration: const InputDecoration(
                  labelText: 'Choisir une option',
                  border: OutlineInputBorder(),
                ),
                items: options.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    param['value'] = newValue!;
                  });
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(param['name'] ?? 'Nom inconnu'),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                readOnly: param['type'] == 'date' || param['type'] == 'time',
                decoration: const InputDecoration(
                  labelText: 'Valeur',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                onTap: () async {
                  if (param['type'] == 'date') {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      param['value'] = date.toLocal().toString().split(' ')[0];
                      controller.text = param['value'];
                      setState(() {});
                    }
                  } else if (param['type'] == 'time') {
                    TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      param['value'] =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      controller.text = param['value'];
                      setState(() {});
                    }
                  }
                },
                onChanged: (value) {
                  setState(() {
                    final parts = value.split(' ');
                    param['value'] = parts[0];
                    controller.text = param['value'];
                  });
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  TextEditingController _getControllerForParam(dynamic param) {
    if (!_controllers.containsKey(param['name'])) {
      _controllers[param['name']] =
          TextEditingController(text: param['value'] ?? "");
    }
    return _controllers[param['name']]!;
  }

  Widget _buildActionParameterFields() {
    if (parameters['actions'].isNotEmpty) {
      final List<dynamic> selectedParameters =
          parameters['actions'][0]['parameters'];
      return Column(
        children: selectedParameters
            .map((param) => _buildParameterField(param))
            .toList(),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildReactionParameterFields() {
    if (parameters['reactions'].isNotEmpty) {
      final List<dynamic> selectedParameters =
          parameters['reactions'][0]['parameters'];
      return Column(
        children: selectedParameters
            .map((param) => _buildParameterField(param))
            .toList(),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildParameterFields() {
    List<Widget> fields = [];
    if (parameters['actions'].isNotEmpty) {
      fields.add(_buildActionParameterFields());
    }
    if (parameters['reactions'].isNotEmpty) {
      fields.add(_buildReactionParameterFields());
    }
    return Column(children: fields);
  }

  void _submitArea() async {
    if (_formKey.currentState!.validate()) {
      if (selectedReactionService == null) {
        _showErrorDialog('Veuillez sélectionner un service de réaction.');
        return;
      }

      Map<String, dynamic> areaJson = {
        'name': parameters['name'],
        'description': parameters['description'],
        'actions': [
          {
            "id": parameters['actions'][0]['id'],
            "name": parameters['actions'][0]['name'],
            "description": parameters['actions'][0]['description'],
            "service_id": parameters['actions'][0]['service_id'],
            'parameters':
                transformParameters(parameters['actions'][0]['parameters']),
            "outputs": []
          }
        ],
        'reactions': [
          {
            "id": parameters['reactions'][0]['id'],
            "name": parameters['reactions'][0]['name'],
            "description": parameters['reactions'][0]['description'],
            "service_id": parameters['reactions'][0]['service_id'],
            'parameters':
                transformParameters(parameters['reactions'][0]['parameters'])
          }
        ],
      };
      try {
        await submitArea(areaJson);
        Navigator.pop(context);
      } catch (error) {
        _showErrorDialog('Erreur lors de la soumission de l\'aire : $error');
      }
    }
  }

  List<Map<String, dynamic>> transformParameters(List<dynamic> parameters) {
    return parameters
        .map((param) => {
              "name": param['name'],
              "value": param['value'],
              "type": param['type'],
            })
        .toList();
  }

  Future<void> submitArea(Map<String, dynamic> areaJson) async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/area');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(areaJson),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        final areaName = parameters['name'];
        await storeAreaName(areaName);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()));
        _showErrorDialog("AREA créée avec Succès !");
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CreateAreaPage()));
        _showErrorDialog(
            'Erreur lors de la soumission de l\'aire : ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog(
          'Une erreur s\'est produite lors de la soumission: $error');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
