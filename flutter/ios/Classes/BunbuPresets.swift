import Foundation

struct BunbuPreset {
    let label: String
    let icon: String
    let code: String
}

let bunbuPresets: [BunbuPreset] = [
    BunbuPreset(
        label: "Todo List",
        icon: "checklist",
        code: """
import 'package:flutter/material.dart';

class Main extends StatefulWidget {
  Main();

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  bool _d0 = false;
  bool _d1 = false;
  bool _d2 = false;
  bool _d3 = false;
  bool _d4 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks'),
        backgroundColor: Color(0xFF6C63FF),
      ),
      body: ListView(
        children: [
          GestureDetector(
            onTap: () { setState(() { _d0 = _d0 == false; }); },
            child: ListTile(
              leading: Icon(_d0 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d0 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Buy groceries', style: TextStyle(color: _d0 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d1 = _d1 == false; }); },
            child: ListTile(
              leading: Icon(_d1 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d1 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Walk the dog', style: TextStyle(color: _d1 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d2 = _d2 == false; }); },
            child: ListTile(
              leading: Icon(_d2 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d2 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Read a book', style: TextStyle(color: _d2 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d3 = _d3 == false; }); },
            child: ListTile(
              leading: Icon(_d3 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d3 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Write Flutter code', style: TextStyle(color: _d3 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d4 = _d4 == false; }); },
            child: ListTile(
              leading: Icon(_d4 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d4 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Go to the gym', style: TextStyle(color: _d4 ? Colors.grey : Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}
"""
    ),
    BunbuPreset(
        label: "Profile",
        icon: "person.circle",
        code: """
import 'package:flutter/material.dart';

class Main extends StatelessWidget {
  Main();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF2196F3),
      ),
      body: ListView(
        children: [
            SizedBox(height: 32),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: Center(
                  child: Text('JD', style: TextStyle(fontSize: 36, color: Colors.white)),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(child: Text('Jane Doe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            SizedBox(height: 4),
            Center(child: Text('Flutter Developer', style: TextStyle(fontSize: 16, color: Colors.grey))),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('142', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Posts', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('1.2k', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Followers', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('89', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Following', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(height: 1, color: Colors.grey),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF2196F3)),
              title: Text('jane.doe@email.com'),
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Color(0xFF2196F3)),
              title: Text('San Francisco, CA'),
            ),
            ListTile(
              leading: Icon(Icons.web, color: Color(0xFF2196F3)),
              title: Text('github.com/janedoe'),
            ),
          ],
        ),
    );
  }
}
"""
    ),
    BunbuPreset(
        label: "Weather",
        icon: "cloud.sun",
        code: """
import 'package:flutter/material.dart';

class Main extends StatelessWidget {
  Main();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather'),
        backgroundColor: Color(0xFF1565C0),
      ),
      body: Container(
        color: Color(0xFF1565C0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Icon(Icons.wb_sunny, size: 80, color: Colors.amber),
            SizedBox(height: 16),
            Text('San Francisco', style: TextStyle(fontSize: 28, color: Colors.white)),
            SizedBox(height: 8),
            Text('72 F', style: TextStyle(fontSize: 64, fontWeight: FontWeight.normal, color: Colors.white)),
            Text('Sunny', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.water_drop, color: Colors.white),
                      SizedBox(height: 4),
                      Text('45%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Humidity', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.air, color: Colors.white),
                      SizedBox(height: 4),
                      Text('12 mph', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Wind', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.visibility, color: Colors.white),
                      SizedBox(height: 4),
                      Text('10 mi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Visibility', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('Mon', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
                      SizedBox(height: 4),
                      Text('74', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Tue', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.cloud, color: Colors.grey, size: 28),
                      SizedBox(height: 4),
                      Text('68', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Wed', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.cloud, color: Colors.grey, size: 28),
                      SizedBox(height: 4),
                      Text('65', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Thu', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
                      SizedBox(height: 4),
                      Text('71', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Fri', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
                      SizedBox(height: 4),
                      Text('75', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"""
    ),
]
