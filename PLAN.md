# خطة تنفيذ تطبيق "المنبّه المتكرر" (Recurring Reminder App) — Flutter / Android

> هذه الوثيقة موجّهة لنموذج ذكاء اصطناعي مُنفِّذ. اتبعها حرفياً وبالترتيب. كل أمر قابل للنسخ والتنفيذ المباشر.
> البيئة المستهدفة: **Ubuntu 24.04 (x86_64)**، sudo بدون كلمة مرور متاح، الأدوات `curl wget unzip git tar` موجودة، JDK/Flutter/Android SDK **غير مثبتة**.
> المجلد الجذر للمشروع: `/home/tw/PhpstormProjects/moving_flater_app`.

---

## 0) القرارات المعتمدة (مثبّتة — لا تُغيّرها)

1. **تثبيت كامل لسلسلة الأدوات** من الصفر: JDK 17 + Flutter (stable) + Android SDK (cmdline-tools فقط، بدون Android Studio).
2. **سلوك التنبيه = شاشة منبّه كاملة (Full-Screen Alarm)**: عند حلول الموعد يُفتح إشعار `fullScreenIntent` يطلق شاشة تملأ الشاشة (مثل المنبّه الحقيقي) مع:
   - صوت من نوع **alarm** (عالٍ، يتجاوز وضع الصامت عبر قناة alarm).
   - اهتزاز.
   - زر **إيقاف (Dismiss)** وزر **غفوة/إعادة (Snooze)** اختياري.
3. **ساعة اليد (Wear OS):** لا نبني وحدة Wear مستقلة. نعتمد على **انعكاس إشعارات Android تلقائياً** على الساعة المقترنة (Notification Bridging)، مع ضبط القناة لتفعيل الاهتزاز على الساعة. نُضيف `setLocalOnly(false)` ضمناً (الافتراضي) لضمان الجسر، ونستخدم قناة عالية الأهمية.
4. التخزين المحلي عبر `shared_preferences` (لا قاعدة بيانات).
5. الجدولة الموثوقة (تعمل والتطبيق مغلق وبعد إعادة التشغيل) عبر **`android_alarm_manager_plus`**.
6. الناتج النهائي: ملف **APK release** يُنسخ للهاتف ويُثبّت ويعمل مباشرة.

---

## 1) تثبيت سلسلة الأدوات (Toolchain)

### 1.1 تثبيت JDK 17
```bash
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jdk-headless
java -version   # يجب أن يظهر 17.x
```
أضف JAVA_HOME (للجلسة):
```bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
```

### 1.2 تثبيت Flutter (stable channel)
```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
flutter --version
flutter config --no-analytics
```

### 1.3 تثبيت Android SDK (cmdline-tools فقط)
```bash
export ANDROID_HOME=$HOME/Android/Sdk
mkdir -p $ANDROID_HOME/cmdline-tools
cd /tmp
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip
unzip -q cmdtools.zip -d $ANDROID_HOME/cmdline-tools
# يجب أن تكون البنية: cmdline-tools/latest/bin
mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest

# متغيرات البيئة الدائمة
{
  echo 'export ANDROID_HOME=$HOME/Android/Sdk'
  echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools'
} >> ~/.bashrc
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
```
> ملاحظة: رابط cmdline-tools قد يتغيّر. إن فشل، احصل على آخر رابط من https://developer.android.com/studio#command-line-tools-only

### 1.4 تثبيت مكوّنات SDK وقبول التراخيص
```bash
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### 1.5 ربط Flutter بالـ SDK والتحقق
```bash
flutter config --android-sdk $ANDROID_HOME
flutter doctor -v
```
**شرط القبول:** يجب أن يظهر ✓ عند "Android toolchain" و"Flutter". (متصفّح/Android Studio غير مطلوبين.)

> تحذير مساحة القرص: المساحة الحرة ~17GB. Flutter+SDK يستهلكان ~6–8GB. راقب `df -h`.

---

## 2) إنشاء المشروع

```bash
cd /home/tw/PhpstormProjects
flutter create --org com.tawseel --project-name reminder_app moving_flater_app 2>/dev/null || \
  ( cd moving_flater_app && flutter create --org com.tawseel --project-name reminder_app . )
cd /home/tw/PhpstormProjects/moving_flater_app
```
> المجلد موجود مسبقاً (يحوي PLAN.md)، لذا استخدم `flutter create .` داخله. احتفظ بـ PLAN.md.

---

## 3) الحزم (pubspec.yaml)

عدّل قسم `dependencies` في `pubspec.yaml` ليصبح:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_local_notifications: ^17.2.3
  android_alarm_manager_plus: ^4.0.4
  shared_preferences: ^2.3.2
  permission_handler: ^11.3.1
  timezone: ^0.9.4
```
ثم:
```bash
flutter pub get
```
> إن ظهرت تعارضات إصدارات، استخدم `flutter pub upgrade --major-versions` ثم ثبّت الإصدارات الناتجة في الوثيقة.

