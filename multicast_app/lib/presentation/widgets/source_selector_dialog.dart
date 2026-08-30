import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/capture_source.dart';
import '../../data/services/base_desktop_capturer.dart';

class SourceSelectorDialog extends ConsumerStatefulWidget {
  const SourceSelectorDialog({super.key});

  @override
  ConsumerState<SourceSelectorDialog> createState() => _SourceSelectorDialogState();
}

class _SourceSelectorDialogState extends ConsumerState<SourceSelectorDialog> {
  List<CaptureSource> _sources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    try {
      final service = ref.read(unifiedDesktopCaptureServiceProvider);
      final sources = await service.getAvailableSources();
      if (mounted) {
        setState(() {
          _sources = sources;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load screen sources: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Screen or Window'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sources.isEmpty
                ? const Center(child: Text('No sources found.'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 16 / 10,
                    ),
                    itemCount: _sources.length,
                    itemBuilder: (context, index) {
                      final source = _sources[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop(source);
                        },
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: source.thumbnail != null
                                    ? Image.memory(
                                        source.thumbnail!,
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(child: Icon(Icons.desktop_windows)),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                color: Colors.black54,
                                child: Text(
                                  source.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loadSources,
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

Future<CaptureSource?> showSourceSelectorDialog(BuildContext context) {
  return showDialog<CaptureSource>(
    context: context,
    builder: (context) => const SourceSelectorDialog(),
  );
}
