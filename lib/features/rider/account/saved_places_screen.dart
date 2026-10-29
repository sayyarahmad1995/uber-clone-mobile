import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'rider_saved_places_store.dart';

const _savedPlacesBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFF2EDFF), Colors.white, Color(0xFFEDF4FF)],
    stops: [0, 0.52, 1],
  ),
);

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  void _openEditor(
    BuildContext context, {
    RiderSavedPlace? place,
    SavedPlaceType? initialType,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SavePlaceScreen(existing: place, initialType: initialType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: riderSavedPlacesStore,
      builder: (context, _) {
        final home = riderSavedPlacesStore.placeForType(SavedPlaceType.home);
        final work = riderSavedPlacesStore.placeForType(SavedPlaceType.work);
        final customs = riderSavedPlacesStore.places
            .where((p) => p.type == SavedPlaceType.custom)
            .toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF2EDFF),
            title: const Text(
              'Saved Places',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),
          ),
          body: Container(
            decoration: _savedPlacesBackground,
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  const Text(
                    'Save places for faster booking.',
                    style: TextStyle(
                      fontSize: 13,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _SavedPlaceTile(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    address: home?.address ?? 'Set your home address',
                    onTap: () => _openEditor(
                      context,
                      place: home,
                      initialType: SavedPlaceType.home,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _SavedPlaceTile(
                    icon: Icons.work_outline,
                    label: 'Work',
                    address: work?.address ?? 'Set your work address',
                    onTap: () => _openEditor(
                      context,
                      place: work,
                      initialType: SavedPlaceType.work,
                    ),
                  ),

                  const SizedBox(height: 23),

                  const Text(
                    'Other saved places',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HiGoTheme.navy,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (customs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HiGoTheme.border),
                      ),
                      child: const Text(
                        'No custom places saved yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                    ),

                  for (final place in customs) ...[
                    _SavedPlaceTile(
                      icon: Icons.bookmark_outline,
                      label: place.label,
                      address: place.address,
                      onTap: () => _openEditor(context, place: place),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 24),

                  _SavedPlacesButton(
                    label: 'Add New Place',
                    icon: Icons.add,
                    onPressed: () => _openEditor(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedPlaceTile extends StatelessWidget {
  const _SavedPlaceTile({
    required this.icon,
    required this.label,
    required this.address,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HiGoTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: HiGoTheme.primary, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: HiGoTheme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedPlacesButton extends StatelessWidget {
  const _SavedPlacesButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7964F6), Color(0xFF458FF1)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavePlaceScreen extends StatefulWidget {
  const SavePlaceScreen({super.key, this.existing, this.initialType});

  final RiderSavedPlace? existing;
  final SavedPlaceType? initialType;

  @override
  State<SavePlaceScreen> createState() => _SavePlaceScreenState();
}

class _SavePlaceScreenState extends State<SavePlaceScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _labelController;

  late SavedPlaceType _type;
  MockPlaceCandidate? _selectedLocation;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
    _labelController = TextEditingController();

    _type =
        widget.existing?.type ?? widget.initialType ?? SavedPlaceType.custom;

    if (widget.existing != null) {
      _selectedLocation = widget.existing!.location;

      if (_type == SavedPlaceType.custom) {
        _labelController.text = widget.existing!.label;
      }
    }

    _searchController.addListener(_refreshSearch);
  }

  void _refreshSearch() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshSearch);
    _searchController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _selectLocation(MockPlaceCandidate location) {
    setState(() {
      _selectedLocation = location;
    });

    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void _savePlace() {
    if (_selectedLocation == null) {
      _showMessage('Select an address first.');
      return;
    }

    if (_type == SavedPlaceType.custom &&
        _labelController.text.trim().isEmpty) {
      _showMessage('Enter a place label.');
      return;
    }

    try {
      riderSavedPlacesStore.save(
        id: widget.existing?.id,
        type: _type,
        label: _labelController.text,
        location: _selectedLocation!,
      );

      Navigator.of(context).pop();
    } on ArgumentError catch (error) {
      _showMessage(error.message.toString());
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deletePlace() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete saved place?'),
        content: Text('Delete "${existing.label}" from saved places?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    riderSavedPlacesStore.delete(existing.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final results = riderSavedPlacesStore.search(_searchController.text);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EDFF),
        title: Text(
          widget.existing == null ? 'Add Saved Place' : 'Edit Saved Place',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: Container(
        decoration: _savedPlacesBackground,
        child: SafeArea(
          top: false,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search address or place',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: HiGoTheme.primary,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _searchController.text.trim().isEmpty
                    ? 'Suggested locations'
                    : 'Search results',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HiGoTheme.navy,
                ),
              ),

              const SizedBox(height: 8),

              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No matching mock locations.',
                    style: TextStyle(color: HiGoTheme.secondaryText),
                  ),
                ),

              for (final location in results)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: HiGoTheme.primary,
                  ),
                  title: Text(
                    location.name,
                    style: const TextStyle(fontSize: 14, color: HiGoTheme.navy),
                  ),
                  subtitle: Text(
                    location.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),
                  trailing: _selectedLocation?.id == location.id
                      ? const Icon(Icons.check_circle, color: HiGoTheme.primary)
                      : const Icon(Icons.chevron_right, size: 19),
                  onTap: () => _selectLocation(location),
                ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F1FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCD6FF)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 34,
                      color: HiGoTheme.primary,
                    ),

                    const SizedBox(height: 9),

                    Text(
                      _selectedLocation?.address ??
                          'Select a location to preview '
                              'its address.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HiGoTheme.navy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Mock location preview — '
                      'not a live map',
                      style: TextStyle(
                        fontSize: 11,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Save as',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HiGoTheme.navy,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in SavedPlaceType.values)
                    ChoiceChip(
                      label: Text(switch (type) {
                        SavedPlaceType.home => 'Home',
                        SavedPlaceType.work => 'Work',
                        SavedPlaceType.custom => 'Custom',
                      }),
                      selected: _type == type,
                      onSelected: (_) {
                        setState(() {
                          _type = type;
                        });
                      },
                    ),
                ],
              ),

              if (_type == SavedPlaceType.custom) ...[
                const SizedBox(height: 16),

                TextField(
                  controller: _labelController,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Place label',
                    hintText: 'e.g. Gym',
                    prefixIcon: Icon(Icons.edit_location_alt_outlined),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              _SavedPlacesButton(
                label: 'Save Place',
                icon: Icons.bookmark_add_outlined,
                onPressed: _savePlace,
              ),

              if (widget.existing != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deletePlace,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Place'),
                ),
              ],

              const SizedBox(height: 12),

              const Text(
                'Saved places will become quick '
                'destinations after booking integration.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: HiGoTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
