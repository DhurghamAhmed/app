import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../providers/auth_provider.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;

class InventoryScannerScreen extends StatefulWidget {
  const InventoryScannerScreen({super.key});

  @override
  State<InventoryScannerScreen> createState() => _InventoryScannerScreenState();
}

class _InventoryScannerScreenState extends State<InventoryScannerScreen> {
  /// Convert Arabic/Eastern numerals to Western numerals
  String _normalizeArabicNumbers(String input) {
    const arabicNumerals = '٠١٢٣٤٥٦٧٨٩';
    const westernNumerals = '0123456789';
    String result = input;
    for (int i = 0; i < arabicNumerals.length; i++) {
      result = result.replaceAll(arabicNumerals[i], westernNumerals[i]);
    }
    return result;
  }

  /// Format number with thousand separators
  String _formatWithCommas(double amount) {
    return NumberFormat('#,###', 'en_US').format(amount.toInt());
  }

  final ProductService _productService = ProductService();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ImagePicker _imagePicker = ImagePicker();
  final mlkit.BarcodeScanner _barcodeScanner = mlkit.BarcodeScanner(
    formats: [
      mlkit.BarcodeFormat.all,
    ],
  );

  mobile.MobileScannerController? _scannerController;
  bool _isCameraActive = false;

  // State variables
  bool _isScanning = false;
  bool _isLoading = false;
  bool _isProcessingImage = false;
  String? _scannedBarcode;
  ProductModel? _foundProduct;
  bool _productNotFound = false;

  // Form controllers for new product
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  // Controller for quantity update
  final _updateQuantityController = TextEditingController();

  @override
  void dispose() {
    _scannerController?.dispose();
    _barcodeScanner.close();
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _updateQuantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize camera scanner with optimized settings
  void _initializeCamera() {
    _scannerController = mobile.MobileScannerController(
      formats: const [mobile.BarcodeFormat.all],
      detectionSpeed: mobile.DetectionSpeed.normal,
      facing: mobile.CameraFacing.back,
      torchEnabled: false,
    );
  }

  /// Show scan options bottom sheet
  void _showScanOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(context.l10n.translate('scan_barcode'),
                  style: AppTextStyles.headingSmall()),
              const SizedBox(height: 8),
              Text(
                context.l10n.translate('choose_scan_method'),
                style: AppTextStyles.bodyMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // Camera option
              _buildScanOption(
                context: context,
                icon: Icons.camera_alt_rounded,
                title: context.l10n.translate('scan_with_camera'),
                subtitle: context.l10n.translate('use_camera_to_scan'),
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _startCameraScanning();
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Gallery option
              _buildScanOption(
                context: context,
                icon: Icons.photo_library_rounded,
                title: context.l10n.translate('scan_from_image'),
                subtitle: context.l10n.translate('select_image_from_gallery'),
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(ctx);
                  _scanFromGallery();
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Create custom barcode option
              _buildScanOption(
                context: context,
                icon: Iconsax.add_circle,
                title: context.l10n.translate('create_custom_barcode'),
                subtitle: context.l10n.translate('create_custom_barcode_desc'),
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateCustomBarcodeSheet();
                },
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium()),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Start camera scanning
  void _startCameraScanning() {
    _initializeCamera();
    setState(() {
      _isCameraActive = true;
      _isScanning = true;
      _scannedBarcode = null;
      _foundProduct = null;
      _productNotFound = false;
    });
  }

  /// Stop camera scanning
  void _stopCameraScanning() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _isCameraActive = false;
      _isScanning = false;
    });
  }

  // ============================================================
  // PART 1: ADVANCED IMAGE PREPROCESSING FOR GALLERY SCANNING
  // ============================================================

