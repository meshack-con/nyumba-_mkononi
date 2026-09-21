import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});
  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  AppUser? _user;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await ApiClient.instance.getMyProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _fullName.text = user.fullName;
        _phone.text = user.phone;
        _area.text = user.area ?? '';
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindwa kupakia taarifa zako.')));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = await ApiClient.instance.updateMyProfile(
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        area: _area.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _user = user;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taarifa zako zimehifadhiwa.')));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindwa kuhifadhi, jaribu tena.')));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final user = await ApiClient.instance.uploadProfilePhoto(file!.bytes as Uint8List, file.name);
      if (mounted) setState(() => _user = user);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindwa kupakia picha, jaribu tena.')));
    }
    if (mounted) setState(() => _uploadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taarifa binafsi', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (!_loading && _user != null)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_editing) {
                        _save();
                      } else {
                        setState(() => _editing = true);
                      }
                    },
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_editing ? 'Hifadhi' : 'Hariri', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Imeshindwa kupakia taarifa zako.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppTheme.primary,
                            backgroundImage: _user!.profilePhotoUrl != null ? NetworkImage(ApiClient.instance.assetUrl(_user!.profilePhotoUrl!)) : null,
                            child: _user!.profilePhotoUrl == null
                                ? Text(_user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800))
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(color: AppTheme.coral, shape: BoxShape.circle),
                                child: _uploadingPhoto
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text('Gusa kamera kupakia/kubadili picha yako', style: TextStyle(color: AppTheme.muted, fontSize: 12))),
                    const SizedBox(height: 30),
                    _field('Jina kamili', _fullName, editable: _editing),
                    _field('Namba ya simu', _phone, editable: _editing, keyboardType: TextInputType.phone),
                    _field('Eneo', _area, editable: _editing),
                    const SizedBox(height: 8),
                    _readOnlyRow('Jina la mtumiaji', _user!.username),
                    _readOnlyRow('Barua pepe', _user!.email ?? 'Haijawekwa'),
                    _readOnlyRow('Aina ya akaunti', _user!.role == 'seller' ? 'Muuzaji/Mpangishaji' : 'Mnunuzi/Mpangaji'),
                    if (_editing) ...[
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _editing = false;
                                  _fullName.text = _user!.fullName;
                                  _phone.text = _user!.phone;
                                  _area.text = _user!.area ?? '';
                                }),
                        child: const Text('Ghairi mabadiliko'),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _field(String label, TextEditingController controller, {required bool editable, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: editable,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: editable ? Colors.white : AppTheme.surfaceLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
