import 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart'
    as impl;

/// บันทึกไฟล์ข้อความ: บนเว็บจะดาวน์โหลดไฟล์ บนมือถือ/เดสก์ท็อปจะเปิดหน้าแชร์
Future<void> saveTextFile(String filename, String content, String mimeType) =>
    impl.saveTextFile(filename, content, mimeType);
