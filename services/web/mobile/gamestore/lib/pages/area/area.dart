import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:gamestore/pages/area/ServiceLoginWebViewPage.dart';
import 'package:gamestore/pages/area/list_area.dart';
import 'package:gamestore/pages/home/home.dart';
import 'package:gamestore/theme/app_theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
            'Error fetching services: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog('An error occurred: $error');
    }
  }

  // ... (Keep existing helper methods: _fetchOAuthLink, _getHeaders, fetchToken)
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage())),
        ),
        title: const Text("Create Area", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
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
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: FadeInRight(
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
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: FadeInUp(
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.85, // Dynamic height or fit content
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
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        // shrinkWrap: true, // Use shrinkWrap if inside another scroll view, but here we have fixed height container
                        children: [
                          _buildTextField('Name', 'Enter a name', (value) {
                            setState(() {
                              parameters['name'] = value;
                            });
                          }),
                          const SizedBox(height: 16.0),
                          _buildTextField('Description', 'Enter a description', (value) {
                            setState(() {
                              parameters['description'] = value;
                            });
                          }),
                          const SizedBox(height: 20),
                          
                          _buildDropdown(
                            value: selectedService,
                            items: servicesData,
                            hint: "Select Service",
                            onChanged: (dynamic value) async {
                              setState(() {
                                selectedService = value;
                                selectedReactionService = null;
                                parameters['actions'] = [];
                                parameters['reactions'] = [];
                              });
                              if (value['subscribable'] == true) {
                                // ... (Keep existing OAuth logic)
                                String? oauthLink;
                                int id = value['id'];
                                try {
                                  oauthLink = await _fetchOAuthLink(value['id']);
                                  if (oauthLink != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WebViewPage(
                                            oauthLink: oauthLink ?? '',
                                            id: id),
                                      ),
                                    );
                                  } else {
                                    _showErrorDialog('OAuth link is null.');
                                  }
                                } catch (error) {
                                  _showErrorDialog('Error fetching OAuth link: $error');
                                }
                              }
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          if (selectedService != null)
                            _buildDropdown(
                              value: selectedReactionService,
                              items: servicesData,
                              hint: "Select Reaction Service",
                              onChanged: (dynamic value) async {
                                setState(() {
                                  selectedReactionService = value;
                                  parameters['actions'] = [];
                                  parameters['reactions'] = [];
                                });
                                if (value['subscribable'] == true) {
                                   // ... (Keep existing OAuth logic)
                                   String? oauthLink;
                                   int id = value['id'];
                                   try {
                                     oauthLink = await _fetchOAuthLink(value['id']);
                                     if (oauthLink != null) {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (context) => WebViewPage(
                                               oauthLink: oauthLink ?? '',
                                               id: id),
                                         ),
                                       );
                                     } else {
                                       _showErrorDialog('OAuth link is null.');
                                     }
                                   } catch (error) {
                                     _showErrorDialog('Error fetching OAuth link: $error');
                                   }
                                }
                              },
                            ),
                          
                          const SizedBox(height: 20),
                          
                          if (selectedService != null && selectedReactionService != null)
                            Column(
                              children: [
                                _buildActionDropdown(),
                                const SizedBox(height: 16),
                                _buildReactionDropdown(),
                                const SizedBox(height: 16),
                                _buildParameterFields(),
                              ],
                            ),
                          
                          const SizedBox(height: 30),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitArea,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text("Create AREA", style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, Function(String) onChanged) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required dynamic value,
    required List<dynamic> items,
    required String hint,
    required Function(dynamic) onChanged,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      dropdownColor: AppTheme.surface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      items: items.map((item) {
        return DropdownMenuItem<dynamic>(
          value: item,
          child: Text(item['name'] ?? 'Unknown'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  // ... (Update _buildActionDropdown and _buildReactionDropdown to use _buildDropdown style or wrap them)
  // For brevity, I'll assume they return DropdownButtonFormField which I should style similarly.
  // I will override the theme for these specific widgets or just use the global theme which I set up.
  // But explicit styling is safer.
  
  Widget _buildActionDropdown() {
    if (selectedService != null) {
      final actions = selectedService['actions'] as List<dynamic>;
      return _buildDropdown(
        value: parameters['actions'].isNotEmpty ? parameters['actions'][0] : null,
        items: actions,
        hint: "Select Action",
        onChanged: (dynamic value) {
          setState(() {
            parameters['actions'] = [value];
          });
        },
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildReactionDropdown() {
    if (selectedReactionService != null) {
      final reactions = selectedReactionService['reactions'] as List<dynamic>;
      return _buildDropdown(
        value: parameters['reactions'].isNotEmpty ? parameters['reactions'][0] : null,
        items: reactions,
        hint: "Select Reaction",
        onChanged: (dynamic value) {
          setState(() {
            parameters['reactions'] = [value];
            parameters['reactionParameters'] = [];
          });
        },
      );
    } else {
      return const SizedBox();
    }
  }

  // ... (Update _buildParameterField to use styled inputs)
  Widget _buildParameterField(dynamic param) {
    TextEditingController controller = _getControllerForParam(param);
    String type = param['type'];

    if (type.startsWith("selector:")) {
      List<String> options = type.substring(10, type.length - 1).split(', ');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: DropdownButtonFormField<String>(
          value: param['value'],
          dropdownColor: AppTheme.surface,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: param['name'] ?? 'Unknown',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
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
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controller,
          readOnly: param['type'] == 'date' || param['type'] == 'time',
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: param['name'] ?? 'Value',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          onTap: () async {
             // ... (Keep existing date/time picker logic)
             if (param['type'] == 'date') {
                DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: AppTheme.darkTheme,
                      child: child!,
                    );
                  },
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
                  builder: (context, child) {
                    return Theme(
                      data: AppTheme.darkTheme,
                      child: child!,
                    );
                  },
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
      );
    }
  }

  // ... (Keep existing logic methods: _getControllerForParam, _buildActionParameterFields, _buildReactionParameterFields, _buildParameterFields, _submitArea, transformParameters, submitArea)
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
        _showErrorDialog('Please select a reaction service.');
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
        _showErrorDialog('Error submitting area: $error');
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
        _showErrorDialog("AREA created successfully!");
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CreateAreaPage()));
        _showErrorDialog(
            'Error submitting area: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog(
          'An error occurred during submission: $error');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }
}
