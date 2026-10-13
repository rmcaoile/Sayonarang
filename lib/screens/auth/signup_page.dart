import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'dart:io';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  late TabController tabController;

  // text controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumController = TextEditingController();
  final List<TextEditingController> otherAddressesControllers = [];

  bool _nameValid = true;
  bool _usernameValid = true;
  bool _emailValid = true;
  bool _passwordValid = true;
  bool _addressValid = true;
  bool _contactNumValid = true;
  bool _proofValid = true;
  bool _obscureText = true;

  List<Widget> addressFields = [];

  File? selectedProof; // full path of the selected file
  String proofFilename = ""; // for displaying filename in the text field
  String? finalFilename; // filename of proof saved in the firebase

  RegExp get _emailRegex =>
      RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$');

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        setState(() {
          _nameValid = true;
        });
      }
    });

    _usernameController.addListener(() {
      if (_usernameController.text.isNotEmpty) {
        setState(() {
          _usernameValid = true;
        });
      }
    });

    _emailController.addListener(() {
      if (_emailController.text.isNotEmpty) {
        setState(() {
          _emailValid = true;
        });
      }
    });

    _passwordController.addListener(() {
      if (_passwordController.text.isNotEmpty) {
        setState(() {
          _passwordValid = true;
        });
      }
    });

    _addressController.addListener(() {
      if (_addressController.text.isNotEmpty) {
        setState(() {
          _addressValid = true;
        });
      }
    });

    _contactNumController.addListener(() {
      if (_contactNumController.text.isNotEmpty) {
        setState(() {
          _contactNumValid = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _contactNumController.dispose();
    super.dispose();
  }

  Widget signupButton() {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () async {
              setState(() {
                _nameValid = _nameController.text.isNotEmpty;
                _usernameValid = _usernameController.text.isNotEmpty;
                _emailValid = _emailController.text.isNotEmpty &&
                    _emailRegex.hasMatch(_emailController.text);
                _passwordValid = _passwordController.text.isNotEmpty &&
                    _passwordController.text.length >= 6;
                _addressValid = _addressController.text.isNotEmpty;
                _contactNumValid = _contactNumController.text.isNotEmpty;
                _proofValid =
                    (proofFilename.isNotEmpty && tabController.index == 1) ||
                        (tabController.index == 0);
              });

              // validate text fields
              if (_nameValid &&
                  _usernameValid &&
                  _emailValid &&
                  _passwordValid &&
                  _addressValid &&
                  _contactNumValid &&
                  _proofValid) {
                // get the addresses from the text controllers
                List<String> addresses = [_addressController.text];
                for (TextEditingController controller
                    in otherAddressesControllers) {
                  if (controller.text.isNotEmpty) {
                    addresses.add(controller.text);
                  }
                }

                final myAuthProvider = context.read<MyAuthProvider>();

                if (selectedProof != null) {
                  // upload file to firebase storage
                  finalFilename =
                      await myAuthProvider.uploadFile(selectedProof!);
                }

                await myAuthProvider.signUp(
                    _nameController.text,
                    _usernameController.text,
                    _emailController.text,
                    _passwordController.text,
                    _contactNumController.text,
                    addresses,
                    finalFilename ?? '',
                    tabController.index == 0 ? 'donor' : 'org');

                // check if sign up is successful
                if (myAuthProvider.signupStatus['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully signed up!'),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Error: ${myAuthProvider.signupStatus['response']}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Already have an account?'),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Log In',
              ))
        ]),
      ],
    );
  }

  Widget signUpDonor() {
    return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            textField('Name', _nameController, false, _nameValid,
                'Please enter your name'),
            textField('Username', _usernameController, false, _usernameValid,
                'Please enter your username'),
            textField('Email', _emailController, false, _emailValid,
                'Please enter a valid email'),
            textField('Password', _passwordController, true, _passwordValid,
                'Password must be six or more characters'),
            textField('Contact Number', _contactNumController, false,
                _contactNumValid, 'Please enter your contact number'),
            textField('Address', _addressController, false, _addressValid,
                'Please enter your address'),
            ...addressFields,
            TextButton(
              onPressed: () {
                // new text controller for the new address field
                TextEditingController newAddressController =
                    TextEditingController();

                setState(() {
                  // add the new address widget to the list
                  addressFields.add(
                    Row(
                      children: [
                        Expanded(
                            child: textField('Address', newAddressController,
                                false, true, '')),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              int index = otherAddressesControllers
                                  .indexOf(newAddressController);
                              otherAddressesControllers.removeAt(index);
                              addressFields.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );

                  // add the new text controller to the list
                  otherAddressesControllers.add(newAddressController);
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 5),
                  Text('Add Address'),
                ],
              ),
            ),

            const SizedBox(height: 10), // spacing purposes
            signupButton(),
          ],
        ));
  }

  Widget signUpOrganization() {
    return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            textField('Name of Organization', _nameController, false,
                _nameValid, 'Please enter your name'),
            textField('Username', _usernameController, false, _usernameValid,
                'Please enter your username'),
            textField('Email', _emailController, false, _emailValid,
                'Please enter a valid email'),
            textField('Password', _passwordController, true, _passwordValid,
                'Password must be six or more characters'),
            textField('Contact Number', _contactNumController, false,
                _contactNumValid, 'Please enter your contact number'),
            textField('Address', _addressController, false, _addressValid,
                'Please enter your address'),

            // additional address fields
            ...addressFields,

            // button for adding additional address
            TextButton(
              onPressed: () {
                // new text controller for the new address field
                TextEditingController newAddressController =
                    TextEditingController();

                setState(() {
                  // add the new address widget to the list
                  addressFields.add(
                    Row(
                      children: [
                        Expanded(
                            child: textField('Address', newAddressController,
                                false, true, '')),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              int index = otherAddressesControllers
                                  .indexOf(newAddressController);
                              otherAddressesControllers.removeAt(index);
                              addressFields.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );

                  // add the new text controller to the list
                  otherAddressesControllers.add(newAddressController);
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 5),
                  Text('Add Address'),
                ],
              ),
            ),

            // proof of legitimacy
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: TextField(
                controller: TextEditingController(text: proofFilename),
                readOnly: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(bottom: 5),
                  labelText: 'Proof of Legitimacy',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  errorText: _proofValid ? null : 'Please upload an image',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.file_upload,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () async {
                      // select an image from the gallery
                      selectedProof = await context
                          .read<MyAuthProvider>()
                          .getImageFromGallery(context);

                      // check if there's a selected image
                      if (selectedProof != null) {
                        // print(selectedProof.path.split("/").last);
                        setState(() {
                          proofFilename = selectedProof!.path.split("/").last;
                          _proofValid = true;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

            // button for signing up
            signupButton(),
          ],
        ));
  }

  Widget textField(String label, TextEditingController textController,
      bool isPassword, bool isValid, String errorMessage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        obscureText: isPassword ? _obscureText : false,
        decoration: InputDecoration(
          labelText: label,
          errorText: isValid ? null : errorMessage,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
        controller: textController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        toolbarHeight: MediaQuery.of(context).size.height * 0.05,
        automaticallyImplyLeading: false, // remove back button
      ),
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.95,
          child: Card(
            color: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40))),
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 40, bottom: 10, left: 16, right: 16),
              child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const Text('Create an Account',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 20), // spacing purposes

                    // container for tab bar
                    Container(
                      child: TabBar(
                        controller: tabController,
                        dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        tabs: const [
                          Tab(text: 'As a Donor'),
                          Tab(text: 'As an Organization'),
                        ],
                      ),
                    ),

                    // container for contents of tab bar
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: TabBarView(
                        controller: tabController,
                        children: [signUpDonor(), signUpOrganization()],
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
