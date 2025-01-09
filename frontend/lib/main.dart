import 'package:flutter/material.dart';
import 'package:memoir_lane/login.dart';
import 'package:memoir_lane/network.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: IntroPage(),
      home: DynamicNetwork(),
    );
  }
}

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
                  return;
                }
              },
              child: Container()),
          SizedBox(height: 100),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Image.asset('assets/diary check.png', scale: 2),
                SizedBox(height: 50),
                Text(
                  'Welcome to Memoir Lane!',
                  style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  'Where your journey unfolds,',
                ),
                Text(
                  'one thought, one memory, one moment at a time.',
                ),
                Text(
                  'Let your story begin here.',
                ),
                SizedBox(height: 50),
                Container(
                  width: 200,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(5)),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward, color: Colors.white)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
