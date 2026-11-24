import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withText;

  const AppLogo({super.key, this.size = 80, this.withText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primario,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primario.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.campaign_outlined,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
        if (withText) ...[
          const SizedBox(height: 12),
          Text(
            AppConstants.appNome,
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              color: AppColors.primario,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.appSubtitulo,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.cinza,
            ),
          ),
        ],
      ],
    );
  }
}