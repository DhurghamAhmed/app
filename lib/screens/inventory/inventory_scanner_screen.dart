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

class InventoryScannerScreen extends StatefulWidget {
  const InventoryScannerScreen({super.key});

  @override
  State<InventoryScannerScreen> createState() => _InventoryScannerScreenState();
}

class _InventoryScannerScreenState extends State<InventoryScannerScreen> {
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
      await _productService.addProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
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
    final additionalQty = int.tryParse(_updateQuantityController.text.trim());
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
              if (_isCameraActive) ...[
                GestureDetector(
                  onTap: () => _scannerController?.toggleTorch(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
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
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: _isScanning
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius - 2),
        child: Stack(
          children: [
            // Camera view
            if (_scannerController != null)
              mobile.MobileScanner(
                controller: _scannerController!,
                onDetect: _onBarcodeDetected,
              ),

            // Enhanced overlay with dark mask around ROI
            _buildEnhancedScannerOverlay(isDark),

            // Close button
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

            // Status indicator
            if (_isLoading) _buildStatusIndicator(isDark),

            // Scanning hint
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.center_focus_strong,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.translate('center_barcode_frame'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced scanner overlay with dark mask around ROI
  Widget _buildEnhancedScannerOverlay(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boxSize = constraints.maxWidth * 0.65;
        final double left = (constraints.maxWidth - boxSize) / 2;
        final double top = (constraints.maxHeight - boxSize) / 2;

        return Stack(
          children: [
            // Dark overlay with cutout
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerOverlayPainter(
                boxSize: boxSize,
                left: left,
                top: top,
                borderColor:
                    _isScanning ? AppColors.primary : AppColors.success,
              ),
            ),

            // Scanning box border and corners
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? AppColors.primary : AppColors.success,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                        top: 0, left: 0, child: _buildCorner(true, true)),
                    Positioned(
                        top: 0, right: 0, child: _buildCorner(true, false)),
                    Positioned(
                        bottom: 0, left: 0, child: _buildCorner(false, true)),
                    Positioned(
                        bottom: 0, right: 0, child: _buildCorner(false, false)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isScanning
                                ? Icons.qr_code_scanner
                                : Icons.check_circle,
                            color:
                                _isScanning ? Colors.white : AppColors.success,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isScanning
                                ? context.l10n.translate('align_barcode_here')
                                : context.l10n.translate('scanned'),
                            style:
                                AppTextStyles.labelMedium(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    final color = _isScanning ? AppColors.primary : AppColors.success;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
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
                    final qty = int.tryParse(quantityController.text.trim());
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
                    if (double.tryParse(value.trim()) == null) {
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
                    if (int.tryParse(value.trim()) == null) {
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

/// Custom painter for scanner overlay with dark mask around ROI
class _ScannerOverlayPainter extends CustomPainter {
  final double boxSize;
  final double left;
  final double top;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.boxSize,
    required this.left,
    required this.top,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Create path for the dark overlay
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create cutout for the scanning box
    final RRect cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxSize, boxSize),
      const Radius.circular(16),
    );

    // Subtract the cutout from the overlay
    final Path cutoutPath = Path()..addRRect(cutout);
    final Path finalPath =
        Path.combine(PathOperation.difference, path, cutoutPath);

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.boxSize != boxSize ||
        oldDelegate.left != left ||
        oldDelegate.top != top ||
        oldDelegate.borderColor != borderColor;
  }
}
