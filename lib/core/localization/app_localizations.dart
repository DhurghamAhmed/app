import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'City Manager',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'search': 'Search',
      'no_data': 'No data',
      'retry': 'Retry',
      'items': 'items',
      'item': 'item',
      'total': 'Total',
      'stock': 'Stock',
      'quantity': 'Quantity',
      'price': 'Price',
      'barcode': 'Barcode',
      'units': 'units',
      'action_cannot_undo': 'This action cannot be undone.',
      'preferred': 'Preferred',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'welcome_back': 'Welcome back!',
      'please_login': 'Please login',
      'please_sign_in': 'Please sign in',

      // Dashboard
      'home': 'Home',
      'dashboard': 'Dashboard',
      'todays_performance': "Today's Performance",
      'total_sales': 'Total Sales',
      'monthly_sales': 'Monthly Sales',
      'total_debts': 'Total Debts',
      'debtors': 'Debtors',
      'recent_activity': 'Recent Activity',
      'your_latest_transactions': 'Your latest transactions',
      'last_sale': 'Last Sale',
      'last_debt': 'Last Debt',
      'no_sales_yet': 'No sales yet',
      'no_debts_yet': 'No debts yet',
      'start_selling': 'Start selling',
      'add_debtor': 'Add debtor',
      'top_debtors': 'Top Debtors',
      'view_all': 'View All',
      'no_outstanding_debts': 'No outstanding debts',
      'active': 'Active',
      'no_sales': 'No Sales',
      'just_now': 'Just now',
      'minutes_ago': 'm ago',
      'hours_ago': 'h ago',

      // Debtors
      'manage_your_debtors': 'Manage your debtors',
      'search_by_name': 'Search by name...',
      'no_debtors_yet': 'No debtors yet',
      'tap_to_add_debtor': 'Tap + to add a new debtor',
      'no_results_found': 'No results found',
      'no_debtor_matches': 'No debtor matches',
      'add_new_debtor': 'Add New Debtor',
      'enter_debtor_details': 'Enter debtor details and first debt',
      'debtor_name': 'Debtor Name',
      'enter_full_name': 'Enter full name',
      'product': 'Product',
      'what_did_they_buy': 'What did they buy?',
      'amount': 'Amount',
      'enter_price': 'Enter price',
      'name_required': 'Name is required',
      'product_required': 'Product is required',
      'amount_required': 'Amount is required',
      'invalid_amount': 'Invalid amount',
      'total_debt': 'Total Debt',
      'debts': 'Debts',
      'history': 'History',
      'no_debts': 'No debts yet',
      'tap_add_debt': 'Tap "Add Debt" to create one',
      'add_debt': 'Add Debt',
      'settle_mark_paid': 'Settle (Mark as Paid)',
      'edit_amount': 'Edit Amount',
      'edit_product_name': 'Edit Product Name',
      'delete_debt': 'Delete Debt',
      'delete_debtor': 'Delete Debtor?',
      'delete_debtor_confirm':
          'This will delete all debts. This action cannot be undone.',
      'debt_deleted': 'has been deleted',
      'debtor_removed': 'has been removed (no more debts)',
      'fully_settled': 'has been fully settled and removed',
      'debtor': 'Debtor',
      'debtor_not_found': 'Debtor not found',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'days_ago': 'days ago',
      'for_debtor': 'for',
      'required': 'Required',
      'invalid': 'Invalid',
      'edit_product_name_title': 'Edit Product Name',
      'enter_new_product_name': 'Enter new product name',
      'edit_amount_title': 'Edit Amount',
      'delete_debt_title': 'Delete Debt?',
      'delete_debt_confirm': 'Are you sure you want to delete this debt?',
      'unknown': 'Unknown',
      'no_description': 'No description',
      'debtor_already_exists': 'A debtor with this name already exists!',

      // Transactions
      'transactions': 'Transactions',
      'todays_activity': "Today's activity",
      'daily_sales': 'Daily Sales',
      'no_sales_today': 'No sales today',
      'sales_will_appear': 'Sales will appear here as you add them',
      'no_debtor_transactions': 'No debtor transactions',
      'debt_payment_records': 'Debt and payment records will appear here',
      'payment_received': 'Payment Received',
      'debt_added': 'Debt Added',
      'price_updated': 'Price Updated',
      'new_debt': 'New Debt',
      'performed_by': 'Performed By',
      'description': 'Description',
      'date': 'Date',
      'time': 'Time',
      'type': 'Type',
      'sale': 'Sale',
      'sale_transaction': 'Sale Transaction',
      'delete_transaction': 'Delete Transaction?',
      'delete_transaction_confirm':
          'Are you sure you want to delete this transaction?',
      'transaction_deleted': 'Transaction deleted',
      'error_deleting_transaction': 'Error deleting transaction',
      'cleanup_transactions': 'Cleanup Transactions',
      'remove_old_transactions':
          'Remove old transactions to keep your list clean',
      'keep_last_30': 'Keep Last 30',
      'delete_except_30': 'Delete all except the last 30',
      'keep_last_50': 'Keep Last 50',
      'delete_except_50': 'Delete all except the last 50',
      'delete_all': 'Delete All',
      'remove_all_cannot_undo': 'Remove all (cannot be undone)',
      'remove_all_warning': 'Remove all (cannot be undone)',
      'cleanup_complete': 'Cleanup complete!',
      'kept_last': 'Kept last',
      'error_during_cleanup': 'Error during cleanup',
      'delete_all_confirm': 'Delete All?',
      'delete_all_message':
          'This will permanently delete ALL transactions. This action cannot be undone!',
      'deleted_transactions': 'Deleted',
      'error_deleting_transactions': 'Error deleting transactions',

      // Sales
      'sales': 'Sales',
      'sales_lists': 'Sales Lists',
      'manage_daily_sales': 'Manage your daily sales',
      'create_new_list': 'Create New List',
      'list_name': 'List Name',
      'add_sale': 'Add Sale',
      'close_list': 'Close List',
      'reopen_list': 'Reopen List',
      'delete_list': 'Delete List',
      'no_lists_yet': 'No sales lists yet',
      'tap_create_list': 'Tap + to create a new list',
      'open': 'Open',
      'closed': 'Closed',
      'open_new_sales_list': 'Open New Sales List',
      'new_sales_list_opened': 'New sales list opened!',
      'close_list_first': 'Close List First',
      'close_list_first_message':
          'You have an active sales list with items. Please close it before opening a new one.',
      'no_active_sales_list': 'No Active Sales List',
      'opened': 'Opened',
      'view_items': 'View Items',
      'no_items_yet': 'No items yet. Add your first sale!',
      'add_item': 'Add Item',
      'closed_lists': 'Closed Lists',
      'previous_sales_history': 'Previous sales history',
      'no_closed_lists_yet': 'No closed lists yet',
      'all_items': 'All Items',
      'tap_to_edit_swipe_delete': 'Tap to edit • Swipe left to delete',
      'no_items_in_list': 'No items in this list',
      'edit_item': 'Edit Item',
      'qty': 'Qty',
      'save_changes': 'Save Changes',
      'item_updated': 'Item updated successfully!',
      'remove_item': 'Remove Item?',
      'item_will_be_removed': 'This item will be removed from the list.',
      'item_removed': 'Item removed',
      'item_restored': 'Item restored',
      'close_sales_list': 'Close Sales List?',
      'close_list_message':
          'This will close the current list and save it to history. You cannot add more items after closing.',
      'empty_list_closed': 'Empty list closed',
      'sales_list_closed': 'Sales list closed and saved!',
      'sales_list_details': 'Sales List Details',
      'delete_sales_list': 'Delete Sales List?',
      'delete_list_message':
          'This will permanently delete this sales list and all its items. This action cannot be undone.',
      'sales_list_deleted': 'Sales list deleted successfully!',
      'error_deleting_list': 'Error deleting list',
      'add_sale_item': 'Add Sale Item',
      'search_list_or_inventory': 'Search list or inventory',
      'start_typing_to_search': 'Start typing to search...',
      'from_this_list': 'This list',
      'from_inventory': 'Inventory',
      'in_stock_badge': 'in stock',
      'not_enough_stock': 'Not enough stock! Available',
      'failed_to_update_inventory': 'Failed to update inventory stock',
      'item_added_inventory_decreased': 'Item added! Inventory decreased by',
      'scan_barcode_title': 'Scan Barcode',
      'point_camera_at_barcode': 'Point camera at barcode to scan',
      'product_not_in_inventory': 'Product not found in inventory',
      'available_stock': 'Available Stock',
      'scan_again': 'Scan Again',
      'add_to_list': 'Add to List',
      'added_to_list': 'added!',
      'add_and_decrease_stock': 'Add & Decrease Stock',
      'add_new_item': 'Add new item',
      'scan_product_barcode': 'Scan product barcode to add',
      'product_not_found_barcode': 'Product not found in inventory',
      'barcode_not_found': 'Barcode Not Found',
      'barcode_not_in_inventory':
          'This barcode is not registered in your inventory.',
      'try_again': 'Try Again',

      // Inventory
      'inventory': 'Inventory',
      'scan_barcode': 'Scan Barcode',
      'add_product': 'Add Product',
      'product_name': 'Product Name',
      'low_stock': 'Low Stock',
      'out_of_stock': 'Out of Stock',
      'inventory_scanner': 'Inventory Scanner',
      'scan_products_manage_stock': 'Scan products to manage stock',
      'choose_scan_method': 'Choose how you want to scan',
      'scan_with_camera': 'Scan with Camera',
      'use_camera_to_scan': 'Use your camera to scan barcodes',
      'scan_from_image': 'Scan from Image',
      'select_image_from_gallery': 'Select an image from gallery',
      'center_barcode_frame': 'Center barcode in frame',
      'align_barcode_here': 'Align barcode here',
      'scanned': 'Scanned!',
      'searching': 'Searching...',
      'processing_image': 'Processing Image...',
      'enhancing_image': 'Enhancing image for better detection',
      'scanned_barcode': 'Scanned Barcode',
      'no_barcode_found': 'No barcode found. Try a clearer image.',
      'error_scanning_image': 'Error scanning image',
      'please_login_scanner': 'Please login to use the scanner',
      'please_login_add_products': 'Please login to add products',
      'error_searching_product': 'Error searching for product',
      'product_found': 'Product Found',
      'product_not_found': 'Product Not Found',
      'add_new_product': 'Add New Product',
      'fill_product_details':
          'Fill in the details to add this product to inventory',
      'enter_product_name': 'Enter product name',
      'please_enter_product_name': 'Please enter product name',
      'price_iqd': 'Price (IQD)',
      'please_enter_price': 'Please enter price',
      'please_enter_valid_number': 'Please enter a valid number',
      'initial_quantity': 'Initial Quantity',
      'enter_quantity': 'Enter quantity',
      'please_enter_quantity': 'Please enter quantity',
      'enter_valid_quantity': 'Please enter a valid quantity',
      'save_product': 'Save Product',
      'product_added_inventory': 'Product added to inventory',
      'failed_add_product': 'Failed to add product',
      'add_stock': 'Add Stock',
      'enter_quantity_to_add': 'Enter quantity to add',
      'update_quantity': 'Update Quantity',
      'stock_updated': 'Stock updated',
      'failed_update_stock': 'Failed to update stock',
      'scan_another': 'Scan Another',
      'no_products_yet': 'No Products Yet',
      'scan_barcode_add_product': 'Scan a barcode to add your first product',
      'error_loading_products': 'Error loading products',
      'please_try_again': 'Please try again',
      'in_stock': 'In Stock',
      'added_on': 'Added On',
      'update_stock': 'Update Stock',
      'add_quantity_to': 'Add quantity to',
      'current_stock': 'Current stock',
      'quantity_to_add': 'Quantity to Add',
      'delete_product_title': 'Delete Product?',
      'delete_product_confirm': 'Are you sure you want to delete',
      'product_deleted': 'Product deleted',
      'failed_delete_product': 'Failed to delete product',
      'search_products': 'Search products...',
      'results_found': 'results found',
      'no_products_found': 'No products found',
      'try_different_search': 'Try a different search term',
      'create_custom_barcode': 'Create Custom Barcode',
      'create_custom_barcode_desc': 'Create a product with a unique barcode',
      'generated_barcode': 'Generated Barcode',
      'create_and_save': 'Create & Save',
      'product_created_successfully': 'Product created with custom barcode!',
      'failed_create_product': 'Failed to create product',
      'enter_product_details':
          'Enter product details to create a custom barcode',
      'custom_barcode_id': 'Custom Barcode ID',
      'product_barcode': 'Product Barcode',
      'show_barcode': 'Show Barcode',

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'overdue_debt': 'Overdue Debt',
      'high_debt': 'High Debt',
      'days_overdue': 'days overdue',
      'restock_needed': 'Restock needed',
      'only_left': 'Only',
      'left': 'left',
      'stay_updated': 'Stay updated with your business',
      'all_caught_up': 'All caught up!',
      'no_pending_notifications': 'No pending notifications',
      'this_week': 'This Week',
      'earlier': 'Earlier',
      'high_amount': 'High amount',

      // Settings
      'settings': 'Settings',
      'manage_preferences': 'Manage your preferences',
      'language': 'Language',
      'change_password': 'Change Password',
      'update_your_password': 'Update your password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'password_changed': 'Password changed successfully',
      'auto_delete_old_sales': 'Auto-Delete Old Sales',
      'keep_current_previous_month': 'Keep only current & previous month',
      'auto_delete_info':
          'Old closed sales lists will be automatically deleted.',
      'logout_confirm': 'Are you sure you want to logout?',
      'account': 'Account',
      'please_enter_current_password': 'Please enter your current password',
      'please_enter_new_password': 'Please enter a new password',
      'password_min_length': 'Password must be at least 6 characters',
      'please_confirm_password': 'Please confirm your new password',
      'passwords_not_match': 'Passwords do not match',
      'failed_to_change_password': 'Failed to change password',
      'change': 'Change',
      'manage_notifications': 'Manage notifications',
      'english': 'English',
      'arabic': 'Arabic',

      // Errors
      'error_loading': 'Error loading data',
      'error_saving': 'Error saving data',
      'error_deleting': 'Error deleting',
      'required_field': 'This field is required',
    },
    'ar': {
      // General
      'app_name': 'ستي فيب',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'close': 'إغلاق',
      'confirm': 'تأكيد',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'موافق',
      'search': 'بحث',
      'no_data': 'لا توجد بيانات',
      'retry': 'إعادة المحاولة',
      'items': 'المنتجات',
      'item': 'منتج',
      'total': 'الإجمالي',
      'stock': 'المخزون',
      'quantity': 'الكمية',
      'price': 'السعر',
      'barcode': 'الباركود',
      'units': 'وحدات',
      'action_cannot_undo': 'لا يمكن التراجع عن هذا الإجراء.',
      'preferred': 'مفضل',

      // Auth
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'sign_in': 'تسجيل الدخول',
      'sign_up': 'إنشاء حساب',
      'welcome_back': 'مرحباً بعودتك!',
      'please_login': 'يرجى تسجيل الدخول',
      'please_sign_in': 'يرجى تسجيل الدخول',

      // Dashboard
      'home': 'الرئيسية',
      'dashboard': 'لوحة التحكم',
      'todays_performance': 'مبيعات اليوم',
      'total_sales': 'إجمالي المبيعات',
      'monthly_sales': 'المبيعات الشهرية',
      'total_debts': 'إجمالي الديون',
      'debtors': 'المديونين',
      'recent_activity': 'النشاط الأخير',
      'your_latest_transactions': 'آخر المعاملات',
      'last_sale': 'آخر بيع',
      'last_debt': 'آخر دين',
      'no_sales_yet': 'لا توجد مبيعات',
      'no_debts_yet': 'لا توجد ديون',
      'start_selling': 'ابدأ البيع',
      'add_debtor': 'أضف مدين',
      'top_debtors': 'أعلى المديونين',
      'view_all': 'عرض الكل',
      'no_outstanding_debts': 'لا توجد ديون مستحقة',
      'active': 'نشط',
      'no_sales': 'لا توجد مبيعات',
      'just_now': 'الآن',
      'minutes_ago': 'د مضت',
      'hours_ago': 'س مضت',

      // Debtors
      'manage_your_debtors': 'إدارة المديونين',
      'search_by_name': 'البحث بالاسم...',
      'no_debtors_yet': 'لا يوجد مديونين',
      'tap_to_add_debtor': 'اضغط + لإضافة مدين جديد',
      'no_results_found': 'لا توجد نتائج',
      'no_debtor_matches': 'لا يوجد مدين مطابق',
      'add_new_debtor': 'إضافة مدين جديد',
      'enter_debtor_details': 'أدخل تفاصيل المدين والدين الأول',
      'debtor_name': 'اسم المدين',
      'enter_full_name': 'أدخل الاسم الكامل',
      'product': 'المنتج',
      'what_did_they_buy': 'ماذا اشترى؟',
      'amount': 'المبلغ',
      'enter_price': 'أدخل السعر',
      'name_required': 'الاسم مطلوب',
      'product_required': 'المنتج مطلوب',
      'amount_required': 'المبلغ مطلوب',
      'invalid_amount': 'مبلغ غير صالح',
      'total_debt': 'إجمالي الدين',
      'debts': 'الديون',
      'history': 'السجل',
      'no_debts': 'لا توجد ديون',
      'tap_add_debt': 'اضغط "إضافة دين" للإنشاء',
      'add_debt': 'إضافة دين',
      'settle_mark_paid': 'تسوية (تم الدفع)',
      'edit_amount': 'تعديل المبلغ',
      'edit_product_name': 'تعديل اسم المنتج',
      'delete_debt': 'حذف الدين',
      'delete_debtor': 'حذف المدين؟',
      'delete_debtor_confirm':
          'سيتم حذف جميع الديون. لا يمكن التراجع عن هذا الإجراء.',
      'debt_deleted': 'تم الحذف',
      'debtor_removed': 'تم الإزالة (لا ديون متبقية)',
      'fully_settled': 'تمت التسوية بالكامل وتم الإزالة',
      'debtor': 'المدين',
      'debtor_not_found': 'المدين غير موجود',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'days_ago': 'أيام مضت',
      'for_debtor': 'لـ',
      'required': 'مطلوب',
      'invalid': 'غير صالح',
      'edit_product_name_title': 'تعديل اسم المنتج',
      'enter_new_product_name': 'أدخل اسم المنتج الجديد',
      'edit_amount_title': 'تعديل المبلغ',
      'delete_debt_title': 'حذف الدين؟',
      'delete_debt_confirm': 'هل أنت متأكد من حذف هذا الدين؟',
      'unknown': 'غير معروف',
      'no_description': 'لا يوجد وصف',
      'debtor_already_exists': 'يوجد مدين بهذا الاسم بالفعل!',

      // Transactions
      'transactions': 'المعاملات',
      'todays_activity': 'نشاط اليوم',
      'daily_sales': 'المبيعات اليومية',
      'no_sales_today': 'لا مبيعات اليوم',
      'sales_will_appear': 'ستظهر المبيعات هنا عند إضافتها',
      'no_debtor_transactions': 'لا توجد معاملات',
      'debt_payment_records': 'سجلات الديون والمدفوعات ستظهر هنا',
      'payment_received': 'تم استلام الدفعة',
      'debt_added': 'تم إضافة دين',
      'price_updated': 'تم تحديث السعر',
      'new_debt': 'دين جديد',
      'performed_by': 'بواسطة',
      'description': 'الوصف',
      'date': 'التاريخ',
      'time': 'الوقت',
      'type': 'النوع',
      'sale': 'بيع',
      'sale_transaction': 'معاملة بيع',
      'delete_transaction': 'حذف المعاملة؟',
      'delete_transaction_confirm': 'هل أنت متأكد من حذف هذه المعاملة؟',
      'transaction_deleted': 'تم حذف المعاملة',
      'error_deleting_transaction': 'خطأ في حذف المعاملة',
      'cleanup_transactions': 'تنظيف المعاملات',
      'remove_old_transactions':
          'إزالة المعاملات القديمة للحفاظ على القائمة نظيفة',
      'keep_last_30': 'الإبقاء على آخر 30',
      'delete_except_30': 'حذف الكل ما عدا آخر 30',
      'keep_last_50': 'الإبقاء على آخر 50',
      'delete_except_50': 'حذف الكل ما عدا آخر 50',
      'delete_all': 'حذف الكل',
      'remove_all_cannot_undo': 'حذف الكل (لا يمكن التراجع)',
      'remove_all_warning': 'إزالة الكل (لا يمكن التراجع)',
      'cleanup_complete': 'تم التنظيف!',
      'kept_last': 'تم الإبقاء على آخر',
      'error_during_cleanup': 'خطأ أثناء التنظيف',
      'delete_all_confirm': 'حذف الكل؟',
      'delete_all_message':
          'سيتم حذف جميع المعاملات نهائياً. لا يمكن التراجع عن هذا الإجراء!',
      'deleted_transactions': 'تم حذف',
      'error_deleting_transactions': 'خطأ في حذف المعاملات',

      // Sales
      'sales': 'المبيعات',
      'sales_lists': 'قوائم المبيعات',
      'manage_daily_sales': 'إدارة المبيعات اليومية',
      'create_new_list': 'إنشاء قائمة جديدة',
      'list_name': 'اسم القائمة',
      'add_sale': 'إضافة بيع',
      'close_list': 'إغلاق القائمة',
      'reopen_list': 'إعادة فتح القائمة',
      'delete_list': 'حذف القائمة',
      'no_lists_yet': 'لا توجد قوائم مبيعات',
      'tap_create_list': 'اضغط + لإنشاء قائمة جديدة',
      'open': 'مفتوح',
      'closed': 'مغلق',
      'open_new_sales_list': 'فتح قائمة مبيعات جديدة',
      'new_sales_list_opened': 'تم فتح قائمة مبيعات جديدة!',
      'close_list_first': 'أغلق القائمة أولاً',
      'close_list_first_message':
          'لديك قائمة مبيعات نشطة تحتوي على عناصر. يرجى إغلاقها قبل فتح قائمة جديدة.',
      'no_active_sales_list': 'لا توجد قائمة مبيعات نشطة',
      'opened': 'مفتوحة',
      'view_items': 'عرض العناصر',
      'no_items_yet': 'لا توجد عناصر بعد. أضف أول عملية بيع!',
      'add_item': 'بيع',
      'closed_lists': 'القوائم المغلقة',
      'previous_sales_history': 'سجل المبيعات السابقة',
      'no_closed_lists_yet': 'لا توجد قوائم مغلقة بعد',
      'all_items': 'جميع العناصر',
      'tap_to_edit_swipe_delete': 'اضغط للتعديل • اسحب لليسار للحذف',
      'no_items_in_list': 'لا توجد عناصر في هذه القائمة',
      'edit_item': 'تعديل العنصر',
      'qty': 'الكمية',
      'save_changes': 'حفظ التغييرات',
      'item_updated': 'تم تحديث العنصر بنجاح!',
      'remove_item': 'إزالة العنصر؟',
      'item_will_be_removed': 'سيتم إزالة هذا العنصر من القائمة.',
      'item_removed': 'تم إزالة العنصر',
      'item_restored': 'تم استعادة العنصر',
      'close_sales_list': 'إغلاق قائمة المبيعات؟',
      'close_list_message':
          'سيتم إغلاق القائمة الحالية وحفظها في السجل. لا يمكنك إضافة المزيد من العناصر بعد الإغلاق.',
      'empty_list_closed': 'تم إغلاق القائمة الفارغة',
      'sales_list_closed': 'تم إغلاق قائمة المبيعات وحفظها!',
      'sales_list_details': 'تفاصيل قائمة المبيعات',
      'delete_sales_list': 'حذف قائمة المبيعات؟',
      'delete_list_message':
          'سيتم حذف قائمة المبيعات هذه وجميع عناصرها نهائياً. لا يمكن التراجع عن هذا الإجراء.',
      'sales_list_deleted': 'تم حذف قائمة المبيعات بنجاح!',
      'error_deleting_list': 'خطأ في حذف القائمة',
      'add_sale_item': 'إضافة منتج للبيع',
      'search_list_or_inventory': 'البحث في القائمة أو المخزون',
      'start_typing_to_search': 'ابدأ الكتابة للبحث...',
      'from_this_list': 'هذه القائمة',
      'from_inventory': 'المخزون',
      'in_stock_badge': 'في المخزون',
      'not_enough_stock': 'المخزون غير كافٍ! المتوفر',
      'failed_to_update_inventory': 'فشل في تحديث مخزون المنتج',
      'item_added_inventory_decreased': 'تمت الإضافة! تم تقليل المخزون بـ',
      'scan_barcode_title': 'مسح الباركود',
      'point_camera_at_barcode': 'وجه الكاميرا نحو الباركود للمسح',
      'product_not_in_inventory': 'المنتج غير موجود في المخزون',
      'available_stock': 'المخزون المتوفر',
      'scan_again': 'مسح مرة أخرى',
      'add_to_list': 'إضافة للقائمة',
      'added_to_list': 'تمت الإضافة!',
      'add_and_decrease_stock': 'بيع',
      'add_new_item': 'إضافة عنصر جديد',
      'scan_product_barcode': 'امسح باركود المنتج للإضافة',
      'product_not_found_barcode': 'المنتج غير موجود في المخزون',
      'barcode_not_found': 'الباركود غير موجود',
      'barcode_not_in_inventory': 'هذا الباركود غير مسجل في المخزون.',
      'try_again': 'إعادة المحاولة',

      // Inventory
      'inventory': 'المخزون',
      'scan_barcode': 'مسح الباركود',
      'add_product': 'إضافة منتج',
      'product_name': 'اسم المنتج',
      'low_stock': 'مخزون منخفض',
      'out_of_stock': 'نفذ من المخزون',
      'inventory_scanner': 'باركود المخزون',
      'scan_products_manage_stock': 'امسح المنتجات لإدارة المخزون',
      'choose_scan_method': 'اختر طريقة المسح',
      'scan_with_camera': 'المسح بالكاميرا',
      'use_camera_to_scan': 'استخدم الكاميرا لمسح الباركود',
      'scan_from_image': 'المسح من صورة',
      'select_image_from_gallery': 'اختر صورة من المعرض',
      'center_barcode_frame': 'ضع الباركود في المنتصف',
      'align_barcode_here': 'ضع الباركود هنا',
      'scanned': 'تم المسح!',
      'searching': 'جاري البحث...',
      'processing_image': 'جاري معالجة الصورة...',
      'enhancing_image': 'تحسين الصورة للكشف الأفضل',
      'scanned_barcode': 'الباركود الممسوح',
      'no_barcode_found': 'لم يتم العثور على باركود. جرب صورة أوضح.',
      'error_scanning_image': 'خطأ في مسح الصورة',
      'please_login_scanner': 'يرجى تسجيل الدخول لاستخدام الباركود',
      'please_login_add_products': 'يرجى تسجيل الدخول لإضافة المنتجات',
      'error_searching_product': 'خطأ في البحث عن المنتج',
      'product_found': 'تم العثور على المنتج',
      'product_not_found': 'المنتج غير موجود',
      'add_new_product': 'إضافة منتج جديد',
      'fill_product_details': 'أدخل التفاصيل لإضافة هذا المنتج للمخزون',
      'enter_product_name': 'أدخل اسم المنتج',
      'please_enter_product_name': 'يرجى إدخال اسم المنتج',
      'price_iqd': 'السعر (د.ع)',
      'please_enter_price': 'يرجى إدخال السعر',
      'please_enter_valid_number': 'يرجى إدخال رقم صحيح',
      'initial_quantity': 'الكمية الأولية',
      'enter_quantity': 'أدخل الكمية',
      'please_enter_quantity': 'يرجى إدخال الكمية',
      'enter_valid_quantity': 'يرجى إدخال كمية صحيحة',
      'save_product': 'حفظ المنتج',
      'product_added_inventory': 'تمت إضافة المنتج للمخزون',
      'failed_add_product': 'فشل في إضافة المنتج',
      'add_stock': 'إضافة مخزون',
      'enter_quantity_to_add': 'أدخل الكمية للإضافة',
      'update_quantity': 'تحديث الكمية',
      'stock_updated': 'تم تحديث المخزون',
      'failed_update_stock': 'فشل في تحديث المخزون',
      'scan_another': 'مسح آخر',
      'no_products_yet': 'لا توجد منتجات بعد',
      'scan_barcode_add_product': 'امسح باركود لإضافة أول منتج',
      'error_loading_products': 'خطأ في تحميل المنتجات',
      'please_try_again': 'يرجى المحاولة مرة أخرى',
      'in_stock': 'في المخزون',
      'added_on': 'تاريخ الإضافة',
      'update_stock': 'تحديث المخزون',
      'add_quantity_to': 'إضافة كمية إلى',
      'current_stock': 'المخزون الحالي',
      'quantity_to_add': 'الكمية للإضافة',
      'delete_product_title': 'حذف المنتج؟',
      'delete_product_confirm': 'هل أنت متأكد من حذف',
      'product_deleted': 'تم حذف المنتج',
      'failed_delete_product': 'فشل في حذف المنتج',
      'search_products': 'البحث في المنتجات...',
      'results_found': 'نتيجة',
      'no_products_found': 'لم يتم العثور على منتجات',
      'try_different_search': 'جرب كلمة بحث مختلفة',
      'create_custom_barcode': 'إنشاء باركود مخصص',
      'create_custom_barcode_desc': 'إنشاء منتج بباركود فريد',
      'generated_barcode': 'الباركود المُنشأ',
      'create_and_save': 'إنشاء وحفظ',
      'product_created_successfully': 'تم إنشاء المنتج بباركود مخصص!',
      'failed_create_product': 'فشل في إنشاء المنتج',
      'enter_product_details': 'أدخل تفاصيل المنتج لإنشاء باركود مخصص',
      'custom_barcode_id': 'رقم الباركود المخصص',
      'product_barcode': 'باركود المنتج',
      'show_barcode': 'عرض الباركود',

      // Notifications
      'notifications': 'الإشعارات',
      'no_notifications': 'لا توجد إشعارات',
      'overdue_debt': 'دين متأخر',
      'high_debt': 'دين مرتفع',
      'days_overdue': 'أيام تأخير',
      'restock_needed': 'يحتاج إعادة تخزين',
      'only_left': 'فقط',
      'left': 'متبقي',
      'stay_updated': 'ابق على اطلاع بأعمالك',
      'all_caught_up': 'لا توجد إشعارات جديدة!',
      'no_pending_notifications': 'لا توجد إشعارات معلقة',
      'this_week': 'هذا الأسبوع',
      'earlier': 'سابقاً',
      'high_amount': 'مبلغ مرتفع',

      // Settings
      'settings': 'الإعدادات',
      'manage_preferences': 'إدارة التفضيلات',
      'language': 'اللغة',
      'change_password': 'تغيير كلمة المرور',
      'update_your_password': 'تحديث كلمة المرور',
      'current_password': 'كلمة المرور الحالية',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
      'password_changed': 'تم تغيير كلمة المرور بنجاح',
      'auto_delete_old_sales': 'حذف المبيعات القديمة تلقائياً',
      'keep_current_previous_month': 'الاحتفاظ بالشهر الحالي والسابق فقط',
      'auto_delete_info': 'سيتم حذف قوائم المبيعات المغلقة القديمة تلقائياً.',
      'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
      'account': 'الحساب',
      'please_enter_current_password': 'يرجى إدخال كلمة المرور الحالية',
      'please_enter_new_password': 'يرجى إدخال كلمة مرور جديدة',
      'password_min_length': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'please_confirm_password': 'يرجى تأكيد كلمة المرور الجديدة',
      'passwords_not_match': 'كلمات المرور غير متطابقة',
      'failed_to_change_password': 'فشل في تغيير كلمة المرور',
      'change': 'تغيير',
      'manage_notifications': 'إدارة الإشعارات',
      'english': 'الإنجليزية',
      'arabic': 'العربية',

      // Errors
      'error_loading': 'خطأ في تحميل البيانات',
      'error_saving': 'خطأ في حفظ البيانات',
      'error_deleting': 'خطأ في الحذف',
      'required_field': 'هذا الحقل مطلوب',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Shorthand getter for common translations
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get close => translate('close');
  String get confirm => translate('confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get search => translate('search');
  String get noData => translate('no_data');
  String get retry => translate('retry');

  // Auth
  String get login => translate('login');
  String get logout => translate('logout');
  String get email => translate('email');
  String get password => translate('password');
  String get welcomeBack => translate('welcome_back');

  // Dashboard
  String get home => translate('home');
  String get dashboard => translate('dashboard');
  String get todaysPerformance => translate('todays_performance');
  String get totalSales => translate('total_sales');
  String get monthlySales => translate('monthly_sales');
  String get totalDebts => translate('total_debts');
  String get debtors => translate('debtors');
  String get topDebtors => translate('top_debtors');
  String get viewAll => translate('view_all');

  // Debtors
  String get manageYourDebtors => translate('manage_your_debtors');
  String get searchByName => translate('search_by_name');
  String get addNewDebtor => translate('add_new_debtor');
  String get debtorName => translate('debtor_name');
  String get product => translate('product');
  String get amount => translate('amount');

  // Transactions
  String get transactions => translate('transactions');
  String get todaysActivity => translate('todays_activity');
  String get dailySales => translate('daily_sales');
  String get history => translate('history');
  String get paymentReceived => translate('payment_received');
  String get debtAdded => translate('debt_added');
  String get priceUpdated => translate('price_updated');

  // Settings
  String get settings => translate('settings');
  String get managePreferences => translate('manage_preferences');
  String get language => translate('language');
  String get changePassword => translate('change_password');

  // Sales
  String get sales => translate('sales');
  String get salesLists => translate('sales_lists');

  // Inventory
  String get inventory => translate('inventory');

  // Notifications
  String get notifications => translate('notifications');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension for easy access
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}
