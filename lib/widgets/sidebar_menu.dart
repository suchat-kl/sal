import 'package:flutter/material.dart';

import '../config/menu_data.dart';
import '../config/theme.dart';
import '../utils/link.dart';
import 'app_logo.dart';

/// เมนูข้าง — ใช้ได้สองแบบเหมือน HTC
/// * เมนูเลื่อนออก (drawer): จอแคบหรือยังไม่ได้ตรึง
/// * ตรึงไว้ข้างซ้าย ([docked]): [collapsed] = เหลือแต่ไอคอน กดปุ่มหรือไอคอนกลุ่มแล้วขยายเห็นชื่อ
class SidebarMenu extends StatefulWidget {
  final bool docked;
  final bool collapsed;
  final bool canPin;
  final bool pinned;
  final String selectedId;
  final VoidCallback onTogglePinned;
  final VoidCallback? onToggleCollapsed;
  final ValueChanged<String> onSelectInternal;

  /// กว้างตอนเหลือแต่ไอคอน
  static const double railWidth = 76;

  /// กว้างตอนเห็นชื่อเมนู
  static const double fullWidth = 280;

  const SidebarMenu({
    super.key,
    this.docked = false,
    this.collapsed = false,
    required this.canPin,
    required this.pinned,
    required this.selectedId,
    required this.onTogglePinned,
    required this.onSelectInternal,
    this.onToggleCollapsed,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  /// กลุ่มเมนูที่เปิดอยู่
  final Set<String> _open = {'tax', 'funeral'};

  bool get _rail => widget.docked && widget.collapsed;

  void _tap(MenuNode node) {
    if (node.isGroup) {
      if (_rail) {
        // ตอนเหลือแต่ไอคอน กดกลุ่มแล้วขยายเมนูและเปิดกลุ่มนั้นให้เลย
        setState(() => _open.add(node.id));
        widget.onToggleCollapsed?.call();
      } else {
        setState(
          () => _open.contains(node.id)
              ? _open.remove(node.id)
              : _open.add(node.id),
        );
      }
      return;
    }
    if (!widget.docked) Navigator.of(context).pop(); // ปิด drawer
    if (node.url != null) {
      openLink(context, node.url!);
    } else {
      widget.onSelectInternal(node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = _rail ? SidebarMenu.railWidth : SidebarMenu.fullWidth;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: const BoxDecoration(gradient: AppTheme.sidebarGradient),
      // จัดวางเนื้อหาที่ความกว้างปลายทางเลย แล้วตัดส่วนเกินระหว่างแอนิเมชัน
      // ไม่งั้นช่วงที่กว้างค่อย ๆ เปลี่ยน แถวเมนูจะถูกบีบจนล้น
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: width,
          maxWidth: width,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Divider(height: 1, color: Color(0x1FFFFFFF)),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: _rail ? 10 : 12,
                    ),
                    children: [
                      if (!_rail) _sectionTitle('เมนูหลัก'),
                      for (final node in MenuData.items) ..._buildNode(node),
                    ],
                  ),
                ),
                if (!_rail) _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// แถวบนสุด: ปุ่มย่อ/ขยาย และปุ่มตรึง/เลิกตรึง
  Widget _buildTopBar() {
    final pinBtn = widget.canPin
        ? IconButton(
            tooltip: widget.pinned ? 'เลิกตรึงเมนู' : 'ตรึงเมนูไว้ข้างซ้าย',
            onPressed: widget.onTogglePinned,
            icon: Icon(
              widget.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: widget.pinned ? AppTheme.accent : Colors.white70,
              size: 20,
            ),
          )
        : null;
    final collapseBtn = widget.docked
        ? IconButton(
            tooltip: _rail ? 'ขยายเมนู' : 'ย่อเมนูเหลือแต่ไอคอน',
            onPressed: widget.onToggleCollapsed,
            icon: Icon(
              _rail ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: Colors.white,
              size: 22,
            ),
          )
        : null;

    if (_rail) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [?collapseBtn, ?pinBtn]),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          const AppLogo(size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'งานเงินเดือน',
              style: AppTheme.heading(17, color: Colors.white),
            ),
          ),
          ?pinBtn,
          ?collapseBtn,
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: 12,
        letterSpacing: 0.6,
        color: Colors.white54,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  List<Widget> _buildNode(MenuNode node) {
    final selected = node.id == widget.selectedId;
    final open = _open.contains(node.id);
    if (_rail) {
      return [_railIcon(node, selected)];
    }
    return [
      _tile(
        node,
        selected: selected,
        trailing: node.isGroup
            ? AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              )
            : node.url != null
            ? const Icon(
                Icons.open_in_new_rounded,
                color: Colors.white38,
                size: 15,
              )
            : null,
      ),
      if (node.isGroup)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: open
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0x33FFFFFF))),
              ),
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  for (final c in node.children)
                    _tile(
                      c,
                      small: true,
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Widget _tile(
    MenuNode node, {
    bool selected = false,
    bool small = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.9)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: () => _tap(node),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: small ? 9 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  node.icon,
                  size: small ? 18 : 22,
                  color: selected ? Colors.white : AppTheme.primaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: small ? 14 : 15,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.88),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _railIcon(MenuNode node, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: node.title,
        preferBelow: false,
        child: Material(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            hoverColor: Colors.white.withValues(alpha: 0.08),
            onTap: () => _tap(node),
            child: SizedBox(
              height: 50,
              child: Icon(
                node.icon,
                color: selected ? Colors.white : AppTheme.primaryLight,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() => Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: const Row(
      children: [
        Icon(Icons.phone_in_talk_rounded, color: AppTheme.accent, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'ฝ่ายบัญชี โทร. 25035, 25036',
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    ),
  );
}
