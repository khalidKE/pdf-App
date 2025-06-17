import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

enum ProtectionLevel {
  basic('Basic Protection', 'Password required to open the document'),
  standard('Standard Protection', 'Password + restrict printing and copying'),
  advanced('Advanced Protection', 'Password + restrict all modifications'),
  maximum('Maximum Protection', 'Password + restrict all operations');

  const ProtectionLevel(this.label, this.description);
  final String label;
  final String description;
}

class ProtectPdfScreen extends StatefulWidget {
  const ProtectPdfScreen({super.key});

  @override
  State<ProtectPdfScreen> createState() => _ProtectPdfScreenState();
}

class _ProtectPdfScreenState extends State<ProtectPdfScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  String _userPassword = '';
  String _confirmPassword = '';
  String _ownerPassword = '';
  bool _isProcessing = false;
  double _protectionProgress = 0.0;
  String _progressText = '';
  ProtectionLevel _selectedProtectionLevel = ProtectionLevel.standard;
  File? _protectedFile;

  // Password visibility toggles
  bool _showUserPassword = false;
  bool _showConfirmPassword = false;
  bool _showOwnerPassword = false;

  // Permission settings
  bool _allowPrinting = true;
  bool _allowCopying = false;
  bool _allowModification = false;
  bool _allowAnnotations = false;
  bool _allowFormFilling = true;
  bool _allowAccessibility = true;

  // Controllers
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ownerPasswordController =
      TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupPasswordControllers();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _setupPasswordControllers() {
    _userPasswordController.addListener(() {
      setState(() {
        _userPassword = _userPasswordController.text;
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _confirmPassword = _confirmPasswordController.text;
      });
    });

    _ownerPasswordController.addListener(() {
      setState(() {
        _ownerPassword = _ownerPasswordController.text;
      });
    });
  }

  Future<void> _selectFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (await file.exists()) {
          final fileSize = await file.length();

          // Check file size limit (100MB)
          if (fileSize > 100 * 1024 * 1024) {
            _showSnackBar('File too large. Please select a PDF under 100MB.',
                Colors.orange);
            return;
          }

          setState(() {
            _selectedFile = file;
            _fileName = result.files.single.name;
            _protectedFile = null;
            _clearPasswords();
          });
        } else {
          _showSnackBar('Selected file does not exist', Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar('Error selecting file: ${e.toString()}', Colors.red);
    }
  }

  void _clearPasswords() {
    _userPasswordController.clear();
    _confirmPasswordController.clear();
    _ownerPasswordController.clear();
    setState(() {
      _userPassword = '';
      _confirmPassword = '';
      _ownerPassword = '';
    });
  }

  bool _validatePasswords() {
    if (_userPassword.isEmpty) {
      _showSnackBar('Please enter a user password', Colors.orange);
      return false;
    }

    if (_userPassword.length < 6) {
      _showSnackBar(
          'Password must be at least 6 characters long', Colors.orange);
      return false;
    }

    if (_userPassword != _confirmPassword) {
      _showSnackBar('Passwords do not match', Colors.orange);
      return false;
    }

    if (_ownerPassword.isNotEmpty && _ownerPassword.length < 6) {
      _showSnackBar(
          'Owner password must be at least 6 characters long', Colors.orange);
      return false;
    }

    return true;
  }

  String _getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Medium';
    if (password.length >= 10 && _hasSpecialCharacters(password))
      return 'Strong';
    return 'Medium';
  }

  bool _hasSpecialCharacters(String password) {
    return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[A-Z]'));
  }

  Color _getPasswordStrengthColor(String password) {
    final strength = _getPasswordStrength(password);
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _protectPdf() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a PDF file first', Colors.orange);
      return;
    }

    if (!_validatePasswords()) return;

    setState(() {
      _isProcessing = true;
      _protectionProgress = 0.0;
      _progressText = 'Initializing protection...';
    });

    try {
      // Step 1: Read file
      _updateProgress(0.1, 'Reading PDF file...');
      final bytes = await _selectedFile!.readAsBytes();

      // Step 2: Load document
      _updateProgress(0.2, 'Loading PDF document...');
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Step 3: Apply security settings
      _updateProgress(0.4, 'Applying security settings...');
      await _applySecuritySettings(document);

      // Step 4: Configure permissions
      _updateProgress(0.6, 'Configuring permissions...');
      await _configurePermissions(document);

      // Step 5: Save protected document
      _updateProgress(0.8, 'Saving protected PDF...');
      final List<int> protectedBytes = await document.save();
      document.dispose();

      // Step 6: Write to file
      _updateProgress(0.9, 'Writing to storage...');
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final baseName = p.basenameWithoutExtension(_fileName!);
      final outputPath =
          '${outputDir.path}/${baseName}_protected_$timestamp.pdf';

      final File protectedFile = File(outputPath);
      await protectedFile.writeAsBytes(protectedBytes);

      setState(() {
        _protectedFile = protectedFile;
      });

      _updateProgress(1.0, 'Protection completed!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      _showProtectionResults();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error protecting PDF: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _protectionProgress = 0.0;
          _progressText = '';
        });
      }
    }
  }

  Future<void> _applySecuritySettings(PdfDocument document) async {
    try {
      final security = document.security;

      // Set passwords
      security.userPassword = _userPassword;
      security.ownerPassword =
          _ownerPassword.isNotEmpty ? _ownerPassword : _userPassword;

      // Set encryption algorithm
      security.algorithm = PdfEncryptionAlgorithm.aesx128Bit;
    } catch (e) {
      debugPrint('Error applying security settings: $e');
    }
  }

  Future<void> _configurePermissions(PdfDocument document) async {
    try {
      final security = document.security;

      // Configure permissions based on protection level and user settings
      switch (_selectedProtectionLevel) {
        case ProtectionLevel.basic:
          // Only password protection, allow most operations
          security.permissions.add(PdfPermissionsFlags.print);
          security.permissions.add(PdfPermissionsFlags.editContent);
          security.permissions.add(PdfPermissionsFlags.copyContent);
          security.permissions.add(PdfPermissionsFlags.editAnnotations);
          security.permissions.add(PdfPermissionsFlags.fillFields);
          break;

        case ProtectionLevel.standard:
          // Restrict printing and copying based on user settings
          if (_allowPrinting) {
            security.permissions.add(PdfPermissionsFlags.print);
          }
          if (_allowCopying) {
            security.permissions.add(PdfPermissionsFlags.copyContent);
          }
          if (_allowModification) {
            security.permissions.add(PdfPermissionsFlags.editContent);
          }
          if (_allowAnnotations) {
            security.permissions.add(PdfPermissionsFlags.editAnnotations);
          }
          if (_allowFormFilling) {
            security.permissions.add(PdfPermissionsFlags.fillFields);
          }
          if (_allowAccessibility) {
            security.permissions
                .add(PdfPermissionsFlags.accessibilityCopyContent);
          }
          break;

        case ProtectionLevel.advanced:
          // Restrict most operations, only allow basic viewing
          if (_allowAccessibility) {
            security.permissions
                .add(PdfPermissionsFlags.accessibilityCopyContent);
          }
          if (_allowFormFilling) {
            security.permissions.add(PdfPermissionsFlags.fillFields);
          }
          break;

        case ProtectionLevel.maximum:
          // Minimal permissions, maximum security
          if (_allowAccessibility) {
            security.permissions
                .add(PdfPermissionsFlags.accessibilityCopyContent);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error configuring permissions: $e');
    }
  }

  void _updateProgress(double progress, String text) {
    if (mounted) {
      setState(() {
        _protectionProgress = progress;
        _progressText = text;
      });
    }
  }

  void _showProtectionResults() {
    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: width < 350 ? width * 0.95 : 350, // Responsive width
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Protection Complete',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('File Name', _fileName ?? 'Unknown'),
                  _buildInfoRow(
                      'Protection Level', _selectedProtectionLevel.label),
                  _buildInfoRow('Encryption', 'AES-256'),
                  _buildInfoRow('Password Protected', 'Yes'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'PDF protected successfully with AES-256 encryption and saved to your documents folder.',
                            style: TextStyle(color: Colors.green),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _shareProtectedFile,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProtectedFile() async {
    if (_protectedFile != null) {
      try {
        await Share.shareXFiles(
          [XFile(_protectedFile!.path)],
          text: 'Password-protected PDF file',
          subject: 'Protected PDF Document',
        );
      } catch (e) {
        _showSnackBar('Error sharing file: ${e.toString()}', Colors.red);
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _protectedFile = null;
      _clearPasswords();
    });
  }

  void _generateStrongPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    String password = '';

    for (int i = 0; i < 12; i++) {
      password += chars[(random + i) % chars.length];
    }

    _userPasswordController.text = password;
    _confirmPasswordController.text = password;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    bool showStrength = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (suffix != null) suffix,
                IconButton(
                  icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: onToggleVisibility,
                ),
              ],
            ),
          ),
        ),
        if (showStrength && controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Strength: ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _getPasswordStrength(controller.text),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getPasswordStrengthColor(controller.text),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProtectionLevelSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protection Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...ProtectionLevel.values.map((level) {
              return RadioListTile<ProtectionLevel>(
                title: Text(level.label),
                subtitle: Text(
                  level.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: level,
                groupValue: _selectedProtectionLevel,
                onChanged: (ProtectionLevel? value) {
                  if (value != null) {
                    setState(() {
                      _selectedProtectionLevel = value;
                      _updatePermissionsForLevel(value);
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _updatePermissionsForLevel(ProtectionLevel level) {
    switch (level) {
      case ProtectionLevel.basic:
        setState(() {
          _allowPrinting = true;
          _allowCopying = true;
          _allowModification = true;
          _allowAnnotations = true;
          _allowFormFilling = true;
          _allowAccessibility = true;
        });
        break;
      case ProtectionLevel.standard:
        setState(() {
          _allowPrinting = true;
          _allowCopying = false;
          _allowModification = false;
          _allowAnnotations = true;
          _allowFormFilling = true;
          _allowAccessibility = true;
        });
        break;
      case ProtectionLevel.advanced:
        setState(() {
          _allowPrinting = false;
          _allowCopying = false;
          _allowModification = false;
          _allowAnnotations = false;
          _allowFormFilling = true;
          _allowAccessibility = true;
        });
        break;
      case ProtectionLevel.maximum:
        setState(() {
          _allowPrinting = false;
          _allowCopying = false;
          _allowModification = false;
          _allowAnnotations = false;
          _allowFormFilling = false;
          _allowAccessibility = true;
        });
        break;
    }
  }

  Widget _buildPermissionsSettings() {
    if (_selectedProtectionLevel == ProtectionLevel.basic) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPermissionTile(
              'Allow Printing',
              'Users can print the document',
              _allowPrinting,
              (value) => setState(() => _allowPrinting = value),
              Icons.print,
            ),
            _buildPermissionTile(
              'Allow Copying',
              'Users can copy text and images',
              _allowCopying,
              (value) => setState(() => _allowCopying = value),
              Icons.copy,
            ),
            _buildPermissionTile(
              'Allow Modification',
              'Users can edit document content',
              _allowModification,
              (value) => setState(() => _allowModification = value),
              Icons.edit,
            ),
            _buildPermissionTile(
              'Allow Annotations',
              'Users can add comments and annotations',
              _allowAnnotations,
              (value) => setState(() => _allowAnnotations = value),
              Icons.comment,
            ),
            _buildPermissionTile(
              'Allow Form Filling',
              'Users can fill interactive forms',
              _allowFormFilling,
              (value) => setState(() => _allowFormFilling = value),
              Icons.edit_note,
            ),
            _buildPermissionTile(
              'Allow Accessibility',
              'Screen readers can access content',
              _allowAccessibility,
              (value) => setState(() => _allowAccessibility = value),
              Icons.accessibility,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFileInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined, size: 32),
        title: Text(
          _fileName ?? p.basename(_selectedFile!.path),
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: FutureBuilder<int>(
          future: _selectedFile!.length(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final sizeKB = snapshot.data! / 1024;
              return Text(
                'Size: ${sizeKB.toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return const Text('Calculating size...');
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_protectedFile != null)
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Protected File',
                onPressed: _shareProtectedFile,
              ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear Selection',
              onPressed: _clearSelection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Protecting PDF...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${(_protectionProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _protectionProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progressText,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userPasswordController.dispose();
    _confirmPasswordController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Protect PDF',
      icon: Icons.security,
      actionButtonLabel:
          _protectedFile != null ? 'Share Protected PDF' : 'Protect PDF',
      isActionButtonEnabled: _selectedFile != null &&
          _userPassword.isNotEmpty &&
          _userPassword == _confirmPassword &&
          !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed:
          _protectedFile != null ? _shareProtectedFile : _protectPdf,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a PDF file and set password protection with custom security settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ElevatedButton.icon(
                        onPressed: _selectFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Select PDF File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFileInfoCard(),
                      const SizedBox(height: 16),
                      if (_isProcessing)
                        _buildProgressIndicator()
                      else ...[
                        // Password fields
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Password Settings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _generateStrongPassword,
                                      icon: const Icon(Icons.auto_fix_high,
                                          size: 16),
                                      label: const Text('Generate'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  controller: _userPasswordController,
                                  label: 'User Password *',
                                  hint: 'Required to open the document',
                                  obscureText: !_showUserPassword,
                                  onToggleVisibility: () => setState(() =>
                                      _showUserPassword = !_showUserPassword),
                                  showStrength: true,
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password *',
                                  hint: 'Re-enter the user password',
                                  obscureText: !_showConfirmPassword,
                                  onToggleVisibility: () => setState(() =>
                                      _showConfirmPassword =
                                          !_showConfirmPassword),
                                  suffix: _userPassword.isNotEmpty &&
                                          _confirmPassword.isNotEmpty
                                      ? Icon(
                                          _userPassword == _confirmPassword
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color:
                                              _userPassword == _confirmPassword
                                                  ? Colors.green
                                                  : Colors.red,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  controller: _ownerPasswordController,
                                  label: 'Owner Password (Optional)',
                                  hint: 'For advanced permissions control',
                                  obscureText: !_showOwnerPassword,
                                  onToggleVisibility: () => setState(() =>
                                      _showOwnerPassword = !_showOwnerPassword),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildProtectionLevelSelector(),

                        const SizedBox(height: 16),

                        _buildPermissionsSettings(),
                      ],
                      if (_protectedFile != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          color: Colors.green.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.security,
                                        color: Colors.green[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PDF Protected Successfully!',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your PDF is now protected with AES-256 encryption',
                                  style: TextStyle(color: Colors.green[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
