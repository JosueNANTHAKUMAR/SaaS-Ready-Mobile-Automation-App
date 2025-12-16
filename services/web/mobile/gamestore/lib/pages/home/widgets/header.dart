import 'package:flutter/material.dart';
import 'package:gamestore/theme/app_theme.dart';

class HeaderSection extends StatelessWidget {
  final VoidCallback onAvatarTap;

  const HeaderSection({Key? key, required this.onAvatarTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Josué', // TODO: Get real user name
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          InkWell(
            onTap: onAvatarTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/logo.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
