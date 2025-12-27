import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/Screens/Home/importantfunc.dart';
import 'package:production/variables.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  TextEditingController reneterpassword = TextEditingController();
  TextEditingController currentpassword = TextEditingController();
  TextEditingController newpassword = TextEditingController();
  bool isloading = false;

  Future<void> changepassword() async {
    setState(() {
      isloading = true;
    });
    final url =
        Uri.parse('https://vgate.vframework.in/vgateapi/processSessionRequest');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'mAgpajsKo9pVRfBicuVsGkzZG986GWPpxfGpbR9A2ysD1WGBMyqj2gL4NTftf7VABJvOG5KZ9iTW4ybk3oYbnO32oL+b08Ba9MW5pRlI6HaDbOb9pU4iH4VxGB79hQS+27ZzZuTOa9a4e8FrO3ASPC4B21zbSa19fJg1elJ/QK/PkA435B0vpMPKmp4vxfy0/tOEuO3yk5OuykSdwjBHoylNcqeZ2YeUaKeO5W9RwdfKDNMA50GTKxK80PrNQ7RlHJHuYH1NuO84hOvinlrITWc/+MPut0ePT14GyygBCVhRfWioIp3Qyxd+QENfFgqc7UwX8Q8MWERGf5uybUU1Pg==',
        'VSID': loginresponsebody!['vsid']
      },
      body: jsonEncode(<String, dynamic>{
        "vuid": loginresult!['vuid'],
        "mobileNumber": loginresult!['mobileNumber'].toString(),
        "password": currentpassword.text,
        "newpassword": newpassword.text
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        isloading = false;
      });
      showsuccessPopUpSync(context, "Password changed", () {});

      currentpassword.clear();
      newpassword.clear();
      _popScreenAfterDelay();
    } else {
      showSimplePopUp(
        context,
        "Failed to change the password",
      );
    }
  }

  void _submitData() {
    if (newpassword.text == reneterpassword.text) {
      // Validate the current password and new password
      if (currentpassword.text.isNotEmpty && newpassword.text.isNotEmpty) {
        changepassword();
      } else {
        showSimplePopUp(
          context,
          "Please fill in all fields",
        );
      }
    } else {
      showSimplePopUp(
        context,
        "Passwords don't match",
      );
    }
  }

  void _popScreenAfterDelay() {
    // Add a small delay before popping the screen to avoid context issues
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close the screen
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Pop screen
                        },
                        child: Icon(Icons.arrow_back_ios)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 75, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Password',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your new password must be different from previous used passwords',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Enter Current Password',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(controller: currentpassword),
                    const SizedBox(height: 20),
                    const Text(
                      'Enter New Password',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(controller: newpassword),
                    const SizedBox(height: 20),
                    const Text(
                      'Re-enter Password',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(controller: reneterpassword),
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: _submitData,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: isloading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Change Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller}) {
    return SizedBox(
      height: 50,
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          labelText: controller == currentpassword
              ? 'Current Password'
              : controller == newpassword
                  ? 'New Password'
                  : 'Re-enter Password',
        ),
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
