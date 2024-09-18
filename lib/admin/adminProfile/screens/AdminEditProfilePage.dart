import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/constants/AppColor_constants.dart';
import 'package:project/constants/globalObjects.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_bloc.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_state.dart';
import '../../../Sqlite/admin_sqliteHelper.dart';
import '../../../constants/AnimatedTextPopUp.dart';
import '../../../No_internet/no_internet.dart';
import '../../../responsive/responsive_layout.dart';
import '../models/AdminEditProfileModel.dart';
import '../models/AdminEditProfileRepository.dart';

class AdminEditProfilePage extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback? onSaveSuccess; // Define the onSaveSuccess callback

  const AdminEditProfilePage({super.key, required this.onSave, this.onSaveSuccess});

  @override
  State<AdminEditProfilePage> createState() =>
      _AdminEditProfilePageState(onSave);
}

class _AdminEditProfilePageState extends State<AdminEditProfilePage>
    with TickerProviderStateMixin {
  final VoidCallback onSave;

  _AdminEditProfilePageState(this.onSave);
  late AnimationController addToCartPopUpAnimationController;

  final TextEditingController _usernameController =
      TextEditingController(text: GlobalObjects.adminusername);
  final TextEditingController _passwordController =
      TextEditingController(text: GlobalObjects.adminpassword);
  final TextEditingController _emailController =
      TextEditingController(text: GlobalObjects.adminMail);
  final TextEditingController _phoneNumberController =
      TextEditingController(text: GlobalObjects.adminphonenumber);
  final AdminEditProfileRepository _editProfileRepository =
      AdminEditProfileRepository('http://62.171.184.216:9595');
  @override
  void initState() {
    addToCartPopUpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    super.initState();
  }

  @override
  void dispose() {
    addToCartPopUpAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _submitForm() async {
    final dbHelper = AdminDatabaseHelper();
    final adminList = await dbHelper.getAdmins();

    if (adminList.isNotEmpty) {
      final adminData = adminList.first;
      final adminEditProfile = AdminEditProfile(
        userLoginId: adminData['username'].toString(),
        userName: _usernameController.text,
        userPassword: _passwordController.text,
        email: _emailController.text,
        mobile: _phoneNumberController.text,
      );

      final success =
          await _editProfileRepository.updateAdminProfile(adminEditProfile);

      if (success) {
        GlobalObjects.adminphonenumber = adminEditProfile.mobile;
        GlobalObjects.adminMail = adminEditProfile.email;
        GlobalObjects.adminusername = adminEditProfile.userName;
        GlobalObjects.adminpassword = adminEditProfile.userPassword;

        addToCartPopUpAnimationController.forward();

        Timer(const Duration(seconds: 3), () {
          addToCartPopUpAnimationController.reverse();
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context, true);
          }
        });
        showPopupWithSuccessMessage("Profile updated successfully!");
        onSave();

        widget.onSaveSuccess?.call();
      } else {
        addToCartPopUpAnimationController.forward();
        Timer(const Duration(seconds: 3), () {
          addToCartPopUpAnimationController.reverse();
          if (mounted) {
            Navigator.pop(context, false);
          }
        });
        showPopupWithFailedMessage("Failed to update profile!");
      }
    }

    return false; // Return false if form validation fails
  }

  bool isInternetLost = false;

  void showPopupWithSuccessMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return addToCartPopUpSuccess(
            addToCartPopUpAnimationController, message);
      },
    );
  }

  void showPopupWithFailedMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return addToCartPopUpFailed(addToCartPopUpAnimationController, message);
      },
    );
  }

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetBloc, InternetStates>(
      listener: (context, state) {
        if (state is InternetLostState) {
          isInternetLost = true;
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.push(
              context,
              PageTransition(
                child: const NoInternet(),
                type: PageTransitionType.rightToLeft,
              ),
            );
          });
        } else if (state is InternetGainedState && isInternetLost) {
          Navigator.pop(context);
          isInternetLost = false;
        }
      },
      builder: (context, state) {
        if (state is InternetGainedState) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Edit Profile',
                style: AppBarStyles.appBarTextStyle,
              ),
              backgroundColor: AppBarStyles.appBarBackgroundColor,
              iconTheme:
                  const IconThemeData(color: AppBarStyles.appBarIconColor),
              centerTitle: true,
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: ResponsiveLayout.contentPadding(context),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              alignment: Alignment.topCenter,
                              child: Image.asset(
                                'assets/icons/userrr.png',
                                height: ResponsiveLayout.isSmallScreen(context)
                                    ? 100
                                    : 200,
                                width: ResponsiveLayout.isSmallScreen(context)
                                    ? 100
                                    : 200,
                              ),
                            ),
                            SizedBox(
                                height: ResponsiveLayout.isSmallScreen(context)
                                    ? 20
                                    : 30),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible =
                                          !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text('Submit',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
