import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'add_property_screen.dart';
import 'auth_screen.dart';
import 'seller_messages_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});
  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  List<Property> _properties = [];
  bool _loading = true;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    // Hakikisha mtumiaji ame-authenticate KABLA ya kuona dashibodi ya muuzaji.
    // Ikiwa tayari ana token iliyohifadhiwa (kutoka mara ya awali), hatahitaji
    // ku-login tena - ensureAuthenticated itapita moja kwa moja.
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  Future<void> _guard() async {
    final ok = await ensureAuthenticated(context, asSeller: true);
    if (!mounted) return;
    if (!ok) {
      // Mtumiaji hakukamilisha authentication (mfano amefunga dirisha la login) -
      // hatoingizwa kwenye dashibodi ya muuzaji, tunarudi nyuma.
      Navigator.pop(context);
      return;
    }
    setState(() => _checkingAuth = false);
    _load();
  }

  Future<void> _load() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) { if (mounted) setState(() => _loading = false); return; }
    try { final data = await ApiClient.instance.getMyProperties(); if (mounted) setState(() => _properties = data); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addProperty() async {
    // Kwa hatua hii mtumiaji tayari ame-authenticate (angeshaondolewa hapo awali
    // kama sivyo), lakini tunaacha ukaguzi huu kama ulinzi wa ziada.
    if (!await ensureAuthenticated(context, asSeller: true) || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      // Bado tunakagua kama mtumiaji ame-authenticate - onyesha loading tu,
      // usionyeshe maudhui ya dashibodi kabla ya uthibitisho.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final approved = _properties.where((item) => item.status == 'approved').length;
    final pending = _properties.where((item) => item.status == 'pending').length;
    final totalUnread = _properties.fold<int>(0, (sum, item) => sum + item.unreadMessagesCount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashibodi yako', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Stack(alignment: Alignment.center, children: [
            IconButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerMessagesScreen()));
                _load();
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            if (totalUnread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(color: AppTheme.coral, shape: BoxShape.circle),
                  child: Text('$totalUnread', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addProperty, backgroundColor: AppTheme.coral, foregroundColor: Colors.white, icon: const Icon(Icons.add_rounded), label: const Text('Weka nyumba')),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
        Text('Tangazo lako, mwanzo wa safari ya mtu.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 22),
        Row(children: [_Stat(label: 'Jumla', value: '${_properties.length}', color: AppTheme.primary), const SizedBox(width: 10), _Stat(label: 'Imeidhinishwa', value: '$approved', color: AppTheme.success), const SizedBox(width: 10), _Stat(label: 'Inapitiwa', value: '$pending', color: AppTheme.primaryContainer)]),
        const SizedBox(height: 28),
        Text('Mali zako', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(36), child: CircularProgressIndicator())) else if (_properties.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Column(children: [Icon(Icons.add_business_outlined, size: 48, color: AppTheme.muted), SizedBox(height: 12), Text('Bado hujaweka nyumba.', style: TextStyle(color: AppTheme.muted))])) else ..._properties.map((property) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: 70, height: 70, child: property.photoUrls.isEmpty ? const ColoredBox(color: AppTheme.sand, child: Icon(Icons.home)) : Image.network(ApiClient.instance.assetUrl(property.photoUrls.first), fit: BoxFit.cover))),
          title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${property.locationLabel}\n${property.formattedPrice}'),
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 4, children: [
                _MiniStat(icon: Icons.visibility_outlined, value: '${property.viewCount}'),
                _MiniStat(icon: Icons.favorite_outline_rounded, value: '${property.favoritesCount}'),
                if (property.unreadMessagesCount > 0) _MiniStat(icon: Icons.mark_chat_unread_outlined, value: '${property.unreadMessagesCount}', color: AppTheme.coral),
              ]),
            ]),
          ),
          isThreeLine: true,
          trailing: _StatusBadge(status: property.status),
        )))
      ])),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value; final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))])));
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, this.color});
  final IconData icon;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.muted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 3),
      Text(value, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status}); final String status;
  @override
  Widget build(BuildContext context) { final approved = status == 'approved'; final expired = status == 'expired'; final color = approved ? AppTheme.success : expired ? AppTheme.muted : AppTheme.primary; final label = approved ? 'Imeidhinishwa' : expired ? 'Imeisha' : 'Inapitiwa'; return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: color.withAlpha(31), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))); }
}
