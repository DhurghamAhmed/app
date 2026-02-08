# TODO - Create Custom Barcode Feature

## Completed Steps:
- [x] Add localization strings (EN/AR) in `app_localizations.dart`
- [x] Add 3rd option "Create Custom Barcode" in `_showScanOptionsSheet()`
- [x] Add `_generateCustomBarcodeId()` method
- [x] Add `_showCreateCustomBarcodeSheet()` bottom sheet with form
- [x] Fix `use_build_context_synchronously` warnings by capturing strings before async gap
- [x] Add `barcode_widget` package for visual barcode rendering
- [x] Add `_showBarcodeDialog()` for viewing product barcodes
- [x] Add barcode button in `_showProductDetails()` actions row
- [x] Add smart barcode type detection (`_detectBarcodeType()`)
- [x] QR codes display as square, linear barcodes as rectangular
- [x] EAN-8, EAN-13, UPC-A, ITF-14, Code128, QR auto-detection
- [x] Fallback error handling for invalid barcode formats
- [x] Verify flutter analyze passes with no errors ✅
- [x] Add Arabic numeral normalization (`_normalizeArabicNumbers()`) for ٠١٢٣٤٥٦٧٨٩ → 0123456789
- [x] Apply normalization consistently across ALL forms (custom barcode, add product, update stock)
- [x] Final flutter analyze verification after Arabic numeral changes ✅

## Files Modified:
1. `lib/core/localization/app_localizations.dart` - Added 10 new translation keys (EN/AR)
2. `lib/screens/inventory/inventory_scanner_screen.dart` - Full custom barcode feature + smart rendering
3. `pubspec.yaml` - Added `barcode_widget: ^2.0.4`
4. `TODO.md` - Task tracking
