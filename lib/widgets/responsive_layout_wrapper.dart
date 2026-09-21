import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class ResponsiveLayoutWrapper extends StatelessWidget {
  final Widget mobileContent;
  final Widget desktopContent;
  final bool scrollableDesktop;
  final double desktopMaxWidth;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.mobileContent,
    required this.desktopContent,
    this.scrollableDesktop = true,
    this.desktopMaxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTablet(context);
    
    Widget desktopInner = Container(
      width: double.infinity,
      constraints: scrollableDesktop 
          ? BoxConstraints(minHeight: MediaQuery.of(context).size.height)
          : const BoxConstraints(),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktopMaxWidth),
        child: desktopContent,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: isDesktop
            ? (scrollableDesktop ? SingleChildScrollView(child: desktopInner) : desktopInner)
            : mobileContent,
      ),
    );
  }
}
