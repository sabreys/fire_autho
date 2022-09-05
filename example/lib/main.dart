import 'package:example/RaisedButton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fire_autho/fire_autho.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

// Copyright 2020 Sabrey (github.com/sabreys). All rights reserved.

// I showed all user functions in this example. I will improve code quality on later version.
// You can use directly after Firebase setup. I don't have mac so I did not control on IOS.

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //  !!!

  runApp(ChangeNotifierProvider(
      create: (context) => AuthManager(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Autho Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  AuthManager manager =
  AuthManager(); // Singleton class. initializing  is here.

  MyHomePage() {
    //  manager.setTwitterConsumerKeys("consumer_key","consumer_secret_key"); // if you will use twitter sign in. you must call this function.
  }

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final mailFieldController = TextEditingController();
  final passFieldController = TextEditingController();
  final resetFieldController = TextEditingController();

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

  String? _verificationId;
  final SmsAutoFill _autoFill = SmsAutoFill();

  @override
  void dispose() {
    mailFieldController.dispose();
    passFieldController.dispose();
    _phoneNumberController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: buildUserListener(),
                ),
                SizedBox(
                    width: 300,
                    child: TextField(
                      controller: mailFieldController,
                      decoration: InputDecoration(hintText: "mail"),
                    )),
                SizedBox(
                    width: 300,
                    child: TextField(
                        controller: passFieldController,
                        decoration: InputDecoration(hintText: "pass"))),
                buildMailPassSignIn(),
                buildMailPass(),
                buildAnonSignIn(),
                buildLogOut(),
                buildGoogleSignIn(),
                buildPhoneInput(),
                buildResetMailSection(),
                buildVerificationInput(),
                Container(
                  padding: const EdgeInsets.only(top: 16.0),
                  alignment: Alignment.center,
                  child: buildsignInWithPhoneNumber(),
                ),
                buildVerifyCodeButton(),
                kIsWeb
                    ? Container()
                    : buildGetNumberButton(), // detecting platform. only on mobile
                SizedBox(
                  height: 20,
                ),

                buildLinkMailAuth(),
                buildLinkPhoneAuth(),
                buildVerifyLinkPhoneAuth(),
                buildLinkGoogleAuth(),
                buildDeleteButton(),
                buildVerificationMailButton(),
                buildReloadButton(),
                buildReSignButton(),
                SizedBox(
                  height: 50,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding buildVerificationInput() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: TextFormField(
        controller: _smsController,
        decoration: const InputDecoration(labelText: 'Verification code'),
      ),
    );
  }

  Widget buildGetNumberButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.center,
      child: RaisedButton(
          child: Text("Get current number"),
          onPressed: () async =>
          {_phoneNumberController.text = (await _autoFill.hint)!},
          color: Colors.greenAccent[700]),
    );
  }

