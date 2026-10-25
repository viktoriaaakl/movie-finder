import 'package:flutter/material.dart';

/// A film poster with rounded corners and a placeholder when there is none.
class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        color: scheme.onSurfaceVariant,
        size: width / 2.5,
      ),
    );

    final url = this.url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              // Lets posters load in the browser even when the image server
              // doesn't allow cross-origin requests.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}
