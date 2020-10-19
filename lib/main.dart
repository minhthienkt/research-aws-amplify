import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter_aws/src/models/todo.dart';
import 'package:flutter_aws/src/resources/provider.dart';
import 'amplifyconfiguration.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final confirmationCodeController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool _isAmplifyConfigured = false;
  Amplify amplify = Amplify();
  AmplifyAuthCognito auth;
  String displayState;
  String authState;
  String error;
  List<String> exceptions = [];

  ////s3storage
  String _uploadFileResult = '';
  String _getUrlResult = '';
  String _removeResult = '';

  @override
  void initState() {
    super.initState();
  }

  void _configureAmplify() async {
    AmplifyStorageS3 storage = new AmplifyStorageS3();
    auth = AmplifyAuthCognito();
    amplify.addPlugin(authPlugins: [auth], storagePlugins: [storage]);
    var isSignedIn = false;

    await amplify.configure(amplifyconfig);
    try {
      isSignedIn = await _isSignedIn();
    } on AuthError catch (e) {
      print("User is not signed in.");
    }

    setState(() {
      _isAmplifyConfigured = true;
      displayState = isSignedIn ? "SIGNED_IN" : "SHOW_SIGN_IN";
    });
    auth.events.listenToAuth((hubEvent) {
      switch (hubEvent["eventName"]) {
        case "SIGNED_IN":
          {
            print("USER IS SIGNED IN");
          }
          break;
        case "SIGNED_OUT":
          {
            print("USER IS SIGNED OUT");
          }
          break;
        case "SESSION_EXPIRED":
          {
            print("USER IS SIGNED IN");
          }
          break;
        default:
          {
            print("CONFIGURATION EVENT");
          }
      }
    });
  }

  Future<bool> _isSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }

  void _signUp() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    Map<String, dynamic> userAttributes = {
      "email": emailController.text,
      "phone_number": phoneController.text,
    };
    try {
      SignUpResult res = await Amplify.Auth.signUp(
          username: usernameController.text.trim(),
          password: passwordController.text.trim(),
          options: CognitoSignUpOptions(userAttributes: userAttributes));
      setState(() {
        displayState =
            res.nextStep.signUpStep != "DONE" ? "SHOW_CONFIRM" : "SHOW_SIGN_UP";
        authState = "Signup: " + res.nextStep.signUpStep;
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _confirmSignUp() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      SignUpResult res = await Amplify.Auth.confirmSignUp(
          username: usernameController.text.trim(),
          confirmationCode: confirmationCodeController.text.trim());
      setState(() {
        displayState =
            res.nextStep.signUpStep != "DONE" ? "SHOW_CONFIRM" : "SHOW_SIGN_IN";
        authState = "ConfirmSignUp: " + res.nextStep.signUpStep;
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _signIn() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      SignInResult res = await Amplify.Auth.signIn(
          username: usernameController.text.trim(),
          password: passwordController.text.trim());
      setState(() {
        displayState = res.isSignedIn ? "SIGNED_IN" : "SHOW_CONFIRM_SIGN_IN";
        authState = "Signin: " + res.nextStep.signInStep;
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _confirmSignIn() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      SignInResult res = await Amplify.Auth.confirmSignIn(
          confirmationValue: confirmationCodeController.text.trim());
      setState(() {
        displayState = res.nextStep.signInStep == "DONE"
            ? "SIGNED_IN"
            : "SHOW_CONFIRM_SIGN_IN";
        authState = "SignIn: " + res.nextStep.signInStep;
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _signOut() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      await Amplify.Auth.signOut(
          options: CognitoSignOutOptions(globalSignOut: true));
      setState(() {
        displayState = 'SHOW_SIGN_IN';
        authState = "SIGNED OUT";
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _updatePassword() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      await Amplify.Auth.updatePassword(
          newPassword: newPasswordController.text.trim(),
          oldPassword: oldPasswordController.text.trim());
      setState(() {
        displayState = 'SIGNED_IN';
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _resetPassword() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      ResetPasswordResult res = await Amplify.Auth.resetPassword(
        username: usernameController.text.trim(),
      );
      setState(() {
        displayState = "SHOW_CONFIRM_REST";
        authState = res.nextStep.updateStep;
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _resendSignUpCode() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      ResendSignUpCodeResult res = await Amplify.Auth.resendSignUpCode(
        username: usernameController.text.trim(),
      );
      print(res);
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _confirmReset() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      UpdatePasswordResult res = await Amplify.Auth.confirmPassword(
          username: usernameController.text.trim(),
          newPassword: newPasswordController.text.trim(),
          confirmationCode: confirmationCodeController.text.trim());
      setState(() {
        displayState = "SHOW_SIGN_IN";
      });
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _fetchSession() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      AuthSession res = await Amplify.Auth.fetchAuthSession();
      print(res);
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
      print(e);
    }
  }

  void _getCurrentUser() async {
    setState(() {
      error = "";
      exceptions = [];
    });
    try {
      AuthUser res = await Amplify.Auth.getCurrentUser();
      print(res);
    } on AuthError catch (e) {
      setState(() {
        error = e.cause;
        e.exceptionList.forEach((el) {
          exceptions.add(el.exception);
        });
      });
    }
  }

  void _stopListening() async {
    auth.events.stopListeningToAuth();
  }

  void _createUser() async {
    setState(() {
      //displayState = "SHOW_SIGN_UP";
      displayState = "SHOW_SIGN_UP";
    });
  }

  void _backToSignIn() async {
    setState(() {
      displayState = "SHOW_SIGN_IN";
    });
  }


  void _backToHome() async {
    setState(() {
      displayState = "SIGNED_IN";
    });
  }

  void _showUpdatePassword() async {
    setState(() {
      displayState = "SHOW_UPDATE_PASSWORD";
    });
  }

  void _s3Storage() async {
    setState(() {
      displayState = "s3Storage";
    });
  }

  void list() async {
    try {
      S3ListOptions options =
          S3ListOptions(accessLevel: StorageAccessLevel.guest);
      ListResult result = await Amplify.Storage.list(options: options);
      print('List Result:');
      for (StorageItem item in result.items) {
        print(
            'Item: { key:${item.key}, eTag:${item.eTag}, lastModified:${item.lastModified}, size:${item.size}');
      }
    } catch (e) {
      print('List Err: ' + e.toString());
    }
  }

  void _upload() async {
    try {
      File local = await FilePicker.getFile(type: FileType.image);
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd–HH:mm:ss').format(now);
      final key = 'hinhanh/demo/' + formattedDate;
      S3UploadFileOptions options =
          S3UploadFileOptions(accessLevel: StorageAccessLevel.guest);
      UploadFileResult result = await Amplify.Storage.uploadFile(
          key: key, local: local, options: options);
      setState(() {
        _uploadFileResult = result.key;
      });
    } catch (e) {
      print('UploadFile Err: ' + e.toString());
    }
  }

  void _getUrl() async {
    try {
      String key = _uploadFileResult;
      S3GetUrlOptions options = S3GetUrlOptions(
          accessLevel: StorageAccessLevel.guest, expires: 10000);
      GetUrlResult result =
          await Amplify.Storage.getUrl(key: key, options: options);

      setState(() {
        _getUrlResult = result.url;
      });
    } catch (e) {
      print('GetUrl Err: ' + e.toString());
    }
  }

  Widget showConfirmSignUp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(10.0)),
              TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: 'Your username',
                    labelText: 'Username *',
                  )),
              TextFormField(
                  controller: confirmationCodeController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.confirmation_number),
                    hintText: 'The code we sent you',
                    labelText: 'Confirmation Code *',
                  )),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _confirmSignUp,
                child: const Text('Confirm SignUp'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _backToSignIn,
                child: const Text('Back to Sign In'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _resendSignUpCode,
                child: const Text('ResendCode'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget showConfirmSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(10.0)),
              TextFormField(
                  controller: confirmationCodeController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.question_answer),
                    hintText: 'The secret answer to the auth challange',
                    labelText: 'Challange Response *',
                  )),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _confirmSignIn,
                child: const Text('Confirm SignIn'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _backToSignIn,
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget showSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: 'Your username',
                    labelText: 'Username *',
                  )),
              TextFormField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.lock),
                    hintText: 'Your password',
                    labelText: 'Password *',
                  )),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _signIn,
                child: const Text('Sign In'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _createUser,
                child: const Text('Create User'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _resetPassword,
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget showSignUp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.person),
                  hintText: 'The name you will use to login',
                  labelText: 'Username *',
                ),
              ),
              TextFormField(
                obscureText: true,
                controller: passwordController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.lock),
                  hintText: 'The password you will use to login',
                  labelText: 'Password *',
                ),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.email),
                  hintText: 'Your email address',
                  labelText: 'Email *',
                ),
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.phone),
                  hintText: 'Your phone number',
                  labelText: 'Phone number *',
                ),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _signUp,
                child: const Text('Sign Up'),
              ),
              const Padding(padding: EdgeInsets.all(2.0)),
              Text(
                'SignUpData: $authState',
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _backToSignIn,
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget showUpdatePassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(10.0)),
              TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.question_answer),
                    hintText: 'Your old password',
                    labelText: 'Old Password *',
                  )),
              TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.question_answer),
                    hintText: 'Your new password',
                    labelText: 'New Password *',
                  )),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _updatePassword,
                child: const Text('Update Password'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget showConfirmReset() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(10.0)),
              TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.verified_user),
                    hintText: 'Your old username',
                    labelText: 'Username *',
                  )),
              TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.question_answer),
                    hintText: 'Your new password',
                    labelText: 'New Password *',
                  )),
              TextFormField(
                  controller: confirmationCodeController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.confirmation_number),
                    hintText: 'The confirmation code we sent you',
                    labelText: 'Confirmation Code *',
                  )),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _confirmReset,
                child: const Text('Confirm Password Reset'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _backToSignIn,
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget showApp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(10.0)),
              Text("You are signed in!"),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _showUpdatePassword,
                child: const Text('Change Password'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                onPressed: _s3Storage,
                child: const Text('S3 Storage'),
              ),
              const Padding(padding: EdgeInsets.all(10.0)),
              RaisedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Graphql()));
                  },
                  child: const Text('Graphql')),
            ],
          ),
        ),
      ],
    );
  }

  showAuthState() {
    return Text(
      'Auth Status: $authState',
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget s3StrogeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          // wrap your Column in Expanded
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                onPressed: _upload,
                child: const Text('Upload File'),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              RaisedButton(
                onPressed: _getUrl,
                child: const Text('GetUrl for uploaded File'),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              RaisedButton(
                onPressed: _backToHome,
                child: const Text('Back to Home'),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              Image.network(_getUrlResult),
              const Padding(padding: EdgeInsets.all(10.0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget getTextWidgets(List<String> strings) {
    if (strings != null) {
      return new Row(
          children: strings.map((item) => new Text(item + " ")).toList());
    }
  }

  showErrors() {
    return Text('Error: $error',
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        style: TextStyle(fontWeight: FontWeight.bold));
  }

  showExceptions() {
    return getTextWidgets(exceptions);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('aws amplify'),
        ),
        body: ListView(
          padding: EdgeInsets.all(10.0),
          children: <Widget>[
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(padding: EdgeInsets.all(10.0)),
                  RaisedButton(
                    onPressed: _isAmplifyConfigured ? null : _configureAmplify,
                    child: const Text('configure'),
                  ),
                  RaisedButton(
                    onPressed: _isAmplifyConfigured ? null : _signIn,
                    child: const Text('signin'),
                  ),
                  const Padding(padding: EdgeInsets.all(10.0)),
                  if (this.displayState == "SHOW_SIGN_UP") showSignUp(),
                  if (this.displayState == "SHOW_CONFIRM") showConfirmSignUp(),
                  if (this.displayState == "SHOW_SIGN_IN") showSignIn(),
                  if (this.displayState == "SHOW_CONFIRM_SIGN_IN")
                    showConfirmSignIn(),
                  if (this.displayState == "SHOW_UPDATE_PASSWORD")
                    showUpdatePassword(),
                  if (this.displayState == "SHOW_CONFIRM_REST")
                    showConfirmReset(),
                  if (this.displayState == "SIGNED_IN") showApp(),
                  if (this.displayState == "s3Storage") s3StrogeWidget(),
                  showAuthState(),
                  if (this.error != null) showErrors(),
                  showExceptions()
                ])
          ],
        ),
      ),
    );
  }
}

