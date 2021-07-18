library fire_autho;

import 'package:firebase_auth_oauth/firebase_auth_oauth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
export 'fire_autho.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:tw_login/tw_login.dart';

/// AuthManager class helps to creating and managing Firebase Auth user.
/// Supported platforms: Android ,IOS , Web
/// This class is singleton.
/// You can call with AuthManager(). or with Provider.
/// Be sure to ensureInitialized() is called.
class AuthManager extends ChangeNotifier {
  static final AuthManager _AuthManager = AuthManager._internal();

  ///sigleton instance

  String localeInfo = "tr";

  User user;
  FirebaseAuth auth;
  Persistence persistenceState = Persistence.LOCAL;
  bool phoneCodeListen = false;
  String phoneCode;
  static const PHONE_VERIFY_DELAY = 20;
  bool indicatorOn = false;
  String _verificationId;
  ConfirmationResult _confirmationResult;
  bool verifyErrorMobile = false;
  GoogleSignInAuthentication googleAuth;

  AuthCredential _credential;
  AuthCredential _googleCredential;
  String consumerKey;
  String consumerSecretKey;

  bool _initialized = false;

  factory AuthManager() {
    return _AuthManager;
  }

  /// singleton constructer.
  AuthManager._internal() {}

  /// initializer. Bu sure it is called.
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      print("AuthManager initializing...");
      await Firebase.initializeApp().whenComplete(() {
        auth = FirebaseAuth.instance;
        user = FirebaseAuth.instance.currentUser;
        listenUser();
        notifyListeners();
        _initialized = true;
        print("AuthManager initialized.");
      });
    }
  }

  /// set locale for set popup language.
  void setLocale(String locale) {
    localeInfo = locale;
  }

  /// set persistence.  Persistence.LOCAL  Persistence.SESSION Persistence.NONE
  Future<void> setPersistence(Persistence persistence) async {
    await FirebaseAuth.instance.setPersistence(persistence);
  }

  Future<void> signOut() async {
    if (user == null) {
      print("There is no user.");
      return;
    }
    print("logging out...");
    await auth.signOut().whenComplete(() {
      user = null;
      notifyListeners();
    });
  }

  /// Listen for user changes.
  Stream<User> get onAuthStateChanged => auth.authStateChanges();

  Future<AuthResponse> signInAnonymous() async {
    FirebaseAuthException errorEx;

    UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously().catchError((error) {
      errorEx = error;
      print(getMessageFromErrorCode(errorEx.code) +
          ":" +
          error.toString() +
          ":" +
          error.code);
    });
    if (errorEx != null) {
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    }
    user = userCredential.user;
    notifyListeners();
    if (user != null) {
      print(" anonim giriş yapıldı");
    }
    return AuthResponse(Status.Successed, "Successed.");
  }

  Future<AuthResponse> signInWithMailPass(String mail, String pass) async {
    FirebaseAuthException errorEx;

    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: mail, password: pass)
        .catchError((error) {
      errorEx = error;
      print(getMessageFromErrorCode(errorEx.code) +
          ":" +
          error.toString() +
          ":" +
          error.code);
    });
    if (errorEx != null) {
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    }
    user = userCredential.user;
    notifyListeners();
    if (user != null) {
      print(" logged in with mail pass ");
    }

    _credential = EmailAuthProvider.credential(email: mail, password: pass);

    return AuthResponse(Status.Successed, "Successed.");
  }

  Future<AuthResponse> signUpWithMailPass(String mail, String pass) async {
    FirebaseAuthException errorEx;
    UserCredential userCredential = await auth
        .createUserWithEmailAndPassword(email: mail, password: pass)
        .catchError((error) {
      errorEx = error;
      print(getMessageFromErrorCode(errorEx.code) +
          ":" +
          error.toString() +
          ":" +
          error.code);
    });
    if (errorEx != null) {
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    }
    user = userCredential.user;
    notifyListeners();
    _credential = EmailAuthProvider.credential(email: mail, password: pass);
    return AuthResponse(Status.Successed, "Successed.");
  }

  /// it can cost much. be carefull
  Future<AuthResponse> signInWithPhone(
      String number, BuildContext context) async {
    if (number == null) {
      return AuthResponse(Status.Failed, "Type your number.", "-1");
    }
    if (kIsWeb) {
      // detect platform
      return await phoneSignInOnWeb(number);
    } else {
      return await phoneSignInOnMobile(number, context);
    }
  }

  /// sign in and sign up with google.this can work with mobile and web
  Future<AuthResponse> signInWithGoogle() async {
    if (kIsWeb) {
      // detect platform
      return await googleSignInOnWeb();
    } else {
      return await googleSignInOnMobile();
    }
  }

  /// call signInWithGoogle() instead.
  Future<AuthResponse> googleSignInOnWeb() async {
    FirebaseAuthException errorEx;

    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider
        .addScope('https://www.googleapis.com/auth/contacts.readonly');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    UserCredential temp = await FirebaseAuth.instance
        .signInWithPopup(googleProvider)
        .catchError((error) {
      errorEx = error;
    });
    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    _googleCredential = temp.credential;
    _credential = temp.credential;
    user = temp.user;
    notifyListeners();
    return AuthResponse(Status.Successed, "successed.");
  }

  /// call signInWithGoogle() instead.
  Future<AuthResponse> googleSignInOnMobile() async {
    FirebaseAuthException errorEx;
    GoogleSignInAccount googleUser;
    PlatformException error;
    try {
      googleUser = await GoogleSignIn().signIn();
    } catch (e) {
      error = e;
    }
    if (error != null) return (AuthResponse(Status.Failed, error.toString()));
    if (googleUser == null) return (AuthResponse(Status.Failed, "Canceled."));

    googleAuth = await googleUser.authentication;

    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential credential2 = await FirebaseAuth.instance
        .signInWithCredential(credential)
        .catchError((error) {
      errorEx = error;
      print(getMessageFromErrorCode(errorEx.code) +
          ":" +
          error.toString() +
          ":" +
          error.code);
    });
    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    _credential = credential;
    _googleCredential = credential;
    user = credential2.user;
    return AuthResponse(Status.Successed, "successed.");
  }

  /// be sure twitter token is not null. call setTwitterConsumerKeys on starting.
  Future<AuthResponse> signInWithTwitter() async {
    if (kIsWeb) {
      // detect platform
      return await twitterSignInOnWeb();
    } else {
      return await twitterSignInOnMobile();
    }
  }

  /// call signInWithTwitter()  instead.
  Future<AuthResponse> twitterSignInOnWeb() async {
    FirebaseAuthException errorEx;

    TwitterAuthProvider twitterProvider = TwitterAuthProvider();

    UserCredential temp = await FirebaseAuth.instance
        .signInWithPopup(twitterProvider)
        .catchError((error) {
      errorEx = error;
      print(error);
    });
    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    _credential = temp.credential;
    user = temp.user;
    return AuthResponse(Status.Successed, "successful.");
  }

  /// call signInWithTwitter()  instead.
  Future<AuthResponse> twitterSignInOnMobile() async {
    assert(consumerKey != null && consumerSecretKey != null,
        " Please call  setTwitterConsumerKeys() before using twitter SignIn.");

    FirebaseAuthException errorEx;
    NoSuchMethodError exception;

    final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: consumerKey,
      consumerSecret: consumerSecretKey,
    );
    AuthCredential twitterAuthCredential;

    try {
      final TwitterLoginResult loginResult = await twitterLogin.authorize();

      final TwitterSession twitterSession = loginResult.session;

      twitterAuthCredential = TwitterAuthProvider.credential(
          accessToken: twitterSession.token, secret: twitterSession.secret);
    } catch (e) {
      exception = e;
      print(e.toString());
    }
    if (exception != null)
      return (AuthResponse(Status.Failed, exception.toString()));
    if (twitterAuthCredential == null)
      return (AuthResponse(Status.Failed, "fail."));

    UserCredential credential2 = await FirebaseAuth.instance
        .signInWithCredential(twitterAuthCredential)
        .catchError((error) {
      errorEx = error;
      print(getMessageFromErrorCode(errorEx.code) +
          ":" +
          error.toString() +
          ":" +
          error.code);
    });
    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    _credential = twitterAuthCredential;
    user = credential2.user;
    return AuthResponse(Status.Successed, "successed.");
  }

  /// it will send a link to mail for reset password directly.
  Future<AuthResponse> sendPasswordResetEmail(String email) async {
    var errorEx;
    AuthResponse response;

    if (email == null || email == "")
      return AuthResponse(Status.Failed, "Empty Mail.");

    await auth.sendPasswordResetEmail(email: email).catchError((error) {
      errorEx = error;
    }).whenComplete(() {
      response = AuthResponse(
          Status.Successed, "Successed.Please check your mail adress.");
    });

    if (errorEx != null)
      response = AuthResponse(Status.Failed, errorEx.message);

    return response;
  }

  /// if you will use twitter sign in method. you need to initialize consumer keys.
  /// https://developer.twitter.com/en
  void setTwitterConsumerKeys(String consumerKey, String consumerSecretKey) {
    assert(consumerKey != null && consumerSecretKey != null);
    this.consumerKey = consumerKey;
    this.consumerSecretKey = consumerSecretKey;
  }

  /// show to currenct user datas
  void printAuthStats() {
    print("UserDatas :" + _nullTerminator(user.toString()));
    /* print("is anon:"+nullTerminator(user.isAnonymous.toString()));
    print(nullTerminator("uid:"+user.uid));
    print("display name:"+nullTerminator(user.displayName));
    print("mail:"+nullTerminator(user.email));
    print("number:"+nullTerminator(user.phoneNumber));
    print("verified mail? :"+nullTerminator(user.emailVerified.toString()));
    print("metadata :"+nullTerminator(user.metadata.toString()));
    print("photoURL :"+nullTerminator(user.photoURL));
    print("runtimetype :"+nullTerminator(user.runtimeType.toString()));*/
  }

  /// it returns current user
  User checkIsUserExist() {
    if (auth != null && auth.currentUser != null) {
      return auth.currentUser;
    }
    return null;
  }

  /// listen user changes and change user field. don't call this
  void listenUser() async {
    auth.authStateChanges().listen((user) {
      this.user = user;
      print("Listen user: user changed.");
      notifyListeners();
    });
  }

  /// this method for null string parsing.
  String _nullTerminator(var degisken) {
    if (degisken != null) {
      return degisken;
    } else {
      return "-";
    }
  }

  /// firebase auth error code detector. it returns error messages.
  String getMessageFromErrorCode(String errorCode) {
    switch (errorCode) {
      case "ERROR_EMAIL_ALREADY_IN_USE":
      case "account-exists-with-different-credential":
      case "email-already-in-use":
        return "Email already used. Go to login page.";
        break;
      case "ERROR_WRONG_PASSWORD":
      case "wrong-password":
        return "Wrong email/password combination.";
        break;
      case "ERROR_USER_NOT_FOUND":
      case "user-not-found":
        return "No user found with this email.";
        break;
      case "ERROR_USER_DISABLED":
      case "user-disabled":
        return "User disabled.";
        break;
      case "ERROR_TOO_MANY_REQUESTS":
      case "operation-not-allowed":
        return "Too many requests to log into this account.";
        break;
      case "ERROR_OPERATION_NOT_ALLOWED":
      case "operation-not-allowed":
        return "Server error, please try again later.";
        break;
      case "ERROR_INVALID_EMAIL":
      case "invalid-email":
        return "Email address is invalid.";
        break;
      case "operation-not-allowed":
        return "This method is not permitted.";
      case "admin-restricted-operation":
        return "Fail.This method may have been disabled(Anonim Sign In). ";
      default:
        return "Login failed. Please try again.";
        break;
    }
  }

  /// this method returns waiting response. if you call this, you need to call veriftPhoneSignForWeb after.
  Future<AuthResponse> phoneSignInOnWeb(String number) async {
    FirebaseAuthException errorEx;

    if (number == null || number == "")
      return AuthResponse(Status.Failed, "empty field", "-1");

    ConfirmationResult confirmationResult =
        await auth.signInWithPhoneNumber(number).catchError((error) {
      errorEx = error;
      print(error);
    });
    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    phoneCodeListen = true;

    _confirmationResult = confirmationResult;

    return AuthResponse(Status.Waiting, "Please Verify Code.");
  }

  /// complete verification for sign in. call this with sms code
  Future<AuthResponse> verifyPhoneSignForWeb(String code) async {
    FirebaseAuthException errorEx;

    if (_confirmationResult == null || code == null || code == "") {
      return AuthResponse(Status.Failed, "Please Sign in before verification.");
    }

    UserCredential userCredential =
        await _confirmationResult.confirm(code).catchError((error) {
      errorEx = error;
      print(error);
    });
    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    user = userCredential.user;
    _credential = userCredential.credential;
    phoneCodeListen = false;
    return AuthResponse(Status.Successed, "successful.");
  }

  /// this method returns waiting response. if you call this, you need to call veriftPhoneSign after.
  Future<AuthResponse> phoneSignInOnMobile(
      String number, BuildContext context) async {
    FirebaseAuthException errorEx;

    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential phoneAuthCredential) async {
      UserCredential temp = await this
          .auth
          .signInWithCredential(phoneAuthCredential)
          .catchError((error) {
        errorEx = error;
        print(getMessageFromErrorCode(errorEx.code) +
            ":" +
            error.toString() +
            ":" +
            error.code);
      });
      user = temp.user;
      notifyListeners();
    };

    PhoneVerificationFailed verificationFailed = (FirebaseAuthException e) {
      errorEx = e;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed:" + e.message),
      ));
      if (e.code == 'invalid-phone-number') {
        print('The provided phone number is not valid.');
      }
    };
    PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please check your phone for the verification code.'),
      ));
      _verificationId = verificationId;
    };

    /*   PhoneCodeSent codeSent =
      (String verificationId, [int forceResendingToken]){
      removeIndicator(context);
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text("Please type your SMS verification code."),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: controller,
                  ),
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text("Confirm"),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () async{
                    bool er=false;
                    final code = controller.text.trim();
                    AuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);

                    UserCredential result = await this.auth.signInWithCredential(credential).catchError((error){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Invalid Value:"+error.toString()),
                      ));
                      Navigator.pop(context);
                      er=true;
                    });
                    if(!er){
                      user = result.user;
                      removeIndicator(context);
                      Navigator.pop(context);
                    }


                  },
                ),
                FlatButton(
                  child: Text("Back"),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () async{
                    Navigator.pop(context);

                  },
                )
              ],
            );
          }
      );
    };*/

    await auth
        .verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      timeout: const Duration(seconds: 60),
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-resolution timed out...
      },
    )
        .catchError((error) {
      errorEx = error;
      print(getMessageFromErrorCode(errorEx.code) +
          ":" +
          error.toString() +
          ":" +
          error.code);
    });

    if (errorEx != null || verifyErrorMobile) {
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    }

    return AuthResponse(Status.Successed, "Successed.");
  }

  /// complete verification for sign in. call this with sms code
  Future<AuthResponse> verifyPhoneSign(
      BuildContext context, String code) async {
    FirebaseAuthException errorEx;

    if (code == null ||
        code == "" ||
        _verificationId == null ||
        _verificationId == "")
      return AuthResponse(Status.Failed, "Please Sign in before verification.");

    AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: code);

    UserCredential result =
        await this.auth.signInWithCredential(credential).catchError((error) {
      errorEx = error;
      verifyErrorMobile = true;
    });

    if (errorEx != null || verifyErrorMobile) {
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);
    }
    _credential = credential;
    return AuthResponse(Status.Successed, "Successed.");
  }

  Future<AuthResponse> linkCredentialWithEmailPass(
      String mail, String pass) async {
    var errorEx;

    if (auth == null || user == null) {
      return AuthResponse(Status.Failed, "There is no user. Please Login.");
    }

    UserCredential credential = await user
        .linkWithCredential(
            EmailAuthProvider.credential(email: mail, password: pass))
        .catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    user = credential.user;
    notifyListeners();
    return AuthResponse(Status.Successed, "Successed.");
  }

  /// if you call this, you need to call verifyLinkCredentialWithPhone after.
  Future<AuthResponse> linkCredentialWithPhone(
      String number, BuildContext context) async {
    if (auth == null || user == null) {
      return AuthResponse(Status.Failed, "There is no user. Please Login.");
    }

    AuthResponse response = await signInWithPhone(number, context);

    return response;
  }

  /// verify with sms to link account.
  Future<AuthResponse> verifyLinkCredentialWithPhone(String smsCode) async {
    var errorEx;

    UserCredential credential = await user
        .linkWithCredential(PhoneAuthProvider.credential(
            verificationId: _confirmationResult.verificationId,
            smsCode: smsCode))
        .catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    user = credential.user;
    notifyListeners();

    return AuthResponse(Status.Successed, "Successed.");
  }

  Future<AuthResponse> linkCredentialWithGoogle() async {
    AuthCredential credentialG;
    var errorEx;

    if (auth == null || user == null) {
      return AuthResponse(Status.Failed, "There is no user. Please Login.");
    }
/*
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider
          .addScope('https://www.googleapis.com/auth/contacts.readonly');
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});


      credentialG =
          (await FirebaseAuth.instance.signInWithPopup(googleProvider))
              .credential;
    } else {*/

    final GoogleSignInAccount googleUser =
        await GoogleSignIn().signIn().catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    credentialG = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    //}

    UserCredential credential =
        await user.linkWithCredential(credentialG).catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    user = credential.user;
    notifyListeners();

    return AuthResponse(Status.Successed, "Successed.");
  }

  Future<AuthResponse> linkCredentialWithTwitter() async {
    var errorEx;
    var errorEx2;
    AuthCredential twitterAuthCredential;

    if (auth == null || user == null) {
      return AuthResponse(Status.Failed, "There is no user. Please Login.");
    }

    final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: consumerKey,
      consumerSecret: consumerSecretKey,
    );

    if (kIsWeb) {
      User tempUser = await FirebaseAuthOAuth().linkExistingUserWithCredentials(
          "twitter.com", ["email"], {"locale": localeInfo}).catchError((error) {
        errorEx = error;
        print(error);
      });

      if (errorEx != null) {
        return AuthResponse(Status.Failed, errorEx.message);
      }

      user = tempUser;
      notifyListeners();

      return AuthResponse(Status.Successed, "Successed.");
    } else {
      try {
        final TwitterLoginResult loginResult = await twitterLogin.authorize();

        final TwitterSession twitterSession = loginResult.session;

        twitterAuthCredential = TwitterAuthProvider.credential(
            accessToken: twitterSession.token, secret: twitterSession.secret);
      } catch (e) {
        errorEx2 = e;
        print(":::" + e.toString());
      }
    }

    UserCredential credential = await user
        .linkWithCredential(twitterAuthCredential)
        .catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null) return AuthResponse(Status.Failed, errorEx.message);

    user = credential.user;

    return AuthResponse(Status.Successed, "Successed.");
  }

  Future<AuthResponse> deleteUser() async {
    var errorEx;
    await reloadUser();

    if (user == null) return AuthResponse(Status.Failed, "There is no User.");

    await user.delete().catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    return AuthResponse(Status.Successed, "Successed.");
  }

  ///  use "user.emailVerified" for only verified user  situation.
  Future<AuthResponse> sendEmailVerification() async {
    var errorEx;

    if (user == null) return AuthResponse(Status.Failed, "There is no User.");
    if (user.emailVerified)
      return AuthResponse(Status.Failed, "Already Verified.");
    if (user.isAnonymous)
      return AuthResponse(Status.Failed, "You Don't Have Email.");

    await user.sendEmailVerification().catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    await reloadUser();

    reSignWithCredential();

    notifyListeners();
    return AuthResponse(Status.Successed, "Successed.");
  }

  /// firebase auth do not listen for any changes. if you remove or block an account, it won't block instantly, call this when you
  /// need to be sure this user is fresh.
  Future<AuthResponse> reloadUser() async {
    var errorEx;

    if (user == null) return AuthResponse(Status.Failed, "There is no User.");

    await user.reload().catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    notifyListeners();
    return AuthResponse(Status.Successed, "Successed.");
  }

  /// sign in with same credential. I do not recommend to use this function.
  Future<AuthResponse> reSignWithCredential() async {
    var errorEx;

    if (user == null || _credential == null)
      return AuthResponse(Status.Failed, "There is no User.");

    UserCredential temp = await user
        .reauthenticateWithCredential(_credential)
        .catchError((error) {
      errorEx = error;
      print(error);
    });

    if (errorEx != null)
      return AuthResponse(Status.Failed, errorEx.message, errorEx.code);

    user = temp.user;
    notifyListeners();
    return AuthResponse(Status.Successed, "Successed.");
  }

  void removeIndicator(BuildContext context) {
    if (indicatorOn) {
      Navigator.pop(context);
      indicatorOn = false;
    }
  }

  void _onLoading(BuildContext context) {
    indicatorOn = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new CircularProgressIndicator(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new Text("Sending Message..."),
              ),
            ],
          ),
        );
      },
    );

    new Future.delayed(new Duration(seconds: 60), () {
      removeIndicator(context);
    });
  }
}

/// Status enum for operation result.
enum Status {
  Failed,
  Successed,
  Waiting,
}

/// UserTypes enum for sign up types.
enum UserTypes {
  Mail,
  Google,
  Twitter,
  Anonymous,
  Phone,
}

///Response class for auth operations.
///status variable is required.
class AuthResponse {
  Status status;
  String message = "";
  String code = "";

  AuthResponse(this.status, this.message, [this.code]);
}
