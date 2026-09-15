import 'package:flutter/material.dart';

class ResponsiveLayoutWrapper extends StatelessWidget {
  final Widget mobileContent;
  final Widget desktopContent;
  final Color desktopBackgroundColor;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.mobileContent,
    required this.desktopContent,
    this.desktopBackgroundColor = const Color(0xFFF3F4F6),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 600;
        
        return Scaffold(
          backgroundColor: isDesktop 
              ? desktopBackgroundColor 
              : Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: isDesktop
                ? SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Container(
                        width: 430,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: desktopContent,
                        ),
                      ),
                    ),
                  )
                : mobileContent,
          ),
        );
      },
    );
  }
}
