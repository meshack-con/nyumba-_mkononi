import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await ApiClient.instance.getToken();
    if (mounted) setState(() => _signedIn = token?.isNotEmpty == true);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 28, 20, 32),
      children: [
        Center(child: CircleAvatar(radius: 58, backgroundColor: AppTheme.primary, child: Text(_signedIn ? 'NM' : 'MK', style: const TextStyle(color: Colors.white, fontSize: 30)))),
        const SizedBox(height: 18),
        Center(child: Text(_signedIn ? 'Mwanachama wa Nyumba Mkononi' : 'Mgeni', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
        Center(child: Text(_signedIn ? 'Akaunti yako iko tayari' : 'Ingia ili kuhifadhi nyumba na kuwasiliana', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.success))),
        const SizedBox(height: 32),
        const _SectionLabel('AKAUNTI'),
        _ProfileTile(icon: Icons.person_outline_rounded, title: 'Taarifa binafsi', onTap: _openAuth),
        _ProfileTile(icon: Icons.notifications_none_rounded, title: 'Arifa', onTap: () => _showMessage('Arifa zako zitaonekana hapa.')),
        _ProfileTile(icon: Icons.account_balance_wallet_outlined, title: 'Toa pesa', onTap: () => _showMessage('Malipo yataonekana hapa.')),
        _ProfileTile(icon: Icons.verified_user_outlined, title: 'Usajili wangu', onTap: () => _showMessage('Uthibitisho wa akaunti yako.')),
        _ProfileTile(icon: Icons.language_rounded, title: 'Lugha', onTap: () => _showMessage('Kiswahili')),
        const SizedBox(height: 24),
        const _SectionLabel('MSAADA'),
        _ProfileTile(icon: Icons.help_outline_rounded, title: 'Kituo cha msaada', onTap: () => _showMessage('Timu yetu itakusaidia hivi karibuni.')),
        _ProfileTile(icon: Icons.logout_rounded, title: _signedIn ? 'Toka' : 'Ingia', danger: _signedIn, onTap: _signedIn ? _signOut : _openAuth),
        if (_signedIn) _ProfileTile(icon: Icons.delete_outline_rounded, title: 'Futa akaunti', danger: true, onTap: () => _showMessage('Tafadhali wasiliana na msaada.')),
      ],
    );
  }

  Future<void> _openAuth() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    _loadSession();
  }

  Future<void> _signOut() async {
    await ApiClient.instance.clearSession();
    if (mounted) setState(() => _signedIn = false);
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
