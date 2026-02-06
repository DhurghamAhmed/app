# City Vape - Flutter Mobile Application

## 📱 نظرة عامة على المشروع

**City Vape** هو تطبيق Flutter لإدارة متجر Vape، يوفر نظام شامل لإدارة المبيعات، الديون، والمعاملات المالية.

---

## 🏗️ البنية التقنية

### التقنيات المستخدمة:
- **Framework:** Flutter 3.27+
- **Language:** Dart
- **State Management:** Provider
- **Backend:** Firebase (Authentication, Firestore)
- **UI/UX:** Material Design مع تصميم مخصص

### الحزم الرئيسية:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
  provider: latest
  intl: latest
```

---

## 📂 هيكل المشروع

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # الثوابت العامة
│   └── theme/
│       ├── app_colors.dart             # نظام الألوان
│       ├── app_text_styles.dart        # أنماط النصوص
│       └── app_theme.dart              # Theme الرئيسي
│
├── models/
│   ├── user_model.dart                 # نموذج المستخدم
│   ├── debtor_model.dart               # نموذج المدين
│   ├── debt_item_model.dart            # نموذج عنصر الدين
│   ├── transaction_model.dart          # نموذج المعاملة
│   ├── sales_list_model.dart           # نموذج قائمة المبيعات
│   └── models.dart                     # تصدير جميع النماذج
│
├── providers/
│   ├── auth_provider.dart              # إدارة حالة المصادقة
│   ├── theme_provider.dart             # إدارة حالة الثيم
│   └── providers.dart                  # تصدير جميع Providers
│
├── services/
│   ├── auth_service.dart               # خدمات المصادقة
│   ├── debtor_service.dart             # خدمات إدارة الديون
│   ├── transaction_service.dart        # خدمات المعاملات
│   ├── sales_service.dart              # خدمات المبيعات
│   └── services.dart                   # تصدير جميع الخدمات
│
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart          # شاشة البداية
│   ├── auth/
│   │   └── auth_screen.dart            # شاشة تسجيل الدخول/التسجيل
│   ├── dashboard/
│   │   └── dashboard_screen.dart       # الشاشة الرئيسية
│   ├── debtor/
│   │   └── add_debtor_screen.dart      # إدارة المدينين
│   ├── sales/
│   │   └── sales_lists_screen.dart     # قوائم المبيعات
│   ├── transactions/
│   │   └── transactions_screen.dart    # المعاملات المالية
│   └── settings/
│       └── settings_screen.dart        # الإعدادات
│
├── widgets/
│   ├── app_card.dart                   # بطاقة مخصصة
│   ├── input_field.dart                # حقل إدخال مخصص
│   ├── primary_button.dart             # زر رئيسي
│   ├── kpi_card.dart                   # بطاقة مؤشرات الأداء
│   ├── progress_ring.dart              # حلقة التقدم
│   ├── section_title.dart              # عنوان القسم
│   └── widgets.dart                    # تصدير جميع Widgets
│
├── firebase_options.dart               # إعدادات Firebase
└── main.dart                           # نقطة البداية
```

---

## 🎨 نظام التصميم

### الألوان الرئيسية:
```dart
// Primary Colors - Modern Purple/Violet gradient
primary: Color(0xFF6C5CE7)
primaryLight: Color(0xFF8B7CF6)
primaryDark: Color(0xFF5641E5)

// Secondary Colors - Teal accent
secondary: Color(0xFF00D9A5)
secondaryLight: Color(0xFF5DFFC2)
secondaryDark: Color(0xFF00B386)

// Accent Colors
accent: Color(0xFFFF6B9D)
accentOrange: Color(0xFFFF9F43)
accentBlue: Color(0xFF54A0FF)

// Status Colors
success: Color(0xFF10B981)
warning: Color(0xFFF59E0B)
error: Color(0xFFEF4444)
info: Color(0xFF3B82F6)
```

### الثيمات:
- **Light Theme:** خلفية فاتحة مع ألوان زاهية
- **Dark Theme:** خلفية داكنة مع تباين عالي (قيد التطوير)

---

## 🔥 Firebase Structure

### Collections:
```
users/
  └── {userId}/
      ├── email: string
      ├── fullName: string
      ├── createdAt: timestamp
      └── role: string

debtors/
  └── {debtorId}/
      ├── userId: string
      ├── name: string
      ├── phone: string
      ├── totalDebt: number
      ├── createdAt: timestamp
      └── debtItems: subcollection
          └── {itemId}/
              ├── product: string
              ├── amount: number
              ├── date: timestamp
              └── notes: string

transactions/
  └── {transactionId}/
      ├── userId: string
      ├── debtorId: string
      ├── debtorName: string
      ├── type: string (payment/debt)
      ├── amount: number
      ├── description: string
      └── timestamp: timestamp

salesLists/
  └── {listId}/
      ├── userId: string
      ├── dateOpened: timestamp
      ├── dateClosed: timestamp?
      ├── totalAmount: number
      ├── status: string (open/closed)
      └── items: subcollection
          └── {itemId}/
              ├── name: string
              ├── price: number
              ├── quantity: number
              ├── total: number
              └── timestamp: timestamp
```

