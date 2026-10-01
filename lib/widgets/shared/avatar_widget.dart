import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final bool hasBorder;
  
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetwork = imageUrl != null && imageUrl!.startsWith('http');
    bool isAsset = imageUrl != null && !imageUrl!.startsWith('http');

    ImageProvider? imageProvider;
    if (isNetwork) {
      imageProvider = NetworkImage(imageUrl!);
    } else if (isAsset && imageUrl!.isNotEmpty) {
      imageProvider = AssetImage(imageUrl!);
    }

    return Container(
      decoration: hasBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.0),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(
                Icons.person,
                size: radius,
                color: Colors.grey.shade400,
              )
            : null,
      ),
    );
  }
}
