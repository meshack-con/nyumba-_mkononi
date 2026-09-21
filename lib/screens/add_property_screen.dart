import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

/// Fomu ya "weka nyumba" - badala ya fomu moja ndefu, mtumiaji anajaza
/// kitu kimoja kwa wakati mmoja kupitia "card" zinazofuatana. Akimaliza
/// hatua moja anabonyeza "Endelea" ndipo anapelekwa hatua inayofuata.
/// Swali la bei na maswali ya ziada (mfano ukubwa wa kiwanja) yanabadilika
/// kulingana na aina ya tangazo aliyochagua hatua ya kwanza.
class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});
  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  int _stepIndex = 0;
  bool _processing = false;
  String _processingText = 'Inachakata taarifa zako...';
  String? _error;

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _area = TextEditingController();
  final _plotSize = TextEditingController();

  String? _type; // 'nyumba' | 'chumba' | 'kiwanja'
  String _mode = 'rent';
  bool _wifi = false;
  bool _carParking = false;
  bool _indoorToilet = false;
  bool _hasElectricity = false;
  bool _waterInside = false;
  bool _waterNearby = false;
  bool _furnished = false;
  bool _swimmingPool = false;

  final List<Uint8List?> _photos = [null, null, null];
  final List<String?> _photoNames = [null, null, null];
  Uint8List? _document;
  String? _documentName;
  PickedLocation? _location;

  @override
  void dispose() {
    for (final controller in [_name, _price, _description, _area, _plotSize]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _photosComplete => _photos.every((photo) => photo != null);

  List<String> get _steps {
    final steps = <String>['type'];
    if (_type != 'chumba') steps.add('mode');
    steps.addAll(['name', 'price']);
    if (_type == 'kiwanja') steps.add('plotSize');
    steps.addAll(['description', 'amenities', 'location', 'photos', 'document', 'review']);
    return steps;
  }

  String get _backendType => _type == 'chumba' ? 'studio' : (_type ?? 'nyumba');
  String get _effectiveMode => _type == 'chumba' ? 'rent' : _mode;

  String get _priceLabel {
    if (_type == 'kiwanja') return 'Bei ya kiwanja (TZS)';
    if (_type == 'chumba') return 'Bei ya chumba kwa mwezi (TZS)';
    return _mode == 'rent' ? 'Bei ya kukodisha kwa mwezi (TZS)' : 'Bei ya mauzo (TZS)';
  }

  String get _typeLabel {
    switch (_type) {
      case 'chumba':
        return 'Chumba';
      case 'kiwanja':
        return 'Kiwanja';
      default:
        return 'Nyumba';
    }
  }

  Future<void> _pickSinglePhoto(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _photos[index] = result.files.single.bytes;
      _photoNames[index] = result.files.single.name;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos[index] = null;
      _photoNames[index] = null;
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _document = result.files.single.bytes;
      _documentName = result.files.single.name;
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedLocation>(context, MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)));
    if (result != null) setState(() { _location = result; _area.text = result.label; });
  }

  String? _validateStep(String key) {
    switch (key) {
      case 'type':
        return _type == null ? 'Chagua aina ya tangazo kwanza' : null;
      case 'name':
        return _name.text.trim().isEmpty ? 'Andika jina la tangazo' : null;
      case 'price':
        final value = int.tryParse(_price.text.trim());
        return (value == null || value <= 0) ? 'Weka bei sahihi' : null;
      case 'plotSize':
        final value = int.tryParse(_plotSize.text.trim());
        return (value == null || value <= 0) ? 'Weka ukubwa sahihi wa kiwanja (mita za mraba)' : null;
      case 'description':
        return _description.text.trim().isEmpty ? 'Andika maelezo mafupi kuhusu tangazo lako' : null;
      case 'location':
        return _location == null ? 'Chagua eneo kwenye ramani' : null;
      case 'photos':
        return !_photosComplete ? 'Ongeza picha 3 za tangazo lako' : null;
      case 'document':
        return _document == null ? 'Pakia hati ya umiliki' : null;
      default:
        return null;
    }
  }

  void _next() {
    final steps = _steps;
    final key = steps[_stepIndex];
    final error = _validateStep(key);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);
    if (_stepIndex < steps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_stepIndex == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _stepIndex--;
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _processing = true;
      _processingText = 'Inachakata taarifa zako...';
      _error = null;
    });
    final firstTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _processing) setState(() => _processingText = 'Bado kidogo, tunapakia picha na hati...');
    });
    final secondTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _processing) setState(() => _processingText = 'Inakamilisha, tumebaki kidogo...');
    });
    try {
      final photoBytes = _photos.map((photo) => photo!).toList();
      final photoNames = _photoNames.map((name) => name!).toList();
      await ApiClient.instance.createProperty(
        name: _name.text.trim(),
        type: _backendType,
        mode: _effectiveMode,
        price: int.parse(_price.text.trim()),
        locationLabel: _area.text.trim(),
        latitude: _location!.point.latitude,
        longitude: _location!.point.longitude,
        hasWifi: _wifi,
        carParking: _carParking,
        indoorToilet: _indoorToilet,
        hasElectricity: _hasElectricity,
        waterInside: _waterInside,
        waterNearby: _waterNearby,
        furnished: _furnished,
        swimmingPool: _swimmingPool,
        description: _description.text.trim(),
        plotSizeSqm: _type == 'kiwanja' ? int.tryParse(_plotSize.text.trim()) : null,
        photos: photoBytes,
        photoNames: photoNames,
        verificationDoc: _document!,
        verificationDocName: _documentName!,
      );
      firstTimer.cancel();
      secondTimer.cancel();
      if (!mounted) return;
      setState(() => _processingText = 'Imekamilika!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tangazo limetumwa. Litapitiwa ndani ya masaa 24.')));
      Navigator.pop(context);
    } on ApiException catch (error) {
      firstTimer.cancel();
      secondTimer.cancel();
      if (mounted) setState(() { _processing = false; _error = error.message; });
    } catch (_) {
      firstTimer.cancel();
      secondTimer.cancel();
      if (mounted) setState(() { _processing = false; _error = 'Imeshindikana kutuma tangazo. Jaribu tena.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) return _processingView();
    final steps = _steps;
    final key = steps[_stepIndex.clamp(0, steps.length - 1)];
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        backgroundColor: AppTheme.sand,
        elevation: 0,
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Weka nyumba mpya', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: (_stepIndex + 1) / steps.length, minHeight: 7, backgroundColor: Colors.white, color: AppTheme.coral),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Hatua ${_stepIndex + 1} kati ya ${steps.length}', style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(key),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: _stepCard(_buildStep(key)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                children: [
                  if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(key == 'review' ? 'Tuma tangazo — TZS 5,000' : 'Endelea'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingView() => Scaffold(
        backgroundColor: AppTheme.navy,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4)),
                ),
                const SizedBox(height: 30),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _processingText,
                    key: ValueKey(_processingText),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Tafadhali usifunge programu...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              ],
            ),
          ),
        ),
      );

  Widget _stepCard(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: child,
      );

  Widget _buildStep(String key) {
    switch (key) {
      case 'type':
        return _typeStep();
      case 'mode':
        return _modeStep();
      case 'name':
        return _textFieldStep(
          title: 'Jina la tangazo',
          caption: 'Mpe jina fupi linalovutia',
          controller: _name,
          icon: Icons.badge_outlined,
          hint: 'Mfano: Nyumba nzuri Sinza',
        );
      case 'price':
        return _priceStep();
      case 'plotSize':
        return _plotSizeStep();
      case 'description':
        return _descriptionStep();
      case 'amenities':
        return _amenitiesStep();
      case 'location':
        return _locationStep();
      case 'photos':
        return _photosStep();
      case 'document':
        return _documentStep();
      case 'review':
        return _reviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepHeader(IconData icon, String title, String caption) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppTheme.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(caption, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _typeStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.category_outlined, 'Unaweka nini?', 'Chagua aina ya tangazo lako'),
          _optionCard(title: 'Nyumba', caption: 'Nyumba nzima ya kuishi', icon: Icons.home_rounded, selected: _type == 'nyumba', onTap: () => setState(() => _type = 'nyumba')),
          const SizedBox(height: 12),
          _optionCard(title: 'Chumba', caption: 'Chumba kimoja, bei ya mwezi', icon: Icons.meeting_room_rounded, selected: _type == 'chumba', onTap: () => setState(() { _type = 'chumba'; _mode = 'rent'; })),
          const SizedBox(height: 12),
          _optionCard(title: 'Kiwanja', caption: 'Kiwanja/ardhi', icon: Icons.landscape_rounded, selected: _type == 'kiwanja', onTap: () => setState(() => _type = 'kiwanja')),
        ],
      );

  Widget _modeStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.swap_horiz_rounded, 'Ni kukodisha au kuuza?', 'Chagua hali ya $_typeLabel yako'),
          _optionCard(title: 'Kukodisha', caption: 'Mtu atalipa kila mwezi', icon: Icons.calendar_month_rounded, selected: _mode == 'rent', onTap: () => setState(() => _mode = 'rent')),
          const SizedBox(height: 12),
          _optionCard(title: 'Kuuza', caption: 'Mauzo ya moja kwa moja', icon: Icons.sell_rounded, selected: _mode == 'sale', onTap: () => setState(() => _mode = 'sale')),
        ],
      );

  Widget _optionCard({required String title, required String caption, required IconData icon, required bool selected, required VoidCallback onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.coral.withOpacity(0.10) : AppTheme.sand,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppTheme.coral : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: selected ? AppTheme.coral : Colors.white, foregroundColor: selected ? Colors.white : AppTheme.navy, child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(caption, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.coral),
            ],
          ),
        ),
      );

  Widget _textFieldStep({required String title, required String caption, required TextEditingController controller, required IconData icon, String? hint, TextInputType? keyboardType, int minLines = 1, int maxLines = 1}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(icon, title, caption),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppTheme.sand, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
          ),
        ],
      );

  Widget _priceStep() => _textFieldStep(
        title: _priceLabel,
        caption: 'Weka namba pekee, bila alama',
        controller: _price,
        icon: Icons.payments_rounded,
        hint: 'Mfano: 250000',
        keyboardType: TextInputType.number,
      );

  Widget _plotSizeStep() => _textFieldStep(
        title: 'Ukubwa wa kiwanja',
        caption: 'Kwa mita za mraba (square meters)',
        controller: _plotSize,
        icon: Icons.straighten_rounded,
        hint: 'Mfano: 400',
        keyboardType: TextInputType.number,
      );

  Widget _descriptionStep() => _textFieldStep(
        title: 'Maelezo ya $_typeLabel',
        caption: 'Eleza kwa uwazi vitu muhimu',
        controller: _description,
        icon: Icons.notes_rounded,
        hint: 'Mfano: iko karibu na barabara kuu, dakika 5 kutoka stendi...',
        minLines: 4,
        maxLines: 6,
      );

  Widget _amenitiesStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.checklist_rounded, 'Huduma zilizopo', 'Chagua zote zinazopatikana (hiari)'),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.wifi_rounded), title: const Text('Wi-Fi ipo'), value: _wifi, onChanged: (value) => setState(() => _wifi = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.local_parking_rounded), title: const Text('Sehemu ya kuegesha gari'), value: _carParking, onChanged: (value) => setState(() => _carParking = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.wc_rounded), title: const Text('Choo cha ndani'), value: _indoorToilet, onChanged: (value) => setState(() => _indoorToilet = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.bolt_rounded), title: const Text('Umeme upo'), value: _hasElectricity, onChanged: (value) => setState(() => _hasElectricity = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.water_drop_rounded), title: const Text('Maji ndani'), value: _waterInside, onChanged: (value) => setState(() => _waterInside = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.water_drop_outlined), title: const Text('Maji karibu'), value: _waterNearby, onChanged: (value) => setState(() => _waterNearby = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.chair_rounded), title: const Text('Ina samani'), value: _furnished, onChanged: (value) => setState(() => _furnished = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.pool_rounded), title: const Text('Ina swimming pool'), value: _swimmingPool, onChanged: (value) => setState(() => _swimmingPool = value)),
        ],
      );

  Widget _locationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.location_on_rounded, 'Eneo', 'Weka alama sahihi kwenye ramani'),
          InkWell(
            onTap: _pickLocation,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: AppTheme.coral),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_area.text.isEmpty ? 'Gusa kuchagua eneo kwenye ramani' : _area.text, style: TextStyle(fontWeight: FontWeight.w700, color: _area.text.isEmpty ? AppTheme.muted : AppTheme.navy))),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _photosStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.photo_camera_outlined, 'Picha za $_typeLabel', _photosComplete ? 'Picha 3/3 zimechaguliwa' : '${_photos.where((p) => p != null).length}/3 picha zimechaguliwa'),
          Row(
            children: [
              ..._photos.asMap().entries.where((entry) => entry.value != null).map((entry) {
                final index = entry.key;
                final photo = entry.value!;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(photo, fit: BoxFit.cover)),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_photos.any((photo) => photo == null))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final nextEmptyIndex = _photos.indexWhere((photo) => photo == null);
                      if (nextEmptyIndex != -1) _pickSinglePhoto(nextEmptyIndex);
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppTheme.sand, border: Border.all(color: AppTheme.muted.withOpacity(0.3))),
                        child: const Center(child: Icon(Icons.add_photo_alternate_outlined, color: AppTheme.muted, size: 28)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _documentStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.description_outlined, 'Uthibitisho wa umiliki', _documentName ?? 'Hati inahitajika (PDF au picha)'),
          OutlinedButton.icon(onPressed: _pickDocument, icon: const Icon(Icons.upload_file_outlined), label: Text(_documentName ?? 'Pakia hati')),
        ],
      );

  Widget _reviewStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(Icons.fact_check_outlined, 'Kagua kabla ya kutuma', 'Hakikisha kila kitu ni sahihi'),
          _reviewRow('Aina', _typeLabel),
          _reviewRow('Hali', _effectiveMode == 'rent' ? 'Kukodisha' : 'Kuuza'),
          _reviewRow('Jina', _name.text),
          _reviewRow(_priceLabel, _price.text),
          if (_type == 'kiwanja') _reviewRow('Ukubwa', '${_plotSize.text} m²'),
          _reviewRow('Eneo', _area.text),
          _reviewRow('Picha', '${_photos.where((p) => p != null).length}/3'),
          _reviewRow('Hati ya umiliki', _documentName ?? 'Haijapakiwa'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded),
                SizedBox(width: 10),
                Expanded(child: Text('Malipo ya tangazo ni TZS 5,000. Tangazo litapitiwa ndani ya masaa 24 baada ya kutumwa.')),
              ],
            ),
          ),
        ],
      );

  Widget _reviewRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600))),
            Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
}