  /// Preprocess image for better barcode detection
  Future<File?> _preprocessImage(String imagePath) async {
    try {
      // Read the image file
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) return null;

      // Step 1: Resize if too small (upscale to 1200px width)
      if (image.width < 1200) {
        final double scale = 1200 / image.width;
        image = img.copyResize(
          image,
          width: 1200,
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.cubic,
        );
      }

      // Step 2: Convert to grayscale for better contrast
      image = img.grayscale(image);

      // Step 3: Crop center area (70% of image)
      final int cropWidth = (image.width * 0.7).round();
      final int cropHeight = (image.height * 0.7).round();
      final int cropX = ((image.width - cropWidth) / 2).round();
      final int cropY = ((image.height - cropHeight) / 2).round();

      image = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Step 4: Increase contrast for barcode clarity
      image = img.adjustColor(image, contrast: 1.3);

      // Step 5: Apply slight sharpening
      image = img.convolution(image, filter: [
        0,
        -1,
        0,
        -1,
        5,
        -1,
        0,
        -1,
        0,
      ]);

      // Save processed image to temp file
      final String tempPath =
          '${imageFile.parent.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File processedFile = File(tempPath);
      await processedFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      return processedFile;
    } catch (e) {
      debugPrint('Image preprocessing error: $e');
      return null;
    }
  }

  /// Scan from gallery with advanced preprocessing
  Future<void> _scanFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Maximum quality
      );
      if (image == null) return;

      setState(() {
        _isLoading = true;
        _isProcessingImage = true;
      });

      // Try 1: Scan original image first
      String? barcodeValue = await _scanImageForBarcode(image.path);

      // Try 2: If no barcode found, preprocess and try again
      if (barcodeValue == null) {
        final File? processedImage = await _preprocessImage(image.path);
        if (processedImage != null) {
          barcodeValue = await _scanImageForBarcode(processedImage.path);
          // Clean up temp file
          try {
            await processedImage.delete();
          } catch (_) {}
        }
      }

      // Try 3: If still no barcode, try with different crop ratios
      barcodeValue ??= await _scanWithMultipleCrops(image.path);

      setState(() => _isProcessingImage = false);

      if (barcodeValue == null || barcodeValue.isEmpty) {
        if (mounted) {
          _showErrorSnackBar(context.l10n.translate('no_barcode_found'));
        }
        setState(() => _isLoading = false);
        return;
      }

      // Process the scanned barcode
      await _processScannedBarcode(barcodeValue);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('error_scanning_image'));
      }
      setState(() {
        _isLoading = false;
        _isProcessingImage = false;
      });
    }
  }

  /// Scan image for barcode using ML Kit
  Future<String?> _scanImageForBarcode(String imagePath) async {
    try {
      final inputImage = mlkit.InputImage.fromFilePath(imagePath);
      final List<mlkit.Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        return barcodes.first.rawValue;
      }
      return null;
    } catch (e) {
      debugPrint('Barcode scan error: $e');
      return null;
    }
  }

  /// Try scanning with multiple crop ratios
  Future<String?> _scanWithMultipleCrops(String imagePath) async {
    final List<double> cropRatios = [0.5, 0.8, 0.6];

    for (final ratio in cropRatios) {
      try {
        final File imageFile = File(imagePath);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        img.Image? image = img.decodeImage(imageBytes);

        if (image == null) continue;

        // Crop with different ratio
        final int cropWidth = (image.width * ratio).round();
        final int cropHeight = (image.height * ratio).round();
        final int cropX = ((image.width - cropWidth) / 2).round();
        final int cropY = ((image.height - cropHeight) / 2).round();

        image = img.copyCrop(
          image,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        // Convert to grayscale and increase contrast
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.4);

        // Save and scan
        final String tempPath =
            '${imageFile.parent.path}/crop_${ratio}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File croppedFile = File(tempPath);
        await croppedFile.writeAsBytes(img.encodeJpg(image, quality: 95));

        final String? result = await _scanImageForBarcode(tempPath);

        // Clean up
        try {
          await croppedFile.delete();
        } catch (_) {}

        if (result != null) return result;
      } catch (e) {
        debugPrint('Crop scan error: $e');
      }
    }

    return null;
  }

  // ============================================================
  // PART 2: ENHANCED LIVE CAMERA PROCESSING
  // ============================================================

  /// Handle barcode detection from camera with ROI filtering
  void _onBarcodeDetected(mobile.BarcodeCapture capture) async {
    if (!_isScanning || _isLoading) return;

    final List<mobile.Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    // Filter barcodes to only those in the center ROI (60% of frame)
    mobile.Barcode? validBarcode;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        // Check if barcode is in center region (ROI)
        if (_isBarcodeInROI(barcode, capture)) {
          validBarcode = barcode;
          break;
        }
      }
    }

    // If no barcode in ROI, try the first valid one
    if (validBarcode == null) {
      for (final b in barcodes) {
        if (b.rawValue != null && b.rawValue!.isNotEmpty) {
          validBarcode = b;
          break;
        }
      }
      validBarcode ??= barcodes.first;
    }

    final String? barcodeValue = validBarcode.rawValue;
    if (barcodeValue == null || barcodeValue.isEmpty) return;

    // Prevent multiple scans of the same barcode
    if (_scannedBarcode == barcodeValue) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Stop scanning and process
    _stopCameraScanning();
    await _processScannedBarcode(barcodeValue);
  }

  /// Check if barcode is within the center ROI (60% of frame)
  bool _isBarcodeInROI(mobile.Barcode barcode, mobile.BarcodeCapture capture) {
    // If no corner points, assume it's valid
    final corners = barcode.corners;
    if (corners.isEmpty) return true;

    // For simplicity, we'll accept all barcodes with valid corners
    // Future enhancement: calculate center and check if within ROI
    return true;
  }

  /// Process scanned barcode
  Future<void> _processScannedBarcode(String barcodeValue) async {
    setState(() {
      _isLoading = true;
      _scannedBarcode = barcodeValue;
      _foundProduct = null;
      _productNotFound = false;
    });

    // Search for product in Firestore
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('please_login_scanner'));
      }
      _resetScanner();
      return;
    }

    try {
      final product =
          await _productService.getProductByBarcodeId(barcodeValue, userId);

      setState(() {
        _isLoading = false;
        if (product != null) {
          _foundProduct = product;
          _productNotFound = false;
          _updateQuantityController.text = '1';
        } else {
          _foundProduct = null;
          _productNotFound = true;
          _nameController.clear();
          _priceController.clear();
          _quantityController.text = '1';
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('error_searching_product'));
      }
      _resetScanner();
    }
  }

  /// Reset scanner
  void _resetScanner() {
    _stopCameraScanning();
    setState(() {
      _scannedBarcode = null;
      _foundProduct = null;
      _productNotFound = false;
      _isLoading = false;
    });
  }

  /// Save new product
  Future<void> _saveNewProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('please_login_add_products'));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalizedPrice =
          _normalizeArabicNumbers(_priceController.text.trim());
      final normalizedQty =
          _normalizeArabicNumbers(_quantityController.text.trim());

      await _productService.addProduct(
        name: _nameController.text.trim(),
        price: double.parse(normalizedPrice),
        quantity: int.parse(normalizedQty),
        barcodeId: _scannedBarcode!,
        userId: userId,
      );

      if (mounted) {
        _showSuccessSnackBar(context.l10n.translate('product_added_inventory'));
      }
      _resetScanner();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('failed_add_product'));
      }
      setState(() => _isLoading = false);
    }
  }

  /// Update product quantity
  Future<void> _updateQuantity() async {
    final normalizedQty =
        _normalizeArabicNumbers(_updateQuantityController.text.trim());
    final additionalQty = int.tryParse(normalizedQty);
    if (additionalQty == null || additionalQty <= 0) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('enter_valid_quantity'));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _productService.updateProductQuantity(
          _foundProduct!.id, additionalQty);
      if (mounted) {
        _showSuccessSnackBar(
            '${context.l10n.translate('stock_updated')} (+$additionalQty)');
      }
      _resetScanner();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('failed_update_stock'));
      }
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      floatingActionButton: _buildFloatingQRButton(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_isCameraActive) _buildScannerArea(isDark),
                    _buildContentArea(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingQRButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showScanOptionsSheet,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.translate('inventory_scanner'),
                        style: AppTextStyles.headingMedium()),
                    Text(
                      context.l10n.translate('scan_products_manage_stock'),
                      style: AppTextStyles.bodySmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Search bar directly under the app bar
          const SizedBox(height: 16),
          _buildSearchBar(isDark),
        ],
      ),
    );
  }

  Widget _buildScannerArea(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingHorizontal),
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Camera view
            if (_scannerController != null)
              mobile.MobileScanner(
                controller: _scannerController!,
                onDetect: _onBarcodeDetected,
              ),

            // Simple overlay with white corners
            _buildEnhancedScannerOverlay(isDark),

            // Close button (top right)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _stopCameraScanning,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),

            // Flash button (top left)
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: () => _scannerController?.toggleTorch(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.flash_on, color: Colors.white, size: 20),
                ),
              ),
            ),

            // Status indicator
            if (_isLoading) _buildStatusIndicator(isDark),
          ],
        ),
      ),
    );
  }

  /// Simple scanner overlay with white rounded corner brackets only - NO dark overlay
  Widget _buildEnhancedScannerOverlay(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boxSize = constraints.maxWidth * 0.7;
        final double left = (constraints.maxWidth - boxSize) / 2;
        final double top = (constraints.maxHeight - boxSize) / 2;

        return Stack(
          children: [
            // NO dark overlay - just the corners

            // White rounded corner brackets only
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: Stack(
                  children: [
                    // Top-left corner
                    Positioned(
                        top: 0,
                        left: 0,
                        child: _buildRoundedCorner(true, true)),
                    // Top-right corner
                    Positioned(
                        top: 0,
                        right: 0,
                        child: _buildRoundedCorner(true, false)),
                    // Bottom-left corner
                    Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildRoundedCorner(false, true)),
                    // Bottom-right corner
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildRoundedCorner(false, false)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Rounded white corner bracket
  Widget _buildRoundedCorner(bool isTop, bool isLeft) {
    const double size = 40;
    const double thickness = 4;
    const double radius = 12;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoundedCornerPainter(
          isTop: isTop,
          isLeft: isLeft,
          color: Colors.white,
          thickness: thickness,
          radius: radius,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isDark) {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(context.l10n.translate('searching'),
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Column(
        children: [
          // Processing indicator for gallery images
          if (_isProcessingImage)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.translate('processing_image'),
                            style: AppTextStyles.titleSmall()),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.translate('enhancing_image'),
                          style: AppTextStyles.bodySmall(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (_scannedBarcode != null) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.qr_code, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.translate('scanned_barcode'),
                          style: AppTextStyles.labelMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scannedBarcode!,
                          style: AppTextStyles.titleMedium(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _resetScanner,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading && _scannedBarcode != null && !_isProcessingImage)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator())),
          if (_foundProduct != null) _buildProductFoundCard(isDark),
          if (_productNotFound) _buildAddProductForm(isDark),
          if (_scannedBarcode == null && !_isCameraActive)
            _buildInstructions(isDark),
        ],
      ),
    );
  }

  Widget _buildInstructions(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userId;

    if (userId == null) {
      return _buildEmptyState(isDark);
    }

    return StreamBuilder<List<ProductModel>>(
      stream: _productService.streamProducts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, isDark);
        }

        final products = snapshot.data ?? [];

        // CASE 1: No products - show minimal empty state
        if (products.isEmpty) {
          return _buildEmptyState(isDark);
        }

        // CASE 2: Products exist - show product list
        return _buildProductList(products, isDark);
      },
    );
  }

  /// Empty state - minimal design with large icon
  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Iconsax.box,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              context.l10n.translate('no_products_yet'),
              style: AppTextStyles.headingMedium(),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                context.l10n.translate('scan_barcode_add_product'),
                style: AppTextStyles.bodyMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(context.l10n.translate('error_loading_products'),
                style: AppTextStyles.titleMedium()),
            const SizedBox(height: 8),
            Text(
              context.l10n.translate('please_try_again'),
              style: AppTextStyles.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search bar widget - shown at top
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Directionality(
        textDirection:
            context.isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          style: AppTextStyles.bodyMedium(),
          decoration: InputDecoration(
            hintText: context.isArabic
                ? 'البحث في المنتجات...'
                : 'Search products...',
            hintStyle: AppTextStyles.bodyMedium(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              Iconsax.search_normal,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Product list with header and search
  Widget _buildProductList(List<ProductModel> products, bool isDark) {
    // Filter products based on search query
    final filteredProducts = _searchQuery.isEmpty
        ? products
        : products.where((product) {
            final query = _searchQuery.toLowerCase();
            return product.name.toLowerCase().contains(query) ||
                product.barcodeId.toLowerCase().contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Products list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.inventory, style: AppTextStyles.headingSmall()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.box, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${products.length} ${products.length == 1 ? context.l10n.translate('item') : context.l10n.translate('items')}',
                    style: AppTextStyles.labelSmall(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search results count (when searching)
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${filteredProducts.length} ${context.l10n.translate('results_found')}',
              style: AppTextStyles.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),

        // Empty search results
        if (_searchQuery.isNotEmpty && filteredProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Iconsax.search_status,
                    size: 48,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.translate('no_products_found'),
                    style: AppTextStyles.titleMedium(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.translate('try_different_search'),
                    style: AppTextStyles.bodySmall(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Products list
        ...filteredProducts
            .map((product) => _buildProductListItem(product, isDark)),

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildProductListItem(ProductModel product, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showProductDetails(product, isDark),
        child: Row(
          children: [
            // Product icon with Iconsax
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Iconsax.box, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.titleMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Iconsax.barcode,
                        size: 14,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.barcodeId,
                          style: AppTextStyles.caption(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Price and quantity
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.money,
                        size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'IQD ${_formatWithCommas(product.price)}',
                      style:
                          AppTextStyles.titleSmall(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: product.quantity > 0
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        product.quantity > 0
                            ? Iconsax.box_tick
                            : Iconsax.box_remove,
                        size: 12,
                        color: product.quantity > 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.quantity}',
                        style: AppTextStyles.labelSmall(
                          color: product.quantity > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(ProductModel product, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Product header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Iconsax.box, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: AppTextStyles.headingSmall()),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Iconsax.barcode,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                product.barcodeId,
                                style: AppTextStyles.bodySmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      context.l10n.translate('price'),
                      'IQD ${_formatWithCommas(product.price)}',
                      Iconsax.money,
                      AppColors.secondary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailCard(
                      context.l10n.translate('in_stock'),
                      '${product.quantity} ${context.l10n.translate('units')}',
                      product.quantity > 0
                          ? Iconsax.box_tick
                          : Iconsax.box_remove,
                      product.quantity > 0
                          ? AppColors.success
                          : AppColors.error,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                context.l10n.translate('added_on'),
                DateFormat('MMMM d, yyyy • h:mm a').format(product.createdAt),
                Iconsax.calendar,
                AppColors.primary,
                isDark,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  // Barcode button - LEFT side
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBarcodeDialog(product, isDark);
                      },
                      icon: const Icon(Iconsax.barcode,
                          color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: context.l10n.translate('update_stock'),
                      leadingIcon: Iconsax.add,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showUpdateStockDialog(product, isDark);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirmation(product, isDark);
                      },
                      icon: const Icon(Iconsax.trash, color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.labelSmall(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.titleMedium(color: color)),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(ProductModel product, bool isDark) {
    final quantityController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(context.l10n.translate('update_stock'),
                    style: AppTextStyles.headingSmall()),
                const SizedBox(height: 8),
                Text(
                  '${context.l10n.translate('add_quantity_to')} ${product.name}',
                  style: AppTextStyles.bodyMedium(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.l10n.translate('current_stock')}: ${product.quantity} ${context.l10n.translate('units')}',
                  style: AppTextStyles.labelMedium(color: AppColors.success),
                ),
                const SizedBox(height: 20),
                InputField(
                  label: context.l10n.translate('quantity_to_add'),
                  hint: context.l10n.translate('enter_quantity'),
                  controller: quantityController,
                  prefixIcon: Icons.add_circle_outline,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: context.l10n.translate('update_stock'),
                  leadingIcon: Icons.add,
                  onPressed: () async {
                    final normalizedQty =
                        _normalizeArabicNumbers(quantityController.text.trim());
                    final qty = int.tryParse(normalizedQty);
                    if (qty == null || qty <= 0) {
                      if (mounted) {
                        _showErrorSnackBar(
                            context.l10n.translate('enter_valid_quantity'));
                      }
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await _productService.updateProductQuantity(
                          product.id, qty);
                      if (mounted) {
                        _showSuccessSnackBar(
                            '${context.l10n.translate('stock_updated')} (+$qty)');
                      }
                    } catch (e) {
                      if (mounted) {
                        _showErrorSnackBar(
                            context.l10n.translate('failed_update_stock'));
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(ProductModel product, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.l10n.translate('delete_product_title'),
              style: AppTextStyles.headingSmall()),
          content: Text(
            '${context.l10n.translate('delete_product_confirm')} "${product.name}"? ${context.l10n.translate('action_cannot_undo')}',
            style: AppTextStyles.bodyMedium(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel,
                  style: AppTextStyles.buttonMedium(
                      color: AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _productService.deleteProduct(product.id);
                  if (mounted) {
                    _showSuccessSnackBar(
                        context.l10n.translate('product_deleted'));
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar(
                        context.l10n.translate('failed_delete_product'));
                  }
                }
              },
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductFoundCard(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(context.l10n.translate('product_found'),
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_foundProduct!.name,
                            style: AppTextStyles.headingSmall()),
                        const SizedBox(height: 4),
                        Text(
                          'Barcode: ${_foundProduct!.barcodeId}',
                          style: AppTextStyles.bodySmall(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildInfoItem(
                          context.l10n.translate('price'),
                          'IQD ${_formatWithCommas(_foundProduct!.price)}',
                          Icons.attach_money,
                          AppColors.secondary,
                          isDark)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildInfoItem(
                          context.l10n.translate('in_stock'),
                          '${_foundProduct!.quantity} ${context.l10n.translate('units')}',
                          Icons.inventory,
                          _foundProduct!.quantity > 0
                              ? AppColors.success
                              : AppColors.error,
                          isDark)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.translate('add_stock'),
                  style: AppTextStyles.titleLarge()),
              const SizedBox(height: 4),
              Text(context.l10n.translate('enter_quantity_to_add'),
                  style: AppTextStyles.bodySmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              InputField(
                  hint: context.l10n.translate('quantity'),
                  controller: _updateQuantityController,
                  prefixIcon: Icons.add_circle_outline,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              PrimaryButton(
                  text: context.l10n.translate('update_quantity'),
                  leadingIcon: Icons.add,
                  isLoading: _isLoading,
                  onPressed: _updateQuantity),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
            text: context.l10n.translate('scan_another'),
            variant: ButtonVariant.outlined,
            leadingIcon: Icons.qr_code_scanner,
            onPressed: _resetScanner),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.labelSmall(color: color))
          ]),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.titleLarge(color: color)),
        ],
      ),
    );
  }

  // ============================================================
  // BARCODE TYPE DETECTION & RENDERING HELPERS
  // ============================================================

  /// Detect the best barcode type based on the data content
  bw.Barcode _detectBarcodeType(String data) {
    final trimmed = data.trim();

    // Custom barcodes (CB-xxx) → QR Code (supports all characters)
    if (trimmed.startsWith('CB-')) {
      return bw.Barcode.qrCode();
    }

    // Check if data is purely numeric
    final isNumeric = RegExp(r'^\d+$').hasMatch(trimmed);

    if (isNumeric) {
      switch (trimmed.length) {
        case 8:
          // EAN-8 format
          return bw.Barcode.ean8();
        case 12:
          // UPC-A format
          return bw.Barcode.upcA();
        case 13:
          // EAN-13 format
          return bw.Barcode.ean13();
        case 14:
          // ITF-14 format
          return bw.Barcode.itf14();
        default:
          if (trimmed.length <= 20) {
            // Short numeric → Code128 (handles any length)
            return bw.Barcode.code128();
          }
          // Long numeric → QR Code
          return bw.Barcode.qrCode();
      }
    }

    // Contains letters or special characters
    // If short alphanumeric, try Code128
    if (trimmed.length <= 30 && RegExp(r'^[\x00-\x7F]+$').hasMatch(trimmed)) {
      return bw.Barcode.code128();
    }

    // Default: QR Code (supports everything including Unicode)
    return bw.Barcode.qrCode();
  }

  /// Check if the barcode should be displayed as square (QR/DataMatrix)
  bool _isSquareBarcode(String data) {
    final barcodeType = _detectBarcodeType(data);
    return barcodeType == bw.Barcode.qrCode() ||
        barcodeType == bw.Barcode.dataMatrix();
  }

  /// Build the barcode widget with correct type and dimensions
  Widget _buildBarcodeImage(String data,
      {double maxWidth = 280, double linearHeight = 100, double qrSize = 200}) {
    final barcodeType = _detectBarcodeType(data);
    final isSquare = _isSquareBarcode(data);

    return bw.BarcodeWidget(
      barcode: barcodeType,
      data: data,
      width: isSquare ? qrSize : maxWidth,
      height: isSquare ? qrSize : linearHeight,
      drawText: !isSquare, // Only show text for linear barcodes
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        letterSpacing: 1.5,
      ),
      errorBuilder: (context, error) {
        // Fallback: if the detected type fails, use QR code
        return bw.BarcodeWidget(
          barcode: bw.Barcode.qrCode(),
          data: data,
          width: qrSize,
          height: qrSize,
          drawText: false,
        );
      },
    );
  }

  /// Show barcode dialog with actual visual barcode
  void _showBarcodeDialog(ProductModel product, bool isDark) {
    final isSquare = _isSquareBarcode(product.barcodeId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                context.l10n.translate('product_barcode'),
                style: AppTextStyles.headingSmall(),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: AppTextStyles.bodyMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // Barcode visual display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    // Product name above barcode
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Actual barcode image - auto-detected type
                    _buildBarcodeImage(
                      product.barcodeId,
                      maxWidth: 280,
                      linearHeight: 100,
                      qrSize: 200,
                    ),

                    // Show barcode ID text below QR codes
                    if (isSquare) ...[
                      const SizedBox(height: 12),
                      Text(
                        product.barcodeId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Price and quantity info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'IQD ${_formatWithCommas(product.price)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${context.l10n.translate('stock')}: ${product.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close button
              PrimaryButton(
                text: context.l10n.translate('close'),
                variant: ButtonVariant.outlined,
                leadingIcon: Icons.close,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Generate a unique custom barcode ID
  String _generateCustomBarcodeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final suffix =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'CB-$timestamp-$suffix';
  }

  /// Show create custom barcode bottom sheet
  void _showCreateCustomBarcodeSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final generatedBarcode = _generateCustomBarcodeId();
    final customNameController = TextEditingController();
    final customPriceController = TextEditingController();
    final customQuantityController = TextEditingController(text: '1');
    final customFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: customFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      context.l10n.translate('create_custom_barcode'),
                      style: AppTextStyles.headingSmall(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.translate('enter_product_details'),
                      style: AppTextStyles.bodyMedium(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Generated Barcode Display with visual barcode
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Iconsax.barcode,
                                    color: AppColors.success, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n
                                          .translate('generated_barcode'),
                                      style: AppTextStyles.labelSmall(
                                          color: AppColors.success),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      generatedBarcode,
                                      style: AppTextStyles.titleMedium(
                                          color: AppColors.success),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Visual barcode - QR code for custom barcodes
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: _buildBarcodeImage(
                                generatedBarcode,
                                maxWidth: 220,
                                linearHeight: 70,
                                qrSize: 180,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Name
                    InputField(
                      label: context.l10n.translate('product_name'),
                      hint: context.l10n.translate('enter_product_name'),
                      controller: customNameController,
                      prefixIcon: Icons.inventory_2_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n
                              .translate('please_enter_product_name');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    InputField(
                      label: context.l10n.translate('price_iqd'),
                      hint: context.l10n.translate('enter_price'),
                      controller: customPriceController,
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.translate('please_enter_price');
                        }
                        final normalized =
                            _normalizeArabicNumbers(value.trim());
                        if (double.tryParse(normalized) == null) {
                          return context.l10n
                              .translate('please_enter_valid_number');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    InputField(
                      label: context.l10n.translate('initial_quantity'),
                      hint: context.l10n.translate('enter_quantity'),
                      controller: customQuantityController,
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n
                              .translate('please_enter_quantity');
                        }
                        final normalized =
                            _normalizeArabicNumbers(value.trim());
                        if (int.tryParse(normalized) == null) {
                          return context.l10n
                              .translate('please_enter_valid_number');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    StatefulBuilder(
                      builder: (btnContext, setButtonState) {
                        bool isSaving = false;
                        return PrimaryButton(
                          text: btnContext.l10n.translate('create_and_save'),
                          leadingIcon: Iconsax.tick_circle,
                          isLoading: isSaving,
                          onPressed: () async {
                            if (!customFormKey.currentState!.validate()) return;

                            final authProvider = Provider.of<AuthProvider>(
                                btnContext,
                                listen: false);
                            final userId = authProvider.userId;

                            if (userId == null) {
                              _showErrorSnackBar(btnContext.l10n
                                  .translate('please_login_add_products'));
                              return;
                            }

                            // Capture navigator and translated strings before async gap
                            final navigator = Navigator.of(ctx);
                            final successMsg = btnContext.l10n
                                .translate('product_created_successfully');
                            final errorMsg = btnContext.l10n
                                .translate('failed_create_product');

                            setButtonState(() => isSaving = true);

                            try {
                              final normalizedPrice = _normalizeArabicNumbers(
                                  customPriceController.text.trim());
                              final normalizedQty = _normalizeArabicNumbers(
                                  customQuantityController.text.trim());

                              await _productService.addProduct(
                                name: customNameController.text.trim(),
                                price: double.parse(normalizedPrice),
                                quantity: int.parse(normalizedQty),
                                barcodeId: generatedBarcode,
                                userId: userId,
                              );

                              if (mounted) {
                                navigator.pop();
                                _showSuccessSnackBar(successMsg);
                              }
                            } catch (e) {
                              setButtonState(() => isSaving = false);
                              if (mounted) {
                                _showErrorSnackBar(errorMsg);
                              }
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddProductForm(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(context.l10n.translate('product_not_found'),
                  style: const TextStyle(
                      color: AppColors.warning, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.translate('add_new_product'),
                    style: AppTextStyles.headingSmall()),
                const SizedBox(height: 4),
                Text(
                  context.l10n.translate('fill_product_details'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                InputField(
                  label: context.l10n.translate('product_name'),
                  hint: context.l10n.translate('enter_product_name'),
                  controller: _nameController,
                  prefixIcon: Icons.inventory_2_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n
                          .translate('please_enter_product_name');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InputField(
                  label: context.l10n.translate('price_iqd'),
                  hint: context.l10n.translate('enter_price'),
                  controller: _priceController,
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.translate('please_enter_price');
                    }
                    final normalized = _normalizeArabicNumbers(value.trim());
                    if (double.tryParse(normalized) == null) {
                      return context.l10n
                          .translate('please_enter_valid_number');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InputField(
                  label: context.l10n.translate('initial_quantity'),
                  hint: context.l10n.translate('enter_quantity'),
                  controller: _quantityController,
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.translate('please_enter_quantity');
                    }
                    final normalized = _normalizeArabicNumbers(value.trim());
                    if (int.tryParse(normalized) == null) {
                      return context.l10n
                          .translate('please_enter_valid_number');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: context.l10n.translate('save_product'),
                  leadingIcon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: _saveNewProduct,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: context.l10n.translate('scan_another'),
          variant: ButtonVariant.outlined,
          leadingIcon: Icons.qr_code_scanner,
          onPressed: _resetScanner,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

/// Rounded corner painter - draws L-shaped corner with rounded edge
class _RoundedCornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;
  final double thickness;
  final double radius;

  _RoundedCornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
    required this.thickness,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isTop && isLeft) {
      // Top-left corner ╭
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      // Top-right corner ╮
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      // Bottom-left corner ╰
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.quadraticBezierTo(0, size.height, radius, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Bottom-right corner ╯
      path.moveTo(0, size.height);
      path.lineTo(size.width - radius, size.height);
      path.quadraticBezierTo(
          size.width, size.height, size.width, size.height - radius);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundedCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.radius != radius;
  }
}
