import 'package:flutter/material.dart';

class RouteSelector extends StatelessWidget {
  const RouteSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Load actual routes from service
    final routes = [
      {'id': '1', 'name': 'Central Park Loop', 'distance': '5.2 km'},
      {'id': '2', 'name': 'Riverside Walk', 'distance': '3.8 km'},
      {'id': '3', 'name': 'Beach Trail', 'distance': '7.1 km'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Route',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...routes.map((route) {
            return ListTile(
              leading: const Icon(Icons.route),
              title: Text(route['name']!),
              subtitle: Text(route['distance']!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context, route['id']);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