---

## 4) إعدادات Android

### 4.1 رفع الحد الأدنى لإصدار SDK
في `android/app/build.gradle` (أو `build.gradle.kts`) داخل `defaultConfig`:
```gradle
minSdkVersion 23
targetSdkVersion 34
compileSdkVersion 34
multiDexEnabled true
```
> `flutter_local_notifications` يتطلب أحياناً تفعيل desugaring. أضف في `android/app/build.gradle`:
```gradle
android {
  compileOptions {
    coreLibraryDesugaringEnabled true
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
}
dependencies {
  coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

### 4.2 الأذونات والمكوّنات في AndroidManifest.xml
الملف: `android/app/src/main/AndroidManifest.xml`. أضف داخل `<manifest>` قبل `<application>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```
وداخل `<application>` أضف مكوّنات `android_alarm_manager_plus`:
```xml
<service
    android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
    android:permission="android.permission.BIND_JOB_SERVICE"
    android:exported="false"/>
<receiver
    android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
    android:exported="false"/>
<receiver
    android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
    android:exported="false">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
  </intent-filter>
</receiver>
```
وعلى الـ `<activity>` الرئيسي (MainActivity) أضف الخصائص اللازمة لإظهار شاشة المنبّه فوق شاشة القفل:
```xml
android:showWhenLocked="true"
android:turnScreenOn="true"
android:launchMode="singleInstance"
```

### 4.3 صوت المنبّه المخصّص (اختياري لكن مُوصى به)
ضع ملف صوت `alarm.mp3` في:
```
android/app/src/main/res/raw/alarm.mp3
```
ويُشار إليه في قناة الإشعار باسم `alarm` (بدون امتداد).

---

## 5) بنية الكود (lib/)

```
lib/
├── main.dart                 # نقطة الدخول + تهيئة الإشعارات والـ AlarmManager
├── models/
│   └── reminder.dart         # نموذج Reminder (تحويل JSON)
├── services/
│   ├── storage_service.dart  # حفظ/قراءة التنبيهات عبر shared_preferences
│   ├── notification_service.dart  # قنوات + إشعار fullScreenIntent
│   └── alarm_scheduler.dart  # جدولة/إلغاء عبر android_alarm_manager_plus
├── screens/
│   ├── home_screen.dart      # قائمة التنبيهات + مفتاح تشغيل لكل واحد + زر إضافة
│   ├── edit_reminder_screen.dart  # إدخال الاسم + التكرار بالدقائق
│   └── alarm_ring_screen.dart     # شاشة المنبّه الكاملة (إيقاف/غفوة)
```

### 5.1 النموذج — models/reminder.dart
```dart
class Reminder {
  final int id;            // معرّف فريد (يُستخدم أيضاً كـ alarmId)
  final String name;       // اسم التنبيه مثل "اشرب الماء"
  final int intervalMinutes; // التكرار بالدقائق
  final bool enabled;

  Reminder({
    required this.id,
    required this.name,
    required this.intervalMinutes,
    this.enabled = true,
  });