//TODO  it works. can be used.
  Widget buildStreamBuilder() {
    return Consumer<AuthManager>(
      builder: (context, cart, child) => Stack(
        children: [
          cart.auth != null
              ? StreamBuilder<User?>(
            stream: widget.manager.onAuthStateChanged,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                User? user = snapshot.data;
                if (user == null) {
                  return Text("No user");
                }
                return Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text("::" + widget.manager.user.toString()),
                );
              } else {
                return SizedBox(
                  height: 200,
                  width: 200,
                  child: Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
            },
          )
              : Text("No No No"),
        ],
      ),
      // Build the expensive widget here.
    );
  }

  // show user state
  Widget buildUserListener() {
    return Consumer<AuthManager>(
      builder: (context, userSnap, child) => Stack(
        children: [
          userSnap.auth != null
              ? Text(
              userSnap.user != null ? userSnap.user.toString() : "No user")
              : Text("No No No"),
        ],
      ),
      // Build the expensive widget here.
    );
  }

  Widget buildAnonSignIn() {
    return CustomRaisedButton(
      child: Text("Sign in anonymously"),
      onPressed: () async {
        AuthResponse response = await widget.manager.signInAnonymous();
        if (response.status == Status.Failed) {
          showSnack(response);
        }
        widget.manager.printAuthStats();
      },
    );
  }

  Widget buildMailPass() {
    return CustomRaisedButton(
      child: Text("Sign in"),
      onPressed: () async {
        AuthResponse response = await widget.manager.signInWithMailPass(
            mailFieldController.text, passFieldController.text);
        widget.manager.printAuthStats();
        if (response.status == Status.Failed) {
          showSnack(response);
        }
      },
    );
  }

  void showSnack(AuthResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Failed:" + response.message!),
    ));
  }

  Widget buildMailPassSignIn() {
    return CustomRaisedButton(
      child: Text("Sign Up"),
      onPressed: () async {
        AuthResponse response = await widget.manager.signUpWithMailPass(
            mailFieldController.text, passFieldController.text);
        widget.manager.printAuthStats();
        if (response.status == Status.Failed) {
          showSnack(response);
        }
      },
    );
  }

  Widget buildLogOut() {
    return CustomRaisedButton(
      child: Text("Log out"),
      onPressed: () async {
        await widget.manager.signOut();

      },
    );
  }

  Widget buildGoogleSignIn() {
    return CustomRaisedButton(
      child: Text("Sign in with Google"),
      onPressed: () async {
        AuthResponse response = await widget.manager.signInWithGoogle();
        if (response.status == Status.Failed) {
          showSnack(response);
        }
        widget.manager.printAuthStats();
      },
    );
  }

  // Widget buildTwitterSignIn() {
  //   return CustomRaisedButton(
  //     child: Text("Sign in with Twitter"),
  //     onPressed: () async {
  //       AuthResponse response = await widget.manager.signInWithTwitter();
  //       if (response.status == Status.Failed) {
  //         showSnack(response);
  //       }
  //       widget.manager.printAuthStats();
  //     },
  //   );
  // }

  Widget buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: TextFormField(
        controller: _phoneNumberController,
        decoration:
        const InputDecoration(labelText: 'Phone number (+xx xxx-xxx-xxxx)'),
      ),
    );
  }

  Widget buildVerifyCodeButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomRaisedButton(
        child: Text("Verify Code"),
        onPressed: () async {
          Provider.of<AuthManager>(context, listen: false).phoneCode =
              _smsController.text;
          if (!kIsWeb) {
            AuthResponse response =
            await Provider.of<AuthManager>(context, listen: false)
                .verifyPhoneSign(context, _smsController.text);

            if (response.status != Status.Successed) {
              showSnack(response);
            }
          } else {
            AuthResponse response =
            await Provider.of<AuthManager>(context, listen: false)
                .verifyPhoneSignForWeb(_smsController.text);
            if (response.status != Status.Successed) {
              showSnack(response);
            }
          }
        },
      ),
    );
  }

  Widget buildsignInWithPhoneNumber() {
    return CustomRaisedButton(
      child: Text("Sign in With Phone Number"),
      onPressed: () async {
        AuthResponse response = await widget.manager
            .signInWithPhone(_phoneNumberController.text, context);
        if (response.status != Status.Successed) {
          showSnack(response);
        }
        widget.manager.printAuthStats();
      },
    );
  }

  Widget buildResetMailSection() {
    return Container(
      width: 300,
      height: 200,
      child: Column(
        children: [
          TextField(
            controller: resetFieldController,
            decoration: InputDecoration(hintText: "Reset Mail"),
          ),
          FlatButton(
            onPressed: () async {
              AuthResponse? response =
              await Provider.of<AuthManager>(context, listen: false)
                  .sendPasswordResetEmail(resetFieldController.text);
              if (response!.status != Status.Successed) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(":" + response.message!),
                ));
              } else {
                showSnack(response);
              }
            },
            child: Text("Send Reset Mail"),
          ),
        ],
      ),
    );
  }

  Widget buildLinkMailAuth() {
    return CustomRaisedButton(
        onPressed: () async {
          AuthResponse response = await widget.manager
              .linkCredentialWithEmailPass(
              mailFieldController.text, passFieldController.text);
          widget.manager.printAuthStats();
          if (response.status == Status.Failed) {
            showSnack(response);
          }
        },
        child: Text("LinkWithEmailPass"));
  }

  Widget buildLinkPhoneAuth() {
    return CustomRaisedButton(
      child: Text("Link With Phone"),
      onPressed: () async {
        AuthResponse response = await widget.manager
            .linkCredentialWithPhone(_phoneNumberController.text, context);
        widget.manager.printAuthStats();

        showSnack(response);
      },
    );
  }

  Widget buildVerifyLinkPhoneAuth() {
    return CustomRaisedButton(
      child: Text("Verify Link Phone "),
      onPressed: () async {
        AuthResponse response = await widget.manager
            .verifyLinkCredentialWithPhone(_smsController.text);
        widget.manager.printAuthStats();

        showSnack(response);
      },
    );
  }

  Widget buildLinkGoogleAuth() {
    return CustomRaisedButton(
        onPressed: () async {
          AuthResponse response =
          await widget.manager.linkCredentialWithGoogle();
          widget.manager.printAuthStats();
          if (response.status == Status.Failed) {
            showSnack(response);
          }
        },
        child: Text("Link Google Account"));
  }
  //
  // Widget buildLinkTwitterAuth() {
  //   return CustomRaisedButton(
  //       onPressed: () async {
  //         AuthResponse response =
  //             await widget.manager.linkCredentialWithTwitter();
  //         widget.manager.printAuthStats();
  //         if (response.status == Status.Failed) {
  //           showSnack(response);
  //         }
  //       },
  //       child: Text("Link Twitter Account"));
  // }

  Widget buildDeleteButton() {
    return CustomRaisedButton(
        onPressed: () async {
          AuthResponse response = await widget.manager.deleteUser();
          widget.manager.printAuthStats();
          if (response.status == Status.Failed) {
            showSnack(response);
          }
        },
        child: Text("Delete Account"));
  }

  Widget buildVerificationMailButton() {
    return CustomRaisedButton(
        onPressed: () async {
          AuthResponse response = await widget.manager.sendEmailVerification();
          widget.manager.printAuthStats();
          if (response.status == Status.Failed) {
            showSnack(response);
          }
        },
        child: Text("Send Verification Email"));
  }

  Widget buildReloadButton() {
    return CustomRaisedButton(
        onPressed: () async {
          AuthResponse response = await widget.manager.reloadUser();
          widget.manager.printAuthStats();
          if (response.status == Status.Failed) {
            showSnack(response);
          }
        },
        child: Text("Reload"));
  }

  Widget buildReSignButton() {
    return CustomRaisedButton(
        onPressed: () async {
          AuthResponse response = await widget.manager.reSignWithCredential();
          widget.manager.printAuthStats();
          if (response.status == Status.Failed) {
            showSnack(response);
          }
        },
        child: Text("ReSign"));
  }
}