class Graphql extends StatelessWidget {
  final HttpLink httpLink = HttpLink(
      uri:
      'https://jaxi54mgxvgsndu2b7m3fsgg6u.appsync-api.us-east-1.amazonaws.com/graphql',
      headers: {'x-api-key': 'da2-e4q2vp2ajbbkpfz5b5iegujy3u'}
  );

  @override
  Widget build(BuildContext context) {
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        cache: OptimisticCache(dataIdFromObject: typenameDataIdFromObject),
        link: httpLink,
      ),
    );
    return MaterialApp(
      home: GraphQLProvider(
        child: MyHomePage(),
        client: client,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final HttpLink httpLink = HttpLink(
      uri:
      'https://jaxi54mgxvgsndu2b7m3fsgg6u.appsync-api.us-east-1.amazonaws.com/graphql',
      headers: {'x-api-key': 'da2-e4q2vp2ajbbkpfz5b5iegujy3u'}
  );


  TextEditingController idController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  String query = '''
  query MyQuery {
  listTodos {
    items {
      id
      name
    }
  }
}
''';

  Future<QueryResult> sendData(String _id, String _name) async {
    String addTodo = '''
         mutation addTodo {
          createTodo(input: {id: "$_id", name: "$_name"}) {
            id
            name
          }
        }
    ''';
    GraphQLClient client = GraphQLClient(
      link: httpLink,
    );
    QueryResult queryResult = await client.query(
      QueryOptions(documentNode: gql(addTodo)),
    );
    return queryResult;
  }

  void clearInput() {
    idController.clear();
    nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Load data using GraphQL',
          ),
        ),
        body: Query(
          options: QueryOptions(
            documentNode: gql(query),
          ),
          builder: (
            QueryResult result, {
            Refetch refetch,
            FetchMore fetchMore,
          }) {
            if (result.exception != null) {
              print(result.exception.toString());
            }
            if (result.data == null) {
              return Center(
                  child: Text(
                "Loading...",
                style: TextStyle(fontSize: 20.0),
              ));
            } else {
              return ListView.builder(
                itemCount: result.data["listTodos"]["items"].length,
                itemBuilder: (BuildContext context, index) {
                  return ListTile(
                    title: Text(result.data["listTodos"]["items"][index]["id"]),
                    trailing:
                        Text(result.data["listTodos"]["items"][index]['name']),
                  );
                },
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Stack(
                      overflow: Overflow.visible,
                      children: <Widget>[
                        Positioned(
                          right: -40.0,
                          top: -40.0,
                          child: InkResponse(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: CircleAvatar(
                              child: Icon(Icons.close),
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: idController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: "Enter Id",
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      )),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Enter id';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                      labelText: "Enter name",
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      )),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Enter name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RaisedButton(
                                  child: Text("Save"),
                                  onPressed: () {
                                    if (_formKey.currentState.validate()) {
                                      _formKey.currentState.save();
                                      sendData(idController.text,
                                          nameController.text);
                                      clearInput();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.green,
        ),

      ),
    );
  }
}
