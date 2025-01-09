//network address
import 'package:flutter/material.dart';
import 'package:memoir_lane/main.dart';

// ipAdress() {
//   return 'http://192.168.254.187:5000';
// }

////// COMMENT THIS IF IP STATIC ///////////////////////////////////////////////////////////////////
String? networkURL;

class NetworkglobalUrl {
  NetworkglobalUrl._privateConstructor();

  static final NetworkglobalUrl _instance = NetworkglobalUrl._privateConstructor();

  String? _baseUrl;

  factory NetworkglobalUrl() {
    return _instance;
  }

  void setBaseUrl(String ipAddress) {
    _baseUrl = 'http://$ipAddress:5000';
    networkURL = _baseUrl!;
  }

  String? getBaseUrl() {
    return _baseUrl ?? networkURL;
  }
}

//dynamic url
ipAdress() {
  return networkURL;
}

//for storing network on open
class DynamicNetwork extends StatefulWidget {
  @override
  _DynamicNetworkState createState() => _DynamicNetworkState();
}

class _DynamicNetworkState extends State<DynamicNetwork> {
  TextEditingController _networkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNetworkExist();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _networkController.dispose();
  }

  Future<void> _checkNetworkExist() async {
    String? BaseUrl = NetworkglobalUrl().getBaseUrl();

    if (BaseUrl != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => IntroPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 100),
            Center(
              child: Image.asset('assets/diary check.png', scale: 2),
            ),
            SizedBox(height: 20),
            Text(
              'Type the IP ADDRESS of PC SERVER NETWORK',
              style: TextStyle(fontSize: 15),
            ),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  TextField(
                    style: TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(contentPadding: EdgeInsets.all(10)),
                    controller: _networkController,
                  ),
                ],
              ),
            ),
            InkWell(
                onTap: () {
                  if (_networkController.text.isNotEmpty) {
                    print(_networkController.text);
                    // Set the IP address in the singleton
                    NetworkglobalUrl().setBaseUrl(_networkController.text);
                    // String? baseUrl = NetworkglobalUrl().getBaseUrl();
                    // showErrorSnackBar(context, baseUrl!);
                    // Navigate to the next screen
                    Navigator.push(context, MaterialPageRoute(builder: (context) => IntroPage()));
                  }
                },
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.deepPurple,
                    ),
                    child: Text('Set Network', style: TextStyle(fontSize: 20, color: Colors.white)))),
          ],
        ), // Show a loading screen while checking the token
      ),
    );
  }
}
