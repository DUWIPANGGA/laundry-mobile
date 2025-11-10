import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfilePage({super.key, required this.profileData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(
      text: widget.profileData['username'],
    );
    emailController = TextEditingController(text: widget.profileData['email']);
    addressController = TextEditingController(
      text: widget.profileData['address'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: tambahkan logika update profil
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}
