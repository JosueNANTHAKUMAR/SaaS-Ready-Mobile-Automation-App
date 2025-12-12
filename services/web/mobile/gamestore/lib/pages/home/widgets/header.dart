import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final VoidCallback onAvatarTap;

  const HeaderSection({Key? key, required this.onAvatarTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 25,
        right: 25,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 30),
                child: Text(
                  'Accueil',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 5),
              Text(
                '',
                style: TextStyle(color: Colors.white, fontSize: 16),
              )
            ],
          ),
          InkWell(
            onTap: onAvatarTap,
            child: CircleAvatar(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
