import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
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
    if (!signedIn) {
      if (mounted) setState(() => _user = null);
      return;
    }
    try {
      final user = await ApiClient.instance.getMe();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // Ikiwa imeshindwa kupakia (mfano token imeisha), UI inabaki
      // katika hali ya "Mgeni" bila kuvunjika.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 28, 20, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 58,
            backgroundColor: AppTheme.primary,
            backgroundImage: _user?.profilePichaUrl != null ? NetworkImage(_user!.profilePichaUrl!) : null,
            child: _user?.profilePichaUrl == null
                ? Text(
                    _signedIn && _user != null && _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'MK',
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            _signedIn ? (_user?.fullName ?? 'Mwanachama wa Nyumba Mkononi') : 'Mgeni',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _signedIn ? 'Akaunti yako iko tayari' : 'Ingia ili kuhifadhi nyumba na kuwasiliana',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppTheme.darkSuccess : AppTheme.success),
          ),
        ),
        const SizedBox(height: 32),
        const _SectionLabel('MUONEKANO'),
        const _ThemeSelector(),
        const SizedBox(height: 24),
        const _SectionLabel('RANGI KUU'),
        const _AccentSelector(),
        const SizedBox(height: 24),
        const _SectionLabel('AKAUNTI'),
        _ProfileTile(icon: Icons.person_outline_rounded, title: 'Taarifa binafsi', onTap: _openPersonalInfo),
        _ProfileTile(icon: Icons.notifications_none_rounded, title: 'Arifa', onTap: _openNotifications),
        _ProfileTile(icon: Icons.language_rounded, title: 'Lugha', onTap: () => _showMessage('Kiswahili')),
        const SizedBox(height: 24),
        const _SectionLabel('MSAADA'),
        _ProfileTile(icon: Icons.help_outline_rounded, title: 'Kituo cha msaada', onTap: () => _showMessage('Timu yetu itakusaidia hivi karibuni.')),
        _ProfileTile(icon: Icons.logout_rounded, title: _signedIn ? 'Toka' : 'Ingia', danger: _signedIn, onTap: _signedIn ? _signOut : _openAuth),
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
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.primary,
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Nyeupe'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Giza'),
              ),
            ],
            selected: {controller.mode},
            onSelectionChanged: (selection) => controller.setMode(selection.first),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerColor = isDark ? Colors.red.shade300 : Colors.red;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: danger ? dangerColor.withAlpha(30) : scheme.surfaceContainerLow,
        foregroundColor: danger ? dangerColor : scheme.onSurface,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _AccentSelector extends StatelessWidget {
  const _AccentSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (final option in ThemeController.accents)
              _AccentDot(
                option: option,
                selected: option.id == controller.accent.id,
                onTap: () => controller.setAccent(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.option, required this.selected, required this.onTap});
  final AccentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: option.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 70,
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: option.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? onSurface : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
              ),
              const SizedBox(height: 6),
              Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
