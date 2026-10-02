# งานเงินเดือน กรมทางหลวง (Flutter Web)

หน้าเว็บรวมทางเข้าระบบงานเงินเดือน แทนหน้าแรกของ https://sal.doh.go.th/sal/
เมนูมีไอคอน ตรึงเมนูข้างได้แบบเดียวกับระบบ HTC

## เมนู

| เมนู | ปลายทาง |
|---|---|
| ใบรับรองภาษีกรมทางหลวง/สลิป | https://dbdoh.doh.go.th/yt/ |
| ใบรับรองภาษีตำรวจทางหลวง/สลิป | https://dbdoh.doh.go.th/tax/ |
| สลิป (พนักงานราชการส่วนกลาง) | http://dev.doh.go.th:8088/payroll |
| หักหนี้ (ข้าราชการ/ลูกจ้างประจำ) | https://dbdoh.doh.go.th/dp |
| ฌาปนกิจ — ดาวน์โหลดไฟล์ | https://sal.doh.go.th/Funeral/ |
| ฌาปนกิจ — ระบบฌาปนกิจสงเคราะห์ | http://hr-app:7777/DohHrFfd/common/Login |
| Smart Helpdesk | https://smhd.doh.go.th/login |

แก้ลิงก์ที่ `lib/config/menu_data.dart` ที่เดียว

## เมนูข้าง

- จอกว้างตั้งแต่ 900px: ตรึงไว้ข้างซ้ายเป็นค่าเริ่มต้น เหลือแต่ไอคอน กดปุ่มด้านบนหรือไอคอนกลุ่มแล้วขยายเห็นชื่อ
- ปุ่มหมุดตรึง/เลิกตรึง จำไว้ในเบราว์เซอร์ (`shared_preferences` key `sal_menu_pinned`)
- จอแคบ: เมนูเลื่อนออกจากด้านซ้าย

## คำสั่ง

```bash
flutter run -d chrome
flutter test
flutter analyze
flutter build web --release --no-wasm-dry-run          # ได้ไฟล์ที่ build/web
flutter build web --release --no-wasm-dry-run --base-href /sal2/   # ถ้าวางใต้ path ย่อย
```

## ข้อกำหนด

- ฟอนต์ไทย bundle มากับแอป (`assets/fonts`: Kanit หัวข้อ, Sarabun เนื้อหา — สัญญาอนุญาต OFL) ต้องระบุ `fontFamily` ให้ชัด
- ข้อความที่ผู้ใช้เห็นและคอมเมนต์ในโค้ดเป็นภาษาไทย
- ภาพประกอบหน้าแรกวาดด้วย widget (`lib/widgets/payroll_illustration.dart`) ไม่ใช้ไฟล์รูป
