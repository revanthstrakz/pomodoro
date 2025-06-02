import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();

  // Password change controllers
  late final TextEditingController currentPasswordController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;

  // Profile update controllers
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    // Always dispose our own controllers
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }
}
