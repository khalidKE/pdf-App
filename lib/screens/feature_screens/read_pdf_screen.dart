import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ReadPdfScreen extends StatefulWidget {
  final String filePath;
  
  const ReadPdfScreen({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  State<ReadPdfScreen> createState() => _ReadPdfScreenState();
}

class _ReadPdfScreenState extends State<ReadPdfScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  PDFViewController? _pdfViewController;
  
  @override
  void initState() {
    super.initState();
    
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
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    const Icon(Icons.print, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.translate('print')),
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
                        ? loc.translate('remove_from_favorites')
                        : loc.translate('add_to_favorites')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages!;
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
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
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
    // Implement printing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('printing_not_implemented')),
      ),
    );
  }
}
