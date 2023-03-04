import 'package:flutter/material.dart';
import 'package:side_menu/src/data/side_menu_item_data.dart';

class SideMenuData {
  const SideMenuData({
    this.customChild,
    this.header,
    this.footer,
    this.items,
  }) : assert(customChild != null || items != null);

  final Widget? customChild, header, footer;
  final List<SideMenuItemData>? items;
}