---

## 🚀 الميزات الرئيسية

### 1. المصادقة (Authentication)
- ✅ تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
- ✅ إنشاء حساب جديد
- ✅ إعادة تعيين كلمة المرور
- ✅ تغيير كلمة المرور
- ✅ تسجيل الخروج

### 2. لوحة التحكم (Dashboard)
- ✅ عرض إحصائيات المبيعات
- ✅ إجمالي الديون
- ✅ عدد المدينين
- ✅ المعاملات الأخيرة
- ✅ إجراءات سريعة (Quick Actions)

### 3. إدارة المدينين (Debtors Management)
- ✅ إضافة مدين جديد
- ✅ عرض قائمة المدينين
- ✅ تفاصيل كل مدين
- ✅ إضافة/تعديل/حذف عناصر الدين
- ✅ تسجيل الدفعات
- ✅ سجل المعاملات لكل مدين

### 4. قوائم المبيعات (Sales Lists)
- ✅ فتح قائمة مبيعات جديدة
- ✅ إضافة عناصر للقائمة
- ✅ حساب الإجمالي تلقائياً
- ✅ إغلاق القائمة
- ✅ عرض القوائم المغلقة (السجل)

### 5. المعاملات (Transactions)
- ✅ عرض جميع المعاملات
- ✅ تصفية حسب النوع (دفعات/ديون)
- ✅ البحث في المعاملات
- ✅ عرض التفاصيل الكاملة

### 6. الإعدادات (Settings)
- ✅ معلومات الملف الشخصي
- ✅ تغيير اللغة (متعدد اللغات)
- ✅ تغيير كلمة المرور
- ✅ الإشعارات
- ✅ تسجيل الخروج

---

## 🎯 أنماط البرمجة المستخدمة

### State Management Pattern:
```dart
// استخدام Provider لإدارة الحالة
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ],
  child: MyApp(),
)
```

### Service Layer Pattern:
```dart
// فصل منطق الأعمال عن UI
class DebtorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> addDebtor(DebtorModel debtor) async {
    // Business logic here
  }
}
```

### Repository Pattern:
```dart
// استخدام Streams للبيانات الحية
Stream<List<DebtorModel>> streamDebtors(String userId) {
  return _firestore
    .collection('debtors')
    .where('userId', isEqualTo: userId)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => DebtorModel.fromFirestore(doc))
      .toList());
}
```

---

## 🔒 الأمان

### Firebase Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /debtors/{debtorId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    match /salesLists/{listId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 📱 الشاشات والتنقل

### Navigation Flow:
```
SplashScreen
    ↓
AuthScreen (if not authenticated)
    ↓
DashboardScreen (Main Hub)
    ├── DebtorsScreen
    ├── SalesListsScreen
    ├── TransactionsScreen
    └── SettingsScreen
```

---

## 🛠️ التحديثات الأخيرة

### ✅ إصلاح التحذيرات (70/72):
1. **withOpacity → withValues(alpha:)** - توافق مع Flutter 3.27+
2. **use_build_context_synchronously** - إضافة فحوصات context.mounted
3. **prefer_const_constructors** - تحسين الأداء

---

## 📝 ملاحظات التطوير

### Best Practices:
- ✅ استخدام `const` constructors حيثما أمكن
- ✅ فحص `context.mounted` قبل استخدام BuildContext بعد async
- ✅ استخدام `.withValues(alpha:)` بدلاً من `.withOpacity()`
- ✅ فصل UI عن Business Logic
- ✅ استخدام Streams للبيانات الحية
- ✅ معالجة الأخطاء بشكل صحيح

### Code Style:
- استخدام camelCase للمتغيرات والدوال
- استخدام PascalCase للـ Classes
- استخدام snake_case لأسماء الملفات
- التعليقات بالعربية والإنجليزية

---

## 🚀 كيفية التشغيل

### المتطلبات:
```bash
Flutter SDK: >=3.0.0
Dart SDK: >=3.0.0
```

### خطوات التشغيل:
```bash
# 1. تثبيت الحزم
flutter pub get

# 2. تشغيل التطبيق
flutter run

# 3. بناء APK
flutter build apk --release

# 4. فحص الأخطاء
flutter analyze
```

---

## 📞 معلومات الاتصال

**Project Name:** City Vape  
**Type:** Flutter Mobile Application  
**Platform:** Android & iOS  
**Status:** Active Development  

---

## 📄 الترخيص

هذا المشروع خاص ومملوك لـ City Vape.

---

**آخر تحديث:** 2024  
**الإصدار:** 1.0.0
