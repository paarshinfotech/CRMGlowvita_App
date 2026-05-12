import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// ─────────────────────────────────────────────
//  Data model for a canvas element
// ─────────────────────────────────────────────
enum ElementType { text, logo }

class CanvasElement {
  final String id;
  ElementType type;
  String text;
  Offset position;
  double fontSize;
  Color textColor;
  FontWeight fontWeight;
  Uint8List? imageBytes;
  double width;
  double height;
  double opacity;
  double rotation;

  CanvasElement({
    required this.id,
    required this.type,
    this.text = '',
    this.position = const Offset(80, 80),
    this.fontSize = 18,
    this.textColor = Colors.black,
    this.fontWeight = FontWeight.w600,
    this.imageBytes,
    this.width = 100,
    this.height = 100,
    this.opacity = 1.0,
    this.rotation = 0.0,
  });
}

// ─────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────
class SocialMediaEditorPage extends StatefulWidget {
  final String templateTitle;
  const SocialMediaEditorPage({super.key, this.templateTitle = 'Test'});

  @override
  State<SocialMediaEditorPage> createState() => _SocialMediaEditorPageState();
}

class _SocialMediaEditorPageState extends State<SocialMediaEditorPage> {
  final List<CanvasElement> _elements = [];
  CanvasElement? _selected;
  int _idCounter = 0;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _backgroundImage;
  final GlobalKey _canvasKey = GlobalKey();

  String _nextId() => 'el_${_idCounter++}';

  void _addText() {
    final el = CanvasElement(
      id: _nextId(),
      type: ElementType.text,
      text: 'New Text',
      position: Offset(
        60 + _elements.length * 12.0,
        80 + _elements.length * 12.0,
      ),
    );
    setState(() {
      _elements.add(el);
      _selected = el;
    });
  }

