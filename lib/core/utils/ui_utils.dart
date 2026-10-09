import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UiUtils {
  static void showTopSnackBar(BuildContext context, String message, {bool isError = true}) {
    final bottomMargin = MediaQuery.of(context).size.height - 150;
    final snackBar = SnackBar(
      content: Text(
        message, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
      ),
      backgroundColor: isError ? Colors.redAccent : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: bottomMargin > 0 ? bottomMargin : 100, // pushes it to the top
        left: 20,
        right: 20,
      ),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