  Reminder copyWith({String? name, int? intervalMinutes, bool? enabled}) =>
      Reminder(
        id: id,
        name: name ?? this.name,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'intervalMinutes': intervalMinutes,
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        name: j['name'],
        intervalMinutes: j['intervalMinutes'],
        enabled: j['enabled'] ?? true,
      );
}
```

### 5.2 التخزين — services/storage_service.dart
- `Future<List<Reminder>> load()` — يقرأ مفتاح `reminders` (JSON list) من SharedPreferences.
- `Future<void> save(List<Reminder> items)` — يحفظها.
- `int nextId()` — يولّد معرّفاً تصاعدياً (يحفظ آخر id في مفتاح منفصل `last_id`).

### 5.3 خدمة الإشعارات — services/notification_service.dart
المتطلبات الدقيقة:
- تهيئة `FlutterLocalNotificationsPlugin` مع أيقونة `@mipmap/ic_launcher`.
- إنشاء قناة إشعار **alarm** عالية الأهمية:
  ```dart
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'alarm_channel',
    'تنبيهات المنبّه',
    description: 'تنبيهات متكررة بصوت المنبّه',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'), // أو الافتراضي إن لم يوجد ملف
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm, // مهم: يجعل الصوت من فئة المنبّه
  );
  ```
- دالة `showAlarmNotification(int id, String title)` تطلق إشعاراً بـ:
  ```dart
  AndroidNotificationDetails(
    'alarm_channel', 'تنبيهات المنبّه',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,        // ← يطلق شاشة المنبّه الكاملة
    ongoing: true,
    autoCancel: false,
    visibility: NotificationVisibility.public, // يظهر على القفل والساعة
    actions: [
      AndroidNotificationAction('DISMISS', 'إيقاف', showsUserInterface: true, cancelNotification: true),
      AndroidNotificationAction('SNOOZE', 'غفوة', showsUserInterface: true),
    ],
  )
  ```
- **ملاحظة Wear OS:** القناة عالية الأهمية + `visibility.public` + عدم استخدام `setLocalOnly(true)` يضمن انعكاس الإشعار والاهتزاز على الساعة المقترنة تلقائياً. لا حاجة لكود إضافي.
- طلب الأذونات وقت التشغيل:
  ```dart
  await Permission.notification.request();
  // SCHEDULE_EXACT_ALARM على Android 13+
  final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestExactAlarmsPermission();
  await androidPlugin?.requestFullScreenIntentPermission();
  ```

### 5.4 المجدوِل — services/alarm_scheduler.dart
- `AndroidAlarmManager.initialize()` يُستدعى في `main()`.
- جدولة تنبيه متكرر:
  ```dart
  await AndroidAlarmManager.periodic(
    Duration(minutes: reminder.intervalMinutes),
    reminder.id,                    // معرّف فريد للإلغاء لاحقاً
    alarmCallback,                  // دالة top-level أو static
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
  ```
- الإلغاء: `AndroidAlarmManager.cancel(reminder.id)`.
- **دالة الـ callback يجب أن تكون top-level أو static** ومُعلّمة بـ `@pragma('vm:entry-point')` لأنها تعمل في isolate منفصل:
  ```dart
  @pragma('vm:entry-point')
  void alarmCallback(int id) async {
    // إعادة تهيئة الإشعارات داخل الـ isolate
    await NotificationService.initInBackground();
    // قراءة اسم التنبيه من التخزين بالـ id
    final name = await StorageService.nameFor(id);
    await NotificationService.showAlarmNotification(id, name ?? 'تنبيه');
  }
  ```
  > مهم: داخل isolate الخلفية لا تتوفر حالة الـ UI، لذا أعد تهيئة كل خدمة تحتاجها (الإشعارات، SharedPreferences).

### 5.5 الواجهات (screens/)
- **home_screen.dart:**
  - `ListView` لكل التنبيهات: العنوان = الاسم، الوصف = "كل X دقيقة"، و`Switch` للتشغيل/الإيقاف (عند التبديل: جدولة أو إلغاء عبر `alarm_scheduler`).
  - زر `FloatingActionButton` يفتح `edit_reminder_screen`.
  - حذف بالسحب (Dismissible) → إلغاء الجدولة + حذف من التخزين.
- **edit_reminder_screen.dart:**
  - حقل نصّي للاسم.
  - حقل رقمي/شريط لاختيار التكرار بالدقائق (مع اقتراحات سريعة: 15/30/45/60).
  - زر حفظ → يولّد id، يحفظ، يجدول إن كان مفعّلاً، يرجع للرئيسية.
- **alarm_ring_screen.dart (شاشة المنبّه الكاملة):**
  - تُفتح عبر التعامل مع `onDidReceiveNotificationResponse` / الضغط على الإشعار، أو كنشاط منفصل من fullScreenIntent.
  - تعرض اسم التنبيه بخط كبير + وقت الآن.
  - زر **إيقاف** كبير: يلغي الإشعار ويوقف الصوت/الاهتزاز.
  - زر **غفوة** (اختياري): يعيد الجدولة بعد 5 دقائق عبر `AndroidAlarmManager.oneShot`.
  - استخدم `WidgetsFlutterBinding` + خصائص `showWhenLocked/turnScreenOn` المضافة في المانيفست.

### 5.6 main.dart — تسلسل التهيئة
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();        // قنوات + أذونات
  await AndroidAlarmManager.initialize();  // المجدوِل
  // إعادة جدولة كل التنبيهات المفعّلة عند بدء التطبيق (للأمان)
  final reminders = await StorageService().load();
  for (final r in reminders.where((r) => r.enabled)) {
    await AlarmScheduler.schedule(r);
  }
  runApp(const ReminderApp());
}
```

---

## 6) الاختبار قبل البناء

```bash
# على جهاز/محاكي متصل
flutter devices
flutter run
```
سيناريوهات يجب التحقق منها:
1. إنشاء تنبيه "اشرب الماء" كل 30 دقيقة وآخر "تحرّك" كل 45 دقيقة.
2. حلول الموعد → ظهور شاشة منبّه كاملة + صوت alarm + اهتزاز.
3. زر الإيقاف يُسكت التنبيه.
4. التنبيه يعمل والتطبيق مُغلق (اختبر بفاصل قصير مثل دقيقة واحدة مؤقتاً).
5. وجود ساعة Wear OS مقترنة → وصول الإشعار واهتزاز الساعة.
6. بعد إعادة تشغيل الهاتف → إعادة الجدولة تلقائياً.

> ملاحظة: `android_alarm_manager_plus periodic` لا يضمن الدقّة تحت دقيقة واحدة بسبب قيود Android Doze. للفواصل ≥15 دقيقة السلوك موثوق. لاختبار سريع استخدم `oneShot` بثوانٍ.

---

## 7) بناء الـ APK النهائي

### 7.1 (موصى به) توقيع release بمفتاح خاص حتى يُثبَّت على أي هاتف
```bash
keytool -genkey -v -keystore ~/reminder-key.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias reminder -storepass reminder123 -keypass reminder123 \
  -dname "CN=Reminder, OU=Dev, O=Tawseel, L=City, S=State, C=SA"
```
أنشئ `android/key.properties`:
```
storePassword=reminder123
keyPassword=reminder123
keyAlias=reminder
storeFile=/home/tw/reminder-key.jks
```
واربطه في `android/app/build.gradle` (قسم `signingConfigs` + `buildTypes.release`). 
> بديل أسرع للاختبار الشخصي: تخطّى التوقيع المخصّص واستخدم توقيع debug — يعمل عند النسخ المباشر لكنه أقل أماناً ولا يصلح للنشر.

### 7.2 البناء
```bash
flutter build apk --release
# أو APK مقسّم حسب المعمارية لحجم أصغر:
flutter build apk --release --split-per-abi
```
الناتج:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 7.3 النقل والتثبيت على الهاتف
- انسخ `app-release.apk` إلى الهاتف (USB / Bluetooth / سحابة).
- على الهاتف: فعّل "التثبيت من مصادر غير معروفة"، ثم افتح الملف وثبّته.
- أو عبر USB من الكمبيوتر: `adb install build/app/outputs/flutter-apk/app-release.apk`.

---

## 8) قائمة تحقّق نهائية (Definition of Done)

- [ ] `flutter doctor` يُظهر ✓ لـ Flutter و Android toolchain.
- [ ] يمكن إنشاء/تعديل/حذف تنبيهات متعددة باسم وتكرار بالدقائق.
- [ ] كل تنبيه له مفتاح تشغيل/إيقاف يعمل فعلياً (جدولة/إلغاء).
- [ ] عند الموعد: شاشة منبّه كاملة + صوت alarm عالٍ + اهتزاز.
- [ ] التنبيه يعمل والتطبيق مغلق وبعد إعادة تشغيل الهاتف.
- [ ] الإشعار ينعكس على ساعة Wear OS المقترنة مع اهتزاز.
- [ ] `flutter build apk --release` ينتج APK يُثبّت ويعمل مباشرة بعد النسخ.

---

## 9) مخاطر وملاحظات للمنفّذ

1. **مساحة القرص ~17GB فقط** — راقبها؛ احذف الكاش إن لزم (`flutter clean`, مسح ملفات /tmp).
2. **توافق إصدارات الحزم** قد يفرض رفع `compileSdk`/AGP/Gradle. إن فشل البناء بسبب AGP، حدّث `android/settings.gradle` (plugin versions) و`gradle-wrapper.properties`.
3. **fullScreenIntent على Android 14+** يتطلب إذن `USE_FULL_SCREEN_INTENT` الذي قد يُمنح تلقائياً لتطبيقات المنبّه أو يحتاج طلباً صريحاً — تعامل مع الحالتين.
4. **تحسين البطارية (Battery Optimization):** بعض الأجهزة (Xiaomi/Huawei/Samsung) تقتل المهام الخلفية. أضف زرّاً يطلب من المستخدم استثناء التطبيق عبر `permission_handler` → `Permission.ignoreBatteryOptimizations`.
5. **دالة الـ callback** يجب أن تكون top-level مع `@pragma('vm:entry-point')` وإلا لن تعمل في الـ release build (tree-shaking).
6. لا تحذف `PLAN.md` عند تشغيل `flutter create .`.

---

نهاية الخطة.
