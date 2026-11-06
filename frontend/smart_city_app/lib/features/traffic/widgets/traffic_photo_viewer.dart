import 'package:flutter/material.dart';

import '../models/traffic_issue_model.dart';

class TrafficPhotoViewer extends StatefulWidget {
  final List<TrafficPhoto> photos;
  final int initialIndex;

  const TrafficPhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<TrafficPhotoViewer> createState() => _TrafficPhotoViewerState();
}

class _TrafficPhotoViewerState extends State<TrafficPhotoViewer> {
  late final PageController _pages;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.photos.isEmpty ? 0 : widget.initialIndex.clamp(0, widget.photos.length - 1).toInt();
    _pages = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) => _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(widget.photos.isEmpty
            ? 'Evidence photos'
            : 'Photo ${_index + 1} of ${widget.photos.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close photo viewer',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.photos.isEmpty
          ? const Center(
              child: Text('No photos available.',
                  style: TextStyle(color: Colors.white70)),
            )
          : Column(children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: widget.photos.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, index) {
                    final photo = widget.photos[index];
                    final url = Uri.tryParse(photo.fileUrl);
                    final valid = url != null && url.hasAuthority &&
                        (url.scheme == 'https' || url.scheme == 'http');
                    if (!valid) {
                      return const Center(child: Text(
                        'Photo URL is not available.',
                        style: TextStyle(color: Colors.white70),
                      ));
                    }
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: Image.network(
                          photo.fileUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Unable to load this photo.',
                                style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(children: [
                    Text(widget.photos[_index].fileName,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 7),
                    const Text('Pinch to zoom • Swipe to change photo',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                        ),
                        TextButton.icon(
                          onPressed: _index + 1 < widget.photos.length
                              ? () => _goTo(_index + 1) : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }
}
