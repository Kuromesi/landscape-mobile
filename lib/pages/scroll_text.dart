import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/constants/constants.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:landscape/utils/utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:landscape/constants/text.dart';
import 'package:landscape/apis/apis.dart';
import 'package:landscape/players/players.dart';
import 'package:provider/provider.dart';

class ScrollTextPage extends StatefulWidget {
  const ScrollTextPage({super.key});

  @override
  _ScrollTextPageState createState() => _ScrollTextPageState();
}

class _ScrollTextPageState extends State<ScrollTextPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Holds the master configuration including the active index and all templates.
  late ScrollTextConfiguration _conf;

  /// Tracks which template is currently being edited in the sub-menu.
  /// Null indicates the user is in the "Template List" view.
  int? _editingIndex;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _conf = ScrollTextConfiguration();
    _loadPreferences();

    // Register state exporter for remote control features.
    configDump[configScrollText] = exportState;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = Provider.of<ScrollTextNotifier>(context, listen: false);
      notifier.addListener(_onNotifierUpdate);
      notifier.updateScrollTextConfig(_conf);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _savePreferences();
    configDump.remove(configScrollText);
    Provider.of<ScrollTextNotifier>(context, listen: false)
        .removeListener(_onNotifierUpdate);
    super.dispose();
  }

  /// Exports the current state as JSON for remote control/API.
  JsonSerializable exportState() => _conf;

  /// Synchronizes local state when external updates occur via Provider.
  void _onNotifierUpdate() {
    if (mounted) {
      setState(() {
        _conf = Provider.of<ScrollTextNotifier>(context, listen: false)
            .scrollTextConfig;
      });
      _savePreferences();
    }
  }

  /// Triggers a UI refresh and updates the remote controller if enabled.
  void _triggerRerender() {
    final notifier = Provider.of<ScrollTextNotifier>(context, listen: false);
    notifier.updateScrollTextConfig(_conf);
    if (remotePairer().remoteControlEnabled) {
      remoteNotifier.updateScrollTextConfig(_conf);
    }
  }

  /// Combines UI update, remote sync, and persistence with debouncing.
  void _notifyAndSave() {
    _triggerRerender();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _savePreferences);
  }

  Future<void> _loadPreferences() async {
    try {
      final jsonStr = await _prefs.getString("fullScrollTextConfig");
      if (jsonStr != null) {
        setState(() {
          _conf = ScrollTextConfiguration.fromJson(jsonDecode(jsonStr));
        });
      }
    } catch (e) {
      debugPrint("Failed to load preferences: $e");
    }
    _triggerRerender();
  }

  Future<void> _savePreferences() async {
    if (remotePairer().remoteControlEnabled) {
      return;
    }
    try {
      await _prefs.setString(
          "fullScrollTextConfig", jsonEncode(_conf.toJson()));
    } catch (e) {
      debugPrint("Failed to save preferences: $e");
    }
  }

  // --- UI Level 1: Template List ---

  Widget _buildTemplateList(StateSetter innerSetState) {
    final templates = _conf.templates ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildListHeader(innerSetState),
        const Divider(),
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) =>
                _buildTemplateTile(index, innerSetState),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader(StateSetter innerSetState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Text Templates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          onPressed: () {
            innerSetState(() {
              final newTemplate = ScrollText(
                text: defaultScrollText,
                direction: "rtl",
                fontSize: 80,
                scrollSpeed: 1.0,
              );
              _conf.templates ??= [];
              _conf.templates!.add(newTemplate);
              _conf.currentTemplate = _conf.templates!.length - 1;
              _editingIndex = _conf.currentTemplate;
            });
            _notifyAndSave();
          },
        ),
      ],
    );
  }

  // --- UI Level 1: Template List Tile Optimization ---

  Widget _buildTemplateTile(int index, StateSetter innerSetState) {
    final item = _conf.templates![index];
    final bool isActive = index == _conf.currentTemplate;

    // Determine the color to display. Default to Black if null.
    final Color displayColor =
        item.fontColor != null ? Color(item.fontColor!) : Colors.black;

    return ListTile(
      selected: isActive,
      selectedTileColor: Colors.blue.withOpacity(0.05),
      // 1. Enhanced Leading: A circular container showing the template color
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.1), // Light tinted background
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.blue : displayColor.withOpacity(0.5),
            width: isActive ? 3 : 2,
          ),
        ),
        child: Icon(
          isActive ? Icons.play_arrow : Icons.text_fields,
          color:
              displayColor == Colors.transparent ? Colors.grey : displayColor,
          size: 20,
        ),
      ),
      title: Text(
        item.text ?? "Unnamed Template",
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          // Optional: You could also tint the title text with the color
          // color: displayColor.withAlpha(200),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // 2. Enhanced Subtitle: Added a small color indicator dot
      subtitle: Row(
        children: [
          Text("S: ${item.fontSize?.round()} / V: ${item.scrollSpeed}"),
          const SizedBox(width: 8),
          // Small color preview dot in subtitle
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.grey.withOpacity(0.5), width: 0.5),
            ),
          ),
        ],
      ),
      trailing: _buildItemMenu(index, innerSetState),
      onTap: () {
        innerSetState(() => _conf.currentTemplate = index);
        _notifyAndSave();
      },
    );
  }

  Widget _buildItemMenu(int index, StateSetter innerSetState) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        if (action == 'edit') {
          innerSetState(() => _editingIndex = index);
        } else if (action == 'delete') {
          _handleDelete(index, innerSetState);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'edit', child: _MenuLabel(Icons.edit, 'Edit', Colors.blue)),
        const PopupMenuItem(
            value: 'delete',
            child: _MenuLabel(Icons.delete, 'Delete', Colors.red)),
      ],
    );
  }

  void _handleDelete(int index, StateSetter innerSetState) {
    innerSetState(() {
      _conf.templates?.removeAt(index);
      // Ensure currentTemplate index remains valid after removal
      final count = _conf.templates?.length ?? 0;
      if (count == 0) {
        _conf.currentTemplate = 0;
      } else if (_conf.currentTemplate! >= count) {
        _conf.currentTemplate = count - 1;
      }
    });
    _notifyAndSave();
  }

  // --- UI Level 2: Editor ---

  Widget _buildEditor(StateSetter innerSetState) {
    // Safety check to prevent crashes if editingIndex becomes invalid
    if (_editingIndex == null ||
        _conf.templates == null ||
        _editingIndex! >= _conf.templates!.length) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _editingIndex = null));
      return const SizedBox.shrink();
    }

    final target = _conf.templates![_editingIndex!];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEditorHeader(innerSetState),
        const Divider(),
        TextFormField(
          key: Key("editor_$_editingIndex"),
          decoration: const InputDecoration(
              labelText: 'Display Text', border: OutlineInputBorder()),
          initialValue: target.text,
          onChanged: (val) {
            innerSetState(() => target.text = val);
            _notifyAndSave();
          },
        ),
        const SizedBox(height: 16),
        _buildDirectionDropdown(target, innerSetState),
        _buildSliderSetting("Font Size", target.fontSize ?? 80, 50, 150, 120,
            (val) {
          innerSetState(() => target.fontSize = val);
        }),
        _buildSliderSetting(
            "Scroll Speed", target.scrollSpeed ?? 1.0, 0, 10, 20, (val) {
          innerSetState(() => target.scrollSpeed = val);
        }),
        _buildColorPickerTile(target, innerSetState),
      ],
    );
  }

  Widget _buildEditorHeader(StateSetter innerSetState) {
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => innerSetState(() => _editingIndex = null)),
        const Text('Edit Configuration', style: TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildDirectionDropdown(ScrollText target, StateSetter innerSetState) {
    return DropdownButtonFormField<String>(
      value: target.direction == "rtl" ? "rtl" : "ltr",
      decoration: const InputDecoration(labelText: 'Scroll Direction'),
      items: const [
        DropdownMenuItem(value: "ltr", child: Text('Left to Right')),
        DropdownMenuItem(value: "rtl", child: Text('Right to Left')),
      ],
      onChanged: (val) {
        innerSetState(() => target.direction = val);
        _notifyAndSave();
      },
    );
  }

  Widget _buildSliderSetting(String label, double value, double min, double max,
      int divisions, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
              "$label: ${value is int ? value : value.toStringAsFixed(1)}"),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: (val) => setState(() => onChanged(val)),
          onChangeEnd: (_) => _notifyAndSave(),
        ),
      ],
    );
  }

  Widget _buildColorPickerTile(ScrollText target, StateSetter innerSetState) {
    return ListTile(
      title: const Text('Text Color'),
      subtitle:
          Text(target.fontColor == null ? "Default (Black)" : "Custom Color"),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: Color(target.fontColor ?? 0xFF000000),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ]),
      ),
      onTap: () async {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Select Color"),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: Color(target.fontColor ?? 0xFF000000),
                onColorChanged: (color) {
                  innerSetState(() => target.fontColor = color.toARGB32());
                  _notifyAndSave();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Main Logic ---

  void _showSettingsDialog() {
    setState(() => _editingIndex = null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, innerSetState) => Padding(
          // Important: viewInsets.bottom ensures the panel rises above the software keyboard.
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: _editingIndex == null
                ? _buildTemplateList(innerSetState)
                : _buildEditor(innerSetState),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FullScreenWrapper(
          fullScreen: appNotifier!.appState.underControl ?? false,
          child: ScrollTextPlayer(conf: _conf.getCurrentTemplate())),
      floatingActionButton: FloatingActionButton(
        heroTag: "scroll_settings",
        onPressed: _showSettingsDialog,
        child: const Icon(Icons.settings),
      ),
    );
  }
}

/// Helper for PopupMenu items to keep UI clean.
class _MenuLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuLabel(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