  Future<void> _uploadLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final el = CanvasElement(
      id: _nextId(),
      type: ElementType.logo,
      position: Offset(80, 80 + _elements.length * 12.0),
      imageBytes: bytes,
    );
    setState(() {
      _elements.add(el);
      _selected = el;
    });
  }

  void _deleteSelected() {
    if (_selected == null) return;
    setState(() {
      _elements.removeWhere((e) => e.id == _selected!.id);
      _selected = null;
    });
  }

  Future<void> _pickBackground() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _backgroundImage = bytes;
    });
  }

  Future<void> _downloadImage() async {
    try {
      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/GlowVita_Post_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post saved to temporary files! Opening...'),
          backgroundColor: const Color(0xFF28A745),
        ),
      );

      await OpenFile.open(imagePath);
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.templateTitle,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _TopBarBtn(
            label: 'Download',
            icon: Icons.download_rounded,
            bg: const Color(0xFF28A745),
            fg: Colors.white,
            onTap: _downloadImage,
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: Stack(
        children: [
          _buildCanvas(),
          _buildDraggablePanel(),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 52.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Text(
            'Edit Template: ${widget.templateTitle}',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          _TopBarBtn(
            label: 'Download',
            icon: Icons.download_rounded,
            bg: const Color(0xFF28A745),
            fg: Colors.white,
            onTap: () {},
          ),
          SizedBox(width: 8.w),
          _TopBarBtn(
            label: 'Save',
            icon: Icons.save_outlined,
            bg: Colors.white,
            fg: const Color(0xFF1A1A2E),
            border: const Color(0xFFD1D1D1),
            onTap: () {},
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(16.w),
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _sectionTitle('Add Elements'),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(
                      icon: Icons.text_fields_rounded,
                      label: 'Text',
                      onTap: _addText,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _OutlineBtn(
                      icon: Icons.upload_file_outlined,
                      label: 'Logo',
                      onTap: _uploadLogo,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _OutlineBtn(
                      icon: Icons.image_outlined,
                      label: 'BG',
                      onTap: _pickBackground,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 16.h),
              _sectionTitle('Edit Element'),
              SizedBox(height: 12.h),
              _selected == null ? _emptyEditState() : _editPanel(_selected!),
            ],
          ),
        );
      },
    );
  }

  Widget _editPanel(CanvasElement el) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (el.type == ElementType.text) ...[
          _label('Content'),
          SizedBox(height: 5.h),
          _InlineField(
            value: el.text,
            onChanged: (v) => setState(() => el.text = v),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Size'),
                    _compactSlider(
                      value: el.fontSize,
                      min: 8,
                      max: 72,
                      onChanged: (v) => setState(() => el.fontSize = v),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Opacity'),
                    _compactSlider(
                      value: el.opacity,
                      min: 0,
                      max: 1,
                      onChanged: (v) => setState(() => el.opacity = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _label('Weight'),
          SizedBox(height: 6.h),
          Row(
            children: [
              _Chip(
                label: 'Regular',
                weight: FontWeight.normal,
                active: el.fontWeight == FontWeight.normal,
                onTap: () => setState(() => el.fontWeight = FontWeight.normal),
              ),
              SizedBox(width: 6.w),
              _Chip(
                label: 'Semi',
                weight: FontWeight.w600,
                active: el.fontWeight == FontWeight.w600,
                onTap: () => setState(() => el.fontWeight = FontWeight.w600),
              ),
              SizedBox(width: 6.w),
              _Chip(
                label: 'Bold',
                weight: FontWeight.bold,
                active: el.fontWeight == FontWeight.bold,
                onTap: () => setState(() => el.fontWeight = FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _label('Color'),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _palette
                  .map(
                    (c) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _Dot(
                        color: c,
                        active: el.textColor.value == c.value,
                        onTap: () => setState(() => el.textColor = c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ] else ...[
          _label('Logo Properties'),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Size'),
                    _compactSlider(
                      value: el.width,
                      min: 20,
                      max: 300,
                      onChanged: (v) => setState(() {
                        el.width = v;
                        el.height = v;
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Opacity'),
                    _compactSlider(
                      value: el.opacity,
                      min: 0,
                      max: 1,
                      onChanged: (v) => setState(() => el.opacity = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 12.h),
        _label('Rotation'),
        _compactSlider(
          value: el.rotation,
          min: -3.14,
          max: 3.14,
          onChanged: (v) => setState(() => el.rotation = v),
        ),
        SizedBox(height: 20.h),
        _deleteBtn(),
      ],
    );
  }

  Widget _compactSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: const Color(0xFF3B2D3D),
        inactiveTrackColor: Colors.grey.shade200,
        thumbColor: const Color(0xFF3B2D3D),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }

  Widget _deleteBtn() {
    return GestureDetector(
      onTap: _deleteSelected,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
            SizedBox(width: 6.w),
            Text(
              'Delete Element',
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Canvas ────────────────────────────────────
  Widget _buildCanvas() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(bottom: 0.1.sh),
      child: Center(
        child: RepaintBoundary(
          key: _canvasKey,
          child: GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: Container(
              width: 380.w,
              height: 380.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Stack(
                  children: [
                    if (_backgroundImage != null)
                      SizedBox.expand(
                        child: Image.memory(
                          _backgroundImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (_elements.isEmpty && _backgroundImage == null)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Add elements from the panel below',
                              style: GoogleFonts.poppins(
                                fontSize: 9.sp,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._elements.map(_canvasItem),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _canvasItem(CanvasElement el) {
    final isSel = _selected?.id == el.id;
    return Positioned(
      left: el.position.dx,
      top: el.position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selected = el),
        onPanUpdate: (d) => setState(() => el.position += d.delta),
        child: Transform.rotate(
          angle: el.rotation,
          child: Opacity(
            opacity: el.opacity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSel ? const Color(0xFF3B2D3D) : Colors.transparent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                  child: el.type == ElementType.text
                      ? Text(
                          el.text,
                          style: GoogleFonts.poppins(
                            fontSize: el.fontSize.sp,
                            fontWeight: el.fontWeight,
                            color: el.textColor,
                          ),
                        )
                      : (el.imageBytes != null
                            ? Image.memory(
                                el.imageBytes!,
                                width: el.width.w,
                                height: el.height.w,
                                fit: BoxFit.contain,
                              )
                            : const SizedBox()),
                ),
                if (isSel)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: _deleteSelected,
                      child: Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
      );

  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      );

  Widget _emptyEditState() {
    return Column(
      children: [
        SizedBox(height: 8.h),
        Icon(
          Icons.open_with_rounded,
          size: 28,
          color: Colors.grey.shade300,
        ),
        SizedBox(height: 10.h),
        Text(
          'Select an element on the canvas to edit its properties.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 9.sp,
            color: Colors.grey.shade500,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];
}

// ─────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────

class _TopBarBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, fg;
  final Color? border;
  final VoidCallback onTap;

  const _TopBarBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7.r),
          border: border != null ? Border.all(color: border!) : null,
          boxShadow: bg != Colors.white
              ? [
                  BoxShadow(
                    color: bg.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            SizedBox(width: 7.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _InlineField({required this.value, required this.onChanged});

  @override
  State<_InlineField> createState() => _InlineFieldState();
}

class _InlineFieldState extends State<_InlineField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_InlineField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F8),
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          color: const Color(0xFF1A1A2E),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final FontWeight weight;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.weight,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B2D3D) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8.sp,
            fontWeight: weight,
            color: active ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _Dot({required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22.w,
        height: 22.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? const Color(0xFF3B2D3D) : Colors.grey.shade300,
            width: active ? 2 : 1,
          ),
        ),
        child: active
            ? Icon(
                Icons.check_rounded,
                size: 11,
                color: color == Colors.white ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}
