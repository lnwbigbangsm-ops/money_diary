# บันทึกรายรับรายจ่าย (Flutter)

แอปบันทึกรายรับ/รายจ่ายในแต่ละวัน เพิ่มเมนูหมวดหมู่เองได้ และคำนวณยอดให้อัตโนมัติ
ข้อมูลเก็บไว้ในเครื่อง (shared_preferences) ใช้ได้โดยไม่ต้องต่ออินเทอร์เน็ต

## ความสามารถ
- **รายวัน**: เลื่อนดูทีละวันหรือเลือกจากปฏิทิน แสดงรายรับ รายจ่าย และคงเหลือของวันนั้น
  พร้อม **ยอดเงินสะสมทั้งหมด** ถึงวันนั้น แตะรายการเพื่อแก้ไข ปัดซ้ายเพื่อลบ (มีปุ่มเลิกทำ)
- **ช่องจำนวนเงินคิดเลขได้**: พิมพ์ `45+30*2` หรือกดปุ่ม + − × ÷ ( ) = แอปคำนวณให้ทันที
- **เมนู/หมวด**: เพิ่ม แก้ไข ลบ เลือกไอคอนและสี ลากเรียงลำดับได้ แยกรายรับและรายจ่าย
  (เพิ่มหมวดใหม่จากหน้าบันทึกรายการได้เลย ถ้าลบหมวดที่มีรายการ รายการจะย้ายไปหมวด "อื่นๆ")
- **รายเดือน**: รายรับ รายจ่าย คงเหลือ อัตราการออม **ปฏิทินรายเดือน** (สีเข้มตามยอดจ่าย แตะวันเพื่อดูรายการ)
  รายจ่ายเฉลี่ยต่อวัน วันที่จ่ายมากที่สุด รายจ่ายก้อนใหญ่สุด และสัดส่วนแยกตามหมวด (%)
- **ส่งออกรายงานรายเดือน**: ไฟล์ .html (สรุปยอด เทียบเดือนก่อน แยกหมวด เรื่องสำคัญ ตารางรายวัน รายการทั้งหมด
  เปิดในเบราว์เซอร์แล้วสั่งพิมพ์เป็น PDF ได้), ไฟล์ .csv สำหรับ Excel และคัดลอกข้อมูล
- **หน้าหลัก**: ภาพรวมเดือนนี้ ปุ่มจดรายจ่าย/รายรับด่วน เมนูหลัก และรายการล่าสุด
- **สำรอง / กู้คืนข้อมูล**: บันทึกทุกอย่างเป็นไฟล์ .json และกู้คืนได้ 2 แบบ
  (รวมกับข้อมูลเดิม หรือแทนที่ทั้งหมด) ใช้ย้ายข้อมูลข้ามเครื่องหรือกันข้อมูลหาย
- **เตือนก่อนทิ้งข้อมูล**: ถ้ากรอกฟอร์มไว้แล้วจะออก (แตะนอกฟอร์ม/ปุ่มปิด/ปุ่มย้อนกลับ)
  แอปจะถามก่อน: "ไม่บันทึก" = ออกเลย, "บันทึกก่อน" = อยู่หน้าเดิมให้กดบันทึก

## วิธีรัน
1. ติดตั้ง Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. โหลดโค้ดและติดตั้งแพ็กเกจ:
   ```
   git clone https://github.com/lnwbigbangsm-ops/money_diary.git
   cd money_diary
   flutter pub get
   ```
3. รันและเทสต์:
   ```
   flutter run -d chrome    # หรือ -d windows / อุปกรณ์ Android
   flutter test             # รันเทสต์
   ```
   - รันบน Windows ต้องติดตั้ง Visual Studio (Desktop development with C++) และเปิด **Developer Mode** ของ Windows
   - `flutter run -d chrome` ใช้โปรไฟล์ Chrome ชั่วคราว ข้อมูลที่บันทึกอาจหายเมื่อรันใหม่
4. เปิดแบบเว็บถาวร (ข้อมูลอยู่ใน Chrome ปกติของคุณ):
   ```
   flutter build web --release
   cd build/web && python -m http.server 8686
   ```
   แล้วเปิด http://localhost:8686

## การเก็บข้อมูล
- ใช้ `shared_preferences` เก็บเป็น JSON 2 คีย์: `categories_v1` (หมวด) และ `entries_v1` (รายการ)
- ข้อมูลอยู่ในเครื่องผู้ใช้เท่านั้น ไม่มีเซิร์ฟเวอร์ และแอป Android ไม่ขอสิทธิ์อินเทอร์เน็ต
- ถ้าข้อมูลในเครื่องเสีย แอปจะข้ามส่วนที่เสียและเปิดได้ตามปกติ
  โดยเก็บข้อมูลดิบไว้ที่คีย์ `<คีย์>_corrupt_<เวลา>` เพื่อกู้ภายหลัง

## Build สำหรับ Google Play
1. ติดตั้ง Android Studio (มี Android SDK และ Java มาด้วย) แล้วรัน `flutter doctor --android-licenses`
2. สร้างคีย์สำหรับเซ็นแอป (ทำครั้งเดียว):
   ```
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. สร้างไฟล์ `android/key.properties`:
   ```
   storePassword=<รหัส keystore>
   keyPassword=<รหัสคีย์>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
4. เพิ่มเลขเวอร์ชันใน `pubspec.yaml` ทุกครั้งที่อัปใหม่ (เช่น `1.0.0+2`) แล้ว build:
   ```
   flutter build appbundle
   ```
   ได้ไฟล์ที่ `build/app/outputs/bundle/release/app-release.aab`

> ⚠️ `upload-keystore.jks` และ `key.properties` ถูกตั้งไม่ให้ขึ้น git แล้ว **ห้ามแชร์** และต้องสำรองเก็บไว้ที่อื่นด้วย
> ถ้าทำหายจะอัปเดตแอปบน Play Store ไม่ได้ (ถ้าไม่มี `key.properties` แอปจะเซ็นด้วยคีย์ debug ซึ่ง Play ไม่รับ)

## โครงสร้าง
```
lib/
  main.dart                  แอปและแถบเมนูด้านล่าง
  models.dart                Category, Entry, Totals
  store.dart                 เก็บ/โหลดข้อมูล และฟังก์ชันคำนวณ
  utils.dart                 รูปแบบเงิน วันที่ไทย ไอคอน และตัวคำนวณสูตร
  theme.dart                 ธีมสว่าง/มืด
  screens/home_screen.dart        หน้าหลัก
  screens/daily_screen.dart       หน้ารายวัน
  screens/summary_screen.dart     หน้าสรุปรายเดือน
  screens/categories_screen.dart  หน้าจัดการเมนู/หมวด
  widgets/entry_form.dart         ฟอร์มเพิ่ม/แก้ไขรายการ (มีปุ่มคิดเลข)
  widgets/category_form.dart      ฟอร์มเพิ่ม/แก้ไขหมวด
  widgets/common.dart             วิดเจ็ตที่ใช้ร่วมกัน
  widgets/backup_sheet.dart       เมนูสำรอง/กู้คืนข้อมูล
  widgets/export_sheet.dart       เมนูส่งออกรายงาน
  widgets/month_calendar.dart     ปฏิทินรายเดือน
  services/file_saver*.dart       บันทึก/แชร์ไฟล์ (แยกเว็บกับมือถือ/เดสก์ท็อป)
  backup.dart                     สร้าง/อ่านไฟล์สำรอง
  report.dart                     รายงานรายเดือน (HTML)
```
