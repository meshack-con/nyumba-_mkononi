import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signedIn = false;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await ApiClient.instance.getToken();
    final signedIn = token?.isNotEmpty == true;
    if (mounted) setState(() => _signedIn = signedIn);
    if (!signedIn) return;
    try {
      final user = await ApiClient.instance.getMyProfile();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // Token inaweza kuwa imeisha muda - _openAuth itashughulikia hilo.
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.fullName ?? (_signedIn ? 'Mwanachama wa Nyumba Mkononi' : 'Mgeni');
    final photoUrl = _user?.profilePhotoUrl;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 28, 20, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 58,
            backgroundColor: AppTheme.primary,
            backgroundImage: photoUrl != null ? NetworkImage(ApiClient.instance.assetUrl(photoUrl)) : null,
            child: photoUrl == null
                ? Text(
                    _signedIn && displayName.isNotEmpty ? displayName[0].toUpperCase() : 'MK',
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        Center(child: Text(displayName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
        Center(child: Text(_signedIn ? 'Akaunti yako iko tayari' : 'Ingia ili kuhifadhi nyumba na kuwasiliana', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.success))),
        const SizedBox(height: 32),
        const _SectionLabel('AKAUNTI'),
        _ProfileTile(icon: Icons.person_outline_rounded, title: 'Taarifa binafsi', onTap: _openPersonalInfo),
        _ProfileTile(icon: Icons.notifications_none_rounded, title: 'Arifa', onTap: _openNotifications),
        _ProfileTile(icon: Icons.account_balance_wallet_outlined, title: 'Toa pesa', onTap: () => _showMessage('Malipo yataonekana hapa.')),
        _ProfileTile(icon: Icons.language_rounded, title: 'Lugha', onTap: () => _showMessage('Kiswahili')),
        const SizedBox(height: 24),
        const _SectionLabel('MSAADA'),
        _ProfileTile(icon: Icons.help_outline_rounded, title: 'Kituo cha msaada', onTap: () => _showMessage('Timu yetu itakusaidia hivi karibuni.')),
        _ProfileTile(icon: Icons.logout_rounded, title: _signedIn ? 'Toka' : 'Ingia', danger: _signedIn, onTap: _signedIn ? _signOut : _openAuth),
        if (_signedIn) _ProfileTile(icon: Icons.delete_outline_rounded, title: 'Futa akaunti', danger: true, onTap: () => _showMessage('Tafadhali wasiliana na msaada.')),
      ],
    );
  }

  Future<void> _openPersonalInfo() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
    _loadSession();
  }

  Future<void> _openNotifications() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  Future<void> _openAuth() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    await _loadSession();
  }

  Future<void> _signOut() async {
    await ApiClient.instance.clearSession();
    if (mounted) setState(() {
      _signedIn = false;
      _user = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        child: Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
      );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(backgroundColor: danger ? Colors.red.withAlpha(20) : AppTheme.surfaceLow, foregroundColor: danger ? Colors.red : AppTheme.navy, child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}
