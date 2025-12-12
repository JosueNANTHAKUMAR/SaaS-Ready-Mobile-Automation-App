import 'package:flutter/material.dart';

class ServicePage extends StatelessWidget {
  final List<String> serviceList;

  const ServicePage({super.key, required this.serviceList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'Services',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[300],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: serviceList.length,
        itemBuilder: (context, index) {
          final service = serviceList[index];
          return GestureDetector(
            onTap: () {
              if (service == "Plannifier") {
                _navigateToDateTimePickerPage(context);
              } else {
                Navigator.of(context).pop(service);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.info,
                  color: Colors.black,
                ),
                title: Text(service),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDateTimePickerPage(BuildContext context) async {
  }
}
