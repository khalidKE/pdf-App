import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';

class ReadPdfScreen extends StatefulWidget {
  final String filePath;

  const ReadPdfScreen({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  State<ReadPdfScreen> createState() => _ReadPdfScreenState();
}

class _ReadPdfScreenState extends State<ReadPdfScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  PDFViewController? _pdfViewController;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0), // Slide from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Add to recent files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final file = File(widget.filePath);

      if (file.existsSync()) {
        final fileItem = FileItem(
          name: path.basename(widget.filePath),
          path: widget.filePath,
          size: file.lengthSync(),
          dateModified: file.lastModifiedSync(),
          type: FileType.pdf,
        );
        fileProvider.addRecentFile(fileItem);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(widget.filePath)], text: fileName);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'print':
                  _printPdf();
                  break;
                case 'favorite':
                  _toggleFavorite();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 8),
                    Text('print'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'favorite',
                child: Row(
                  children: [
                    Icon(
                      _isFavorite() ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: _isFavorite() ? Colors.red : null,
                    ),
                    const SizedBox(width: 8),
                    Text(_isFavorite()
                        ? 'remove_from_favorites'
                        : 'add_to_favorites'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: PDFView(
                    filePath: widget.filePath,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: true,
                    pageFling: true,
                    pageSnap: true,
                    defaultPage: _currentPage,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages!;
                        _isLoading = false;
                      });
                    },
                    onError: (error) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
                        ),
                      );
                    },
                    onPageError: (page, error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error loading page $page: $error'),
                        ),
                      );
                    },
                    onViewCreated: (PDFViewController pdfViewController) {
                      _pdfViewController = pdfViewController;
                    },
                    onPageChanged: (int? page, int? total) {
                      setState(() {
                        _currentPage = page!;
                      });
                    },
                  ),
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          // Page navigation bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _currentPage > 0
                      ? () {
                          _pdfViewController?.setPage(_currentPage - 1);
                        }
                      : null,
                ),
                Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          _pdfViewController?.setPage(_currentPage + 1);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isFavorite() {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    return fileProvider.isFavorite(widget.filePath);
  }

  void _toggleFavorite() {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final file = File(widget.filePath);

    if (file.existsSync()) {
      final fileItem = FileItem(
        name: path.basename(widget.filePath),
        path: widget.filePath,
        size: file.lengthSync(),
        dateModified: file.lastModifiedSync(),
        type: FileType.pdf,
      );
      fileProvider.toggleFavorite(fileItem);
    }
  }

  Future<void> _printPdf() async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => File(widget.filePath).readAsBytesSync(),
        name: path.basename(widget.filePath),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing PDF: $e')),
      );
    }
  }
}
