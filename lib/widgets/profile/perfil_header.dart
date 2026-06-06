import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';

class PerfilHeader extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onAvatarTap;

  const PerfilHeader({
    Key? key,
    required this.user,
    required this.onAvatarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.only(top: 48.0, bottom: 32.0, left: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: user.fotoUrl != null ? NetworkImage(user.fotoUrl!) : null,
                  child: user.fotoUrl == null
                      ? Text(
                          user.nombreCompleto.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6D00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nombreCompleto,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.rolGlobal,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
