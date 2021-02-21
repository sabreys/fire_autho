
# Fire_Autho
### Firebase Authentication Manager


[![Generic badge](https://img.shields.io/badge/Status-Building-<COLOR>.svg)](https://shields.io/)
[![Generic badge](https://img.shields.io/badge/Version-0.0.1-red.svg)](https://shields.io/)

 Notice: This project is under development. It's  unofficial. You can send pull request to contribute.

## Features
All features is avaible on Mobile and Web but  I can't test on IOS.
- Sign and login with email.
- Sign in anonymously (can link with other credential).
- Sign in with Google, Twitter and phone number.
- Link multiple accounts.
- Delete  account.
- Verify account.
- Listen auth state with provider.

# Instalization
- Initialize Firebase setup. [Tutorial](https://firebase.flutter.dev/docs/auth/overview)
###  index.html :

```
     <script src="https://www.gstatic.com/firebasejs/8.2.6/firebase-app.js"></script>
     <script src="https://www.gstatic.com/firebasejs/8.2.6/firebase-analytics.js"></script>
     <script src="https://www.gstatic.com/firebasejs/8.1.1/firebase-auth.js"></script>

  <script>
      var firebaseConfig = {
      apiKey: "********",
      authDomain: "******.firebaseapp.com",
      projectId: "****",
      storageBucket: "****.appspot.com",
      messagingSenderId: "******",
      appId: "********",
      measurementId: "****"
     };

  firebase.initializeApp(firebaseConfig);
  firebase.analytics();
   </script>

```
 You need to use ChangeNotifierProvider  on top of the widget tree.

 main.dart:

       void main() {
         WidgetsFlutterBinding.ensureInitialized();
         runApp(ChangeNotifierProvider(create: (context) => AuthManager(), child: MyApp()));
         }

    class MyHomePage extends StatefulWidget {
       AuthManager manager = AuthManager(); // Singleton class.

       MyHomePage(){
         manager.setTwitterConsumerKeys("consumer_key","consumer_secret_key");
           // if you  will use twitter sign in. you must call this function.
       }
    }



## Setup for Google Sign In On Web

[Configure you project and google cloud api  like in this video. Be sure you added local host on cloud.](https://www.youtube.com/watch?v=0HLt1TYA600&list=WL&index=4)

      <script src="https://apis.google.com/js/platform.js" async defer></script>
      <meta name="google-signin-client_id" content="xxxxxxxxxx.apps.googleusercontent.com">

##  Example Usage

   All methods usages showed on example project.

    onPressed: () async {
       AuthResponse response = await manager.signInWithMailPass(
           mailFieldController.text, passFieldController.text);  // give mail and password.
     // you can get manager with Provider.of<AuthManager>(context) too.
     if (response.status == Status.Failed) {
         showSnack(response);  // show fail message or do something to handle.
       }
    },


--

    AuthResponse response = await Provider.of<AuthManager>(context).signInWithGoogle();
    print(response.message + response.code); // response.status  can be Failed, Successed, Waiting

Phone Sign in :

    AuthResponse response = await Provider.of<AuthManager>(context, listen:false).signInWithPhone(phoneNumberString, context);
    // this will send a sms. if this succesed, you get response.type == Status.Waiting  not Status.Successed. Operation will finish when you confirm verification sms.


    AuthResponse response = await Provider.of<AuthManager>(context, listen:false).verifyPhoneSignForWeb( _smsController.text);
    // call this when you get the sms code. I use in  button onclick.


