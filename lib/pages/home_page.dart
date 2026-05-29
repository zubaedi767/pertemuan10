import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Map<String, dynamic>> foods = const [
    {
      "name": "Nasi Goreng",
      "price": "15000",
      "image":
      "https://cdn-icons-png.flaticon.com/512/5787/5787016.png"
    },
    {
      "name": "Burger",
      "price": "25000",
      "image":
      "https://cdn-icons-png.flaticon.com/512/3075/3075977.png"
    },
    {
      "name": "Pizza",
      "price": "50000",
      "image":
      "https://cdn-icons-png.flaticon.com/512/3132/3132693.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,

        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),

      body: ListView.builder(
        itemCount: foods.length,

        itemBuilder: (context, index) {

          final food = foods[index];

          return Card(
            margin: const EdgeInsets.all(10),

            child: ListTile(
              leading: Image.network(
                food['image'],
                width: 50,
              ),

              title: Text(food['name']),

              subtitle: Text(
                "Rp ${food['price']}",
              ),

              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text("Pesan"),
              ),
            ),
          );
        },
      ),
    );
  }
}