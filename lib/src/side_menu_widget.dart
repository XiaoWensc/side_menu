import 'package:flutter/material.dart';
import 'package:side_menu/src/component/resizer.dart';
import 'package:side_menu/src/component/resizer_toggle.dart';
import 'package:side_menu/src/data/resizer_data.dart';
import 'package:side_menu/src/data/resizer_toggle_data.dart';
import 'package:side_menu/src/data/side_menu_builder_data.dart';
import 'package:side_menu/src/data/side_menu_data.dart';
import 'package:side_menu/src/side_menu_body.dart';
import 'package:side_menu/src/side_menu_controller.dart';
import 'package:side_menu/src/side_menu_mode.dart';
import 'package:side_menu/src/side_menu_position.dart';
import 'package:side_menu/src/side_menu_priority.dart';
import 'package:side_menu/src/side_menu_width_mixin.dart';
import 'package:side_menu/src/utils/constants.dart';

typedef SideMenuBuilder = SideMenuData Function(SideMenuBuilderData data);

class SideMenuWidget extends StatefulWidget {
  const SideMenuWidget({
    Key? key,
    required this.builder,
    this.controller,
    this.mode = SideMenuMode.auto,
    this.priority = SideMenuPriority.mode,
    this.position = SideMenuPosition.left,
    this.minWidth = Constants.minWidth,
    this.maxWidth = Constants.maxWidth,
    this.hasResizer = true,
    this.hasResizerToggle = true,
    this.resizerData,
    this.resizerToggleData,
    this.backgroundColor,
  })  : assert(minWidth >= 0.0),
        assert(maxWidth > 0.0),
        assert(priority == SideMenuPriority.sizer ? hasResizer : true),
        assert(resizerData != null ? hasResizer : true),
        assert(resizerToggleData != null ? hasResizerToggle : true),
        super(key: key);

  final SideMenuBuilder builder;

  final SideMenuController? controller;

  final SideMenuMode mode;

  final SideMenuPriority priority;

  final SideMenuPosition position;

  final double minWidth, maxWidth;

  final bool hasResizer;

  final ResizerData? resizerData;

  final bool hasResizerToggle;

  final ResizerToggleData? resizerToggleData;

  final Color? backgroundColor;

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget>
    with SideMenuWidthMixin {
  double _currentWidth = Constants.zeroWidth;
  bool _endAnim = true;

  @override
  void initState() {
    if (widget.controller != null) {
      widget.controller?.open = _openMenu;
      widget.controller?.close = _closeMenu;
      widget.controller?.toggle = _toggleMenu;
    }
    super.initState();
  }

  /// 展开
  void _openMenu() {
    setState(() {
      _endAnim = false;
      _currentWidth = widget.maxWidth;
    });
  }

  /// 收起
  void _closeMenu() {
    setState(() {
      _endAnim = false;
      _currentWidth = widget.minWidth;
    });
  }

  /// 展开&收起
  void _toggleMenu() {
    setState(() {
      _endAnim = false;
      _currentWidth =
          _currentWidth == widget.minWidth ? widget.maxWidth : widget.minWidth;
    });
  }

  @override
  void didUpdateWidget(covariant SideMenuWidget oldWidget) {
    if (oldWidget.mode != widget.mode ||
        oldWidget.priority != widget.priority ||
        oldWidget.hasResizer != widget.hasResizer ||
        oldWidget.minWidth != widget.minWidth ||
        oldWidget.maxWidth != widget.maxWidth) {
      _calculateMenuWidthSize();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _calculateMenuWidthSize();
    super.didChangeDependencies();
  }

  void _calculateMenuWidthSize() {
    _currentWidth = calculateWidthSize(
      priority: widget.priority,
      hasResizer: widget.hasResizer,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      currentWidth: _currentWidth,
      mode: widget.mode,
      deviceWidth: MediaQuery.of(context).size.width,
    );
  }

  @override
  Widget build(BuildContext context) => _createView();

  Widget _createView() {
    final size = MediaQuery.of(context).size;
    final content = _content(size);

    if (widget.hasResizer || widget.hasResizerToggle) {
      if (widget.hasResizer && widget.hasResizerToggle) {
        return _hasResizerToggle(
          child: _hasResizer(child: content),
        );
      } else if (widget.hasResizer) {
        return _hasResizer(child: content);
      } else {
        return _hasResizerToggle(child: content);
      }
    } else {
      return content;
    }
  }

  Widget _content(Size size) {
    return AnimatedContainer(
      duration: Constants.duration,
      width: _currentWidth,
      color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(
        minHeight: size.height,
        maxHeight: size.height,
        minWidth: widget.minWidth,
        maxWidth: widget.maxWidth,
      ),
      child: SideMenuBody(
        isOpen: _currentWidth != widget.minWidth,
        minWidth: widget.minWidth,
        endAnim: _endAnim,
        currentWidth: _currentWidth,
        data: _builder(),
      ),
      onEnd: () => setState(() => _endAnim = true),
    );
  }

  SideMenuData _builder() {
    return widget.builder(SideMenuBuilderData(
      currentWidth: _currentWidth,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      isOpen: _currentWidth != widget.minWidth,
    ));
  }

  Widget _resizer() {
    return Resizer(
      data: widget.resizerData,
      onPanUpdate: (details) {
        late final double x;
        if (widget.position == SideMenuPosition.left) {
          x = details.globalPosition.dx;
        } else {
          x = MediaQuery.of(context).size.width - details.globalPosition.dx;
        }
        if (x >= widget.minWidth && x <= widget.maxWidth) {
          setState(() {
            _currentWidth = x;
          });
        } else if (x < Constants.minWidth && _currentWidth != widget.minWidth) {
          setState(() {
            _currentWidth = widget.minWidth;
          });
        } else if (x > Constants.maxWidth && _currentWidth != widget.maxWidth) {
          setState(() {
            _currentWidth = widget.maxWidth;
          });
        }
      },
    );
  }

  Widget _hasResizer({required Widget child}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.position == SideMenuPosition.right) _resizer(),
        child,
        if (widget.position == SideMenuPosition.left) _resizer(),
      ],
    );
  }

  Widget _resizerToggle() {
    return ResizerToggle(
      data: widget.resizerToggleData,
      rightArrow: _currentWidth == widget.minWidth,
      leftPosition: widget.position == SideMenuPosition.left,
      onTap: () => _toggleMenu(),
    );
  }

  Widget _hasResizerToggle({required Widget child}) {
    return Stack(
      alignment: widget.position == SideMenuPosition.left
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      children: [
        child,
        _resizerToggle(),
      ],
    );
  }
}
