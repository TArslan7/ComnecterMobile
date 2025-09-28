import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';

class RadarRangeSlider extends StatefulWidget {
  final RadarRangeSettings settings;
  final ValueChanged<RadarRangeSettings> onChanged;
  final int userCount;

  const RadarRangeSlider({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.userCount,
  });

  @override
  State<RadarRangeSlider> createState() => _RadarRangeSliderState();
}

class _RadarRangeSliderState extends State<RadarRangeSlider> {
  late TextEditingController _textController;
  late double _currentRange;
  bool _isEditing = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.settings.rangeKm;
    _textController = TextEditingController(
      text: widget.settings.getDisplayValue(),
    );
  }

  @override
  void didUpdateWidget(RadarRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.rangeKm != widget.settings.rangeKm) {
      _currentRange = widget.settings.rangeKm;
      _textController.text = widget.settings.getDisplayValue();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateRange(double newRange) {
    setState(() {
      _currentRange = newRange;
    });
    
    final newSettings = widget.settings.copyWith(rangeKm: newRange);
    widget.onChanged(newSettings);
  }

  void _updateRangeFromText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Parse the text to extract numeric value
    final regex = RegExp(r'^(\d+(?:\.\d+)?)\s*(km|mi|miles?)?$', caseSensitive: false);
    final match = regex.firstMatch(text);
    
    if (match != null) {
      final value = double.tryParse(match.group(1) ?? '');
      final unit = match.group(2)?.toLowerCase();
      
      if (value != null && value > 0) {
        double rangeKm = value;
        
        // Convert to km if needed
        if (unit == 'mi' || unit == 'mile' || unit == 'miles') {
          rangeKm = widget.settings.toKm(value);
        }
        
        // Apply constraints
        rangeKm = rangeKm.clamp(0.1, 200.0);
        
        _updateRange(rangeKm);
      }
    }
    
    setState(() {
      _isEditing = false;
    });
  }

  void _toggleUnit() {
    final newSettings = widget.settings.copyWith(useMiles: !widget.settings.useMiles);
    widget.onChanged(newSettings);
    _textController.text = newSettings.getDisplayValue();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _textController.text.length,
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _textController.text = widget.settings.getDisplayValue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeMode = widget.settings.getRangeMode(_currentRange);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.settings.rangeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with range info - clickable to expand/collapse
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.radar,
                  color: widget.settings.rangeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Radar Range',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.settings.rangeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rangeMode.name.toUpperCase(),
                    style: TextStyle(
                      color: widget.settings.rangeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Unit toggle button
                GestureDetector(
                  onTap: _toggleUnit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.settings.rangeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.settings.rangeColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Km/Mi',
                          style: TextStyle(
                            color: widget.settings.rangeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz,
                          color: widget.settings.rangeColor,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.settings.rangeColor,
                  size: 20,
                ),
              ],
            ),
          ),
          
          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: _isExpanded ? Column(
              children: [
                const SizedBox(height: 16),
                
                // Range display and input
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _textController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*\s*(km|mi|miles?)?$')),
                        ],
                        onSubmitted: (_) => _updateRangeFromText(),
                        onEditingComplete: _updateRangeFromText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.settings.rangeColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter range',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.settings.rangeColor.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.settings.rangeColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _startEditing,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: widget.settings.rangeColor.withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.settings.getDisplayValue(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.settings.rangeColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: widget.settings.rangeColor.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              
              if (_isEditing) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _updateRangeFromText,
                  icon: const Icon(Icons.check),
                  color: Colors.green,
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: _cancelEditing,
                  icon: const Icon(Icons.close),
                  color: Colors.red,
                  iconSize: 20,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.settings.rangeColor,
              inactiveTrackColor: widget.settings.rangeColor.withValues(alpha: 0.3),
              thumbColor: widget.settings.rangeColor,
              overlayColor: widget.settings.rangeColor.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _getSliderValue(),
              min: 0.1,
              max: widget.settings.useMiles ? 200.0 : 200.0,
              divisions: _getDivisions(),
              onChanged: (value) {
                final rangeKm = widget.settings.useMiles ? widget.settings.toKm(value) : value;
                _updateRange(rangeKm);
              },
            ),
          ),
          
          // Range labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.settings.useMiles ? '0.1 mi' : '0.1 km',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                widget.settings.useMiles ? '200 mi' : '200 km',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Real-time feedback
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Range: ${widget.settings.getDisplayValue()} • ${widget.userCount} users',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Mode-specific features
          if (widget.settings.shouldUseClusters() || widget.settings.shouldUseHeatmap())
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.settings.rangeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: widget.settings.rangeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.settings.shouldUseHeatmap() 
                        ? 'Heatmap view enabled for large ranges'
                        : 'Cluster view enabled for large ranges',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.settings.rangeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
              ],
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  double _getSliderValue() {
    if (widget.settings.useMiles) {
      final milesValue = widget.settings.toMiles(_currentRange);
      return milesValue.clamp(0.1, 200.0);
    } else {
      return _currentRange.clamp(0.1, 200.0);
    }
  }

  int _getDivisions() {
    if (widget.settings.useMiles) {
      // For miles: more divisions for better precision
      if (_currentRange <= 10) return 90; // 0.1mi steps (0.1 to 10 miles)
      if (_currentRange <= 50) return 490; // 0.1mi steps (0.1 to 50 miles)
      if (_currentRange <= 100) return 990; // 0.1mi steps (0.1 to 100 miles)
      return 1999; // 0.1mi steps (0.1 to 200 miles)
    } else {
      // For km: more divisions for better precision
      if (_currentRange <= 10) return 90; // 0.1km steps (0.1 to 10 km)
      if (_currentRange <= 50) return 490; // 0.1km steps (0.1 to 50 km)
      if (_currentRange <= 100) return 990; // 0.1km steps (0.1 to 100 km)
      return 1999; // 0.1km steps (0.1 to 200 km)
    }
  }
}
