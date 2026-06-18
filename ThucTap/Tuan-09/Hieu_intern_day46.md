# Báo cáo thực tập ngày 46- SSL Termination 

---
# 1. Tại sao SSL gắn liền với Luật pháp?
 
> **"Tại sao khách hàng BẮT BUỘC phải dùng HTTPS/SSL? Ai yêu cầu điều đó?"**
 
Câu trả lời không chỉ đến từ best practice kỹ thuật — mà đến từ **luật pháp, quy định quốc tế, và hợp đồng kinh doanh**. Khi một khách hàng của Nhân Hòa bị phạt vì thiếu SSL, hoặc trang web của họ bị Google hạ rank, hoặc tài khoản thanh toán của họ bị Visa/Mastercard thu hồi — thì nguồn gốc của những hậu quả đó đều có thể truy ngược về các tiêu chuẩn trình bày trong phần này.
 
> 🏢 **Áp dụng tại Nhân Hòa**
>
> - Nhân Hòa là đơn vị hosting — chúng ta không chỉ bán server/domain, chúng ta còn **tư vấn bảo mật** cho khách hàng.
> - Hiểu luật và tiêu chuẩn giúp kỹ thuật viên giải thích cho khách hàng *tại sao* họ cần SSL, không chỉ "click mua cert cho có".
> - Trong nhiều trường hợp, thiếu SSL không phải là tùy chọn — đó là **vi phạm hợp đồng hoặc vi phạm pháp luật**.
 
## 1.1 Ba luồng áp lực khiến SSL trở thành bắt buộc
 
SSL/TLS đã chuyển dịch từ "tùy chọn tốt" sang "bắt buộc" vì ba luồng áp lực đồng thời:
 
| Luồng áp lực | Ví dụ cụ thể | Hậu quả nếu không tuân thủ |
|---|---|---|
| **Pháp lý & Quy định** | PCI-DSS, GDPR, HIPAA, Nghị định 13/2023 | Phạt tiền, thu hồi giấy phép, kiện tụng |
| **Thị trường & Đối tác** | Visa/Mastercard yêu cầu PCI-DSS | Mất khả năng thanh toán thẻ tín dụng |
| **Công cụ & Nền tảng** | Google Chrome, Google Search | Cảnh báo "Not Secure", tụt hạng SEO |
 
---
 
# 2. PCI-DSS — Tiêu chuẩn thanh toán thẻ
 
## 2.1 PCI-DSS là gì?
 
**PCI-DSS** (Payment Card Industry Data Security Standard) là bộ tiêu chuẩn bảo mật do **PCI Security Standards Council** — liên minh của Visa, Mastercard, American Express, Discover, JCB — ban hành. Mọi tổ chức **lưu trữ, xử lý, hoặc truyền tải thông tin thẻ tín dụng** đều phải tuân thủ.
 
> ⚖️ **Quy định pháp lý**
>
> - Nếu website khách hàng có form nhập số thẻ tín dụng — họ **PHẢI** tuân thủ PCI-DSS, bất kể công ty nhỏ hay lớn.
> - Ngay cả khi dùng cổng thanh toán bên thứ 3 (VNPay, Momo, Stripe...) — khách hàng vẫn có thể bị yêu cầu tuân thủ một số điều khoản PCI-DSS.
> - Vi phạm PCI-DSS: phạt từ **5.000 USD đến 100.000 USD/tháng**, và có thể bị thu hồi quyền xử lý thẻ.
 
## 2.2 PCI-DSS và SSL/TLS
 
PCI-DSS v4.0 (bản hiện hành 2022) đề cập trực tiếp đến TLS ở nhiều yêu cầu. Quan trọng nhất:
 
| Yêu cầu PCI-DSS | Mô tả | Liên quan SSL/TLS |
|---|---|---|
| **Req 4.2.1** | Mã hóa dữ liệu thẻ khi truyền qua mạng công cộng | HTTPS bắt buộc cho mọi trang có dữ liệu thẻ |
| **Req 4.2.1.1** | Chỉ dùng protocol và cipher đáng tin cậy | Tắt TLS 1.0, TLS 1.1, SSL 3.0 — dùng TLS 1.2+ |
| **Req 4.2.1.2** | Danh sách các trusted certificate được quản lý | Phải có quy trình quản lý cert expiry |
| **Req 6.3.3** | Mọi phần mềm bảo vệ khỏi lỗ hổng đã biết | Vá lỗi OpenSSL/Nginx/Apache kịp thời |
| **Req 12.3.3** | Ciphers và protocols được review hàng năm | Audit SSL config định kỳ |
 
## 2.3 Mốc thời gian quan trọng của PCI-DSS về TLS
 
| Năm | Sự kiện | Hành động bắt buộc |
|---|---|---|
| 2015 | PCI-DSS 3.1 ra đời | Tắt SSL 3.0 và TLS 1.0 ngay lập tức |
| 30/06/2018 | Deadline PCI-DSS 3.2 | Hoàn tất tắt TLS 1.0 trên môi trường production |
| 30/06/2023 | PCI-DSS 4.0 chính thức | Tắt TLS 1.1, chỉ dùng TLS 1.2 và TLS 1.3 |
| 31/03/2024 | Các yêu cầu mới có hiệu lực | Review cipher hàng năm, certificate inventory |
| 31/12/2025 | PCI-DSS v3.2.1 hết hỗ trợ | Phải migrate lên PCI-DSS v4.0 hoàn toàn |
 
> ⚠️ **Cảnh báo**
>
> - TLS 1.0 và TLS 1.1 đã **BỊ CẤM hoàn toàn** trong PCI-DSS từ năm 2023.
> - Nếu server của khách hàng vẫn cho phép TLS 1.0/1.1 — họ đang **vi phạm PCI-DSS**.
> - Nhân Hòa có thể cung cấp dịch vụ SSL chuẩn PCI-DSS như một lợi thế cạnh tranh khi tư vấn khách hàng e-commerce.
 
## 2.4 Các mức độ tuân thủ PCI-DSS (Levels)
 
PCI-DSS chia doanh nghiệp thành 4 cấp độ dựa trên số giao dịch thẻ mỗi năm:
 
| Level | Giao dịch/năm | Yêu cầu kiểm tra | Ví dụ điển hình |
|---|---|---|---|
| **Level 1** | Trên 6 triệu | Audit hàng năm bởi QSA (chuyên gia độc lập) | Lazada, Shopee, ngân hàng lớn |
| **Level 2** | 1 – 6 triệu | Self-assessment (SAQ) + quét mạng hàng quý | Chuỗi bán lẻ vừa |
| **Level 3** | 20.000 – 1 triệu | Self-assessment (SAQ) | Shop online vừa |
| **Level 4** | Dưới 20.000 | Self-assessment (SAQ) | Cá nhân, shop nhỏ |
 
---
 
# 3. GDPR — Bảo vệ dữ liệu cá nhân Châu Âu
 
## 3.1 GDPR là gì?
 
**GDPR** (General Data Protection Regulation) là luật của Liên minh Châu Âu có hiệu lực từ **25/05/2018**. Điều quan trọng: GDPR có **hiệu lực ngoài lãnh thổ EU** — bất kỳ tổ chức nào trên thế giới thu thập hoặc xử lý dữ liệu cá nhân của công dân EU đều phải tuân thủ.
 
> ⚖️ **Quy định pháp lý**
>
> - Website của khách hàng Nhân Hòa có khách truy cập từ Châu Âu? GDPR có thể áp dụng.
> - Chỉ cần 1 người dùng EU điền form email trên website → đó là "xử lý dữ liệu cá nhân" theo GDPR.
> - Phạt GDPR cực nặng: lên tới **20 triệu EUR hoặc 4% doanh thu toàn cầu hàng năm** — lấy mức nào cao hơn.
 
## 3.2 GDPR và vai trò của SSL/TLS
 
GDPR không đề cập tên "SSL" hay "TLS" trực tiếp, nhưng **Điều 32** bắt buộc:
 
| Điều khoản GDPR | Nội dung | Cách SSL đáp ứng |
|---|---|---|
| **Điều 32(1)(a)** | Mã hóa dữ liệu cá nhân | HTTPS mã hóa toàn bộ dữ liệu trong quá trình truyền tải |
| **Điều 32(1)(b)** | Đảm bảo tính bí mật và toàn vẹn | TLS đảm bảo không ai nghe lén hoặc sửa đổi dữ liệu |
| **Điều 32(2)** | Xem xét rủi ro và áp dụng biện pháp phù hợp | Cấu hình SSL đúng chuẩn là "biện pháp kỹ thuật phù hợp" |
| **Điều 25** | Privacy by Design — bảo mật ngay từ thiết kế | SSL phải được bật từ đầu, không thêm sau |
| **Điều 83(4)** | Phạt vi phạm Điều 32 | 10 triệu EUR hoặc 2% doanh thu toàn cầu |
 
## 3.3 Checklist GDPR tối thiểu về mã hóa
 
- Mọi trang có form nhập dữ liệu cá nhân (tên, email, CMND...) **PHẢI** dùng HTTPS
- Cookie consent banner chính nó phải chạy trên HTTPS
- API endpoint nhận dữ liệu cá nhân **PHẢI** dùng TLS 1.2 hoặc TLS 1.3
- Không được dùng self-signed cert cho website public (thiếu trust chain)
- Cert phải có hiệu lực — cert hết hạn là "thiếu biện pháp kỹ thuật phù hợp"
- Hệ thống log không được ghi lại dữ liệu nhạy cảm dưới dạng plaintext
## 3.4 Một số vụ phạt GDPR điển hình
 
| Công ty | Năm | Lý do liên quan bảo mật | Mức phạt |
|---|---|---|---|
| **British Airways** | 2020 | Breach để lọt dữ liệu 500.000 khách hàng — thiếu mã hóa đủ mạnh | ~22 triệu EUR |
| **Marriott International** | 2020 | Thiếu kiểm soát mã hóa dữ liệu trong quá trình M&A | ~18 triệu EUR |
| **H&M (Đức)** | 2020 | Lưu dữ liệu nhân viên không được bảo vệ đủ chuẩn | 35,3 triệu EUR |
| **Meta (Ireland)** | 2023 | Truyền dữ liệu EU sang Mỹ không đủ cơ chế bảo vệ | **1,2 tỷ EUR** |
 
---
 
# 4. HIPAA — Tiêu chuẩn y tế Hoa Kỳ
 
## 4.1 HIPAA là gì?
 
**HIPAA** (Health Insurance Portability and Accountability Act) là luật liên bang Hoa Kỳ ban hành năm 1996, điều chỉnh bảo vệ thông tin sức khỏe cá nhân — gọi là **PHI (Protected Health Information)**. Bất kỳ tổ chức nào xử lý PHI của bệnh nhân Mỹ đều phải tuân thủ — kể cả vendor phần mềm, hosting provider phục vụ khách hàng trong ngành y tế Mỹ.
 
> ⚖️ **Quy định pháp lý**
>
> - **PHI bao gồm:** tên, ngày sinh, địa chỉ, số BHYT, hồ sơ bệnh án, kết quả xét nghiệm, hình ảnh y tế...
> - Nếu khách hàng Nhân Hòa cung cấp phần mềm phòng khám cho thị trường Mỹ — HIPAA áp dụng.
> - HIPAA cũng áp dụng cho **Business Associates**: nếu Nhân Hòa host dữ liệu y tế cho công ty Mỹ, cần ký BAA (Business Associate Agreement).
 
## 4.2 HIPAA Security Rule và SSL/TLS
 
| Yêu cầu HIPAA | Mô tả | SSL/TLS đáp ứng thế nào |
|---|---|---|
| **§164.312(e)(1)** | Truyền tải PHI qua mạng phải được bảo vệ | HTTPS/TLS mã hóa PHI trong transit |
| **§164.312(e)(2)(ii)** | Mã hóa và giải mã PHI khi truyền tải | TLS 1.2+ với cipher mạnh (AES-GCM) |
| **§164.312(a)(2)(iv)** | Kiểm soát mã hóa/giải mã dữ liệu | Quản lý certificate và private key nghiêm ngặt |
| **§164.306(a)(1)** | Bảo vệ khỏi các mối đe dọa hợp lý | Tắt TLS 1.0/1.1, vá lỗi SSL kịp thời |
 
## 4.3 Mức phạt HIPAA
 
| Mức vi phạm | Mô tả | Phạt/vi phạm | Phạt tối đa/năm |
|---|---|---|---|
| **Tier 1** | Không biết — đã thực hiện biện pháp hợp lý | 100 – 50.000 USD | 25.000 USD |
| **Tier 2** | Biết nhưng thiếu bất cẩn nghiêm trọng | 1.000 – 50.000 USD | 100.000 USD |
| **Tier 3** | Bất cẩn nghiêm trọng — đã khắc phục | 10.000 – 50.000 USD | 250.000 USD |
| **Tier 4** | Bất cẩn nghiêm trọng — không khắc phục | 50.000 USD | **1.900.000 USD** |
 
---
 
# 5. ISO/IEC 27001 — Quản lý an toàn thông tin
 
## 5.1 ISO 27001 là gì?
 
**ISO/IEC 27001** là tiêu chuẩn quốc tế về **Hệ thống Quản lý An toàn Thông tin (ISMS)** do ISO và IEC ban hành. Phiên bản mới nhất: **ISO 27001:2022**. Khác với PCI-DSS hay HIPAA — ISO 27001 là tiêu chuẩn **toàn diện**, bao phủ toàn bộ hệ thống quản lý bảo mật: không chỉ kỹ thuật mà còn quy trình, con người, vật lý.
 
> 🏢 **Áp dụng tại Nhân Hòa**
>
> - Chứng chỉ ISO 27001 là **lợi thế cạnh tranh lớn** — nhiều khách hàng doanh nghiệp yêu cầu vendor phải có ISO 27001.
> - Nhân Hòa hướng đến ISO 27001 certification sẽ giúp tăng uy tín với khách hàng enterprise và chính phủ.
> - ISO 27001 không bắt buộc theo luật — nhưng nhiều hợp đồng B2B và đấu thầu yêu cầu chứng chỉ này.
 
## 5.2 SSL trong ISO 27001 Annex A
 
ISO 27001:2022 có 93 controls trong Annex A. Các control liên quan trực tiếp đến SSL/TLS:
 
| Control | Tên | Yêu cầu liên quan SSL |
|---|---|---|
| **A.8.24** | Sử dụng mật mã | Chính sách mã hóa — xác định loại cert, độ dài key, cipher suite được phép dùng |
| **A.8.20** | Network Security | Bảo vệ thông tin trong mạng — HTTPS cho tất cả giao tiếp nhạy cảm |
| **A.8.21** | Security of network services | Cơ chế xác thực và mã hóa khi dùng dịch vụ mạng (TLS cho API, email, web) |
| **A.8.26** | Application security requirements | Mã hóa dữ liệu khi truyền tải — requirement cho developer |
| **A.5.14** | Information transfer | Chính sách bảo vệ thông tin khi chuyển giao — HTTPS, SFTP, không email plaintext |
| **A.8.9** | Configuration management | Cấu hình bảo mật baseline — SSL config chuẩn được document và áp dụng nhất quán |
 
## 5.3 Quy trình ISMS và SSL
 
ISO 27001 yêu cầu SSL không chỉ được cài đặt, mà còn phải được **quản lý trong vòng đời**:
 
- **Chính sách mật mã (Cryptography Policy):** document loại cert được dùng, độ dài key tối thiểu, cipher suite được phép
- **Quản lý vòng đời certificate:** inventory cert, theo dõi ngày hết hạn, quy trình gia hạn
- **Quản lý private key:** bảo mật, backup, hủy key khi không còn sử dụng
- **Review định kỳ:** kiểm tra cipher suite, cập nhật theo lỗ hổng mới, audit log
- **Incident response:** quy trình xử lý khi cert hết hạn hoặc private key bị lộ
---
 
# 6. Quy định Việt Nam
 
## 6.1 Tổng quan khung pháp lý Việt Nam
 
Việt Nam đã xây dựng khung pháp lý tương đối đầy đủ về an toàn thông tin. Các văn bản pháp luật chính:
 
| Văn bản | Năm | Nội dung chính |
|---|---|---|
| **Luật An toàn thông tin mạng** | 2015 (sửa đổi 2022) | Khung tổng thể bảo vệ thông tin; phân loại thông tin; trách nhiệm tổ chức cung cấp dịch vụ |
| **Luật An ninh mạng** | 2018 | Bảo vệ không gian mạng; yêu cầu đặt máy chủ tại Việt Nam; xử lý nội dung vi phạm |
| **Nghị định 13/2023/NĐ-CP** | 2023 | Bảo vệ dữ liệu cá nhân — GDPR phiên bản Việt Nam |
| **Nghị định 85/2016/NĐ-CP** | 2016 | Điều kiện cung cấp dịch vụ an toàn thông tin mạng |
| **Thông tư 03/2017/TT-BTTTT** | 2017 | Quy định chứng thư số và dịch vụ chứng thực chữ ký số |
| **TCVN ISO/IEC 27001:2020** | 2020 | Bản dịch ISO 27001 — tiêu chuẩn Việt Nam |
 
## 6.2 Nghị định 13/2023/NĐ-CP — Bảo vệ dữ liệu cá nhân
 
Có hiệu lực từ **01/07/2023**, Nghị định 13 là văn bản quan trọng nhất ảnh hưởng trực tiếp đến khách hàng Nhân Hòa. Được ví như **"GDPR của Việt Nam"**, nghị định này yêu cầu:
 
- Dữ liệu cá nhân phải được bảo vệ trong quá trình thu thập, lưu trữ và truyền tải
- Tổ chức phải áp dụng các biện pháp kỹ thuật và quản lý để bảo vệ dữ liệu
- Phải có **cơ chế mã hóa phù hợp** — HTTPS/TLS là biện pháp mã hóa truyền tải tối thiểu
- Phải có quy trình thông báo vi phạm trong vòng **72 giờ**
- Phạt vi phạm: cảnh cáo, phạt tiền từ **50 triệu đến 100 triệu VNĐ**, hoặc truy cứu hình sự
> 🏢 **Áp dụng tại Nhân Hòa**
>
> - Mọi website Việt Nam có form thu thập email, số điện thoại, CMND của người dùng đều phải tuân thủ Nghị định 13.
> - Thiếu HTTPS trên trang thu thập thông tin cá nhân có thể được coi là vi phạm nghị định này.
> - Nhân Hòa có thể tư vấn khách hàng về compliance Nghị định 13 khi họ hỏi về SSL — đây là **giá trị gia tăng**.
 
## 6.3 Thông tư 03/2017 — Chứng thư số tại Việt Nam
 
Việt Nam có hệ thống chứng thư số riêng do Bộ TT&TT quản lý:
 
| Tổ chức | Vai trò | Liên quan đến SSL |
|---|---|---|
| **NEAC** (Cục An toàn thông tin) | Cơ quan quản lý nhà nước về ATTT | Ban hành tiêu chuẩn, cấp phép CA hoạt động tại VN |
| **VNPT-CA** | Root CA được nhà nước cấp phép | Cấp chữ ký số cho tổ chức/cá nhân VN (eSign) |
| **Viettel-CA** | Root CA được nhà nước cấp phép | Cấp chữ ký số cho doanh nghiệp VN |
| **BKAV-CA** | Root CA được nhà nước cấp phép | Chứng thư số cho doanh nghiệp VN |
| **Let's Encrypt, ZeroSSL...** | International CA — không cần phép VN | SSL website — không phải chữ ký số theo luật VN |
 
> 💡 **Lưu ý quan trọng**
>
> **Phân biệt quan trọng:** SSL certificate (bảo mật kết nối web) **KHÁC** với chữ ký số (eSign, ký văn bản pháp lý).
>
> - Let's Encrypt và ZeroSSL **hợp lệ hoàn toàn** cho SSL website tại Việt Nam — không cần chứng nhận của Bộ TT&TT.
> - Khi khách hàng hỏi "cần mua cert VN hay quốc tế?" — cho website SSL thông thường: Let's Encrypt hoặc ZeroSSL đều OK.
 
---
 
# 7. Google, trình duyệt và "luật" thị trường
 
## 7.1 Google Chrome và HTTPS
 
Chrome — chiếm ~65% thị phần trình duyệt — đã thực hiện một chuỗi thay đổi buộc website phải dùng HTTPS. Đây là "luật" của thị trường, không phải nhà nước, nhưng hậu quả còn **ngay lập tức** hơn:
 
| Năm | Chrome version | Thay đổi |
|---|---|---|
| 2014 | Chrome 37 | Bắt đầu đánh dấu HTTP với biểu tượng ổ khóa gạch chéo |
| 2017 | Chrome 62 | Hiển thị "Not Secure" cho tất cả form HTTP (input field) |
| 2018 | Chrome 68 | Hiển thị **"Not Secure" cho TẤT CẢ website HTTP** |
| 2020 | Chrome 84 | Chặn download từ HTTPS trang sang HTTP (mixed content) |
| 2021 | Chrome 90 | HTTP redirect tự động lên HTTPS cho domain đã từng dùng HTTPS |
| 2024 | Chrome 117+ | Cảnh báo mạnh hơn, HTTPS-First Mode mặc định một phần |
 
## 7.2 Google Search và SEO
 
Google chính thức xác nhận HTTPS là một **ranking signal** từ tháng 8/2014. Tác động thực tế:
 
- Website HTTPS được ưu tiên hơn HTTP trong kết quả tìm kiếm — cùng điều kiện khác
- Tốc độ tải trang qua HTTP/2 (chỉ có trên HTTPS) ảnh hưởng **Core Web Vitals** — yếu tố ranking
- Google Search Console đánh dấu warning cho website HTTP
- Google Ads có thể reject landing page không dùng HTTPS
> 🏢 **Áp dụng tại Nhân Hòa**
>
> Với khách hàng chạy website bán hàng, dịch vụ — **thiếu SSL = mất khách hàng từ Google**. Script giải thích cho khách hàng không chuyên:
> *"Không có SSL → Google dán nhãn Not Secure → khách bỏ trang → mất doanh thu."*
 
## 7.3 Certificate Transparency (CT) — Sổ đăng bộ cert toàn cầu
 
**Certificate Transparency** là yêu cầu của Google: mọi cert do CA cấp từ 30/04/2018 trở đi **phải được ghi vào CT Log** — sổ đăng bộ công khai. Chrome sẽ từ chối cert không có SCT (Signed Certificate Timestamp). Mục đích: phát hiện cert giả mạo.
 
- Mọi CA đáng tin cậy (Let's Encrypt, DigiCert, ZeroSSL...) đều tự động submit cert vào CT Log
- Self-signed cert **KHÔNG** có CT Log → Chrome cảnh báo, nhưng vẫn cho phép tiếp tục (add exception)
- CT Log có thể dùng để monitor domain: ai đó đang cấp cert cho domain của bạn mà bạn không biết?
---
 
# 8. Vai trò SSL trong tiêu chuẩn bảo mật doanh nghiệp
 
## 8.1 Defense in Depth — Bảo mật theo chiều sâu
 
SSL/TLS là một tầng trong mô hình bảo mật nhiều lớp (Defense in Depth). Doanh nghiệp không thể chỉ dựa vào SSL — nhưng cũng không thể thiếu SSL:
 
```
╔══════════════════════════════════════════════════════╗
║          TẦNG BẢO MẬT (NGOÀI → TRONG)               ║
╠══════════════════════════════════════════════════════╣
║  Tầng 7 - Ứng dụng   : WAF, Input validation,       ║
║                         Anti-XSS, Anti-SQLi          ║
║  Tầng 6 - SSL/TLS ★  : Mã hóa truyền tải,           ║
║                         Xác thực server,             ║
║                         Toàn vẹn dữ liệu             ║
║  Tầng 5 - Mạng        : Firewall, IDS/IPS,           ║
║                         VPN, Network segmentation    ║
║  Tầng 4 - Server      : OS hardening, Patch mgmt,    ║
║                         Least privilege              ║
║  Tầng 3 - Dữ liệu     : Mã hóa at-rest,             ║
║                         Database encryption          ║
║  Tầng 2 - Nhân sự     : Security awareness,          ║
║                         Access control, MFA          ║
║  Tầng 1 - Vật lý      : Datacenter security,         ║
║                         Physical access control      ║
╚══════════════════════════════════════════════════════╝
```
 
> 🔑 **Yếu tố then chốt**
>
> - SSL/TLS bảo vệ **"data in transit"** — dữ liệu đang di chuyển trên mạng.
> - SSL **không** bảo vệ dữ liệu đã lưu trên server (cần database encryption cho "data at rest").
> - SSL **không** ngăn được tấn công XSS, SQLi — các tầng khác đảm nhiệm điều đó.
 
## 8.2 PKI — Public Key Infrastructure trong doanh nghiệp
 
Doanh nghiệp lớn thường xây dựng **PKI nội bộ** thay vì mua cert từ public CA cho mọi thứ:
 
| Thành phần PKI | Vai trò | Ví dụ tại doanh nghiệp |
|---|---|---|
| **Root CA** | CA gốc, tự ký, không bao giờ online (offline) | Lưu trong HSM, chỉ dùng để ký Intermediate CA |
| **Intermediate CA** | CA trung gian, online, ký cert thực tế | Internal CA ký cert cho intranet, VPN, email |
| **End-entity cert** | Cert của server/user cụ thể | `web.internal.company.com`, `john.doe@company.com` |
| **CRL/OCSP** | Danh sách cert bị thu hồi | Server kiểm tra cert chưa bị revoke trước khi tin tưởng |
| **HSM** | Hardware Security Module — bảo vệ private key CA | Private key CA không bao giờ rời thiết bị phần cứng |
 
## 8.3 Certificate Lifecycle Management
 
Quản lý vòng đời certificate là điểm yếu thường bị **bỏ qua nhất** trong doanh nghiệp. Hậu quả: cert hết hạn gây downtime production.
 
```
Yêu cầu (Request)
      │ Xác định nhu cầu cert: loại, domain, thời hạn
      ↓
Cấp phát (Issue)
      │ Tạo CSR, verify domain, nhận cert từ CA
      ↓
Triển khai (Deploy)
      │ Cài cert lên server, verify hoạt động
      ↓
Giám sát (Monitor)
      │ Theo dõi ngày hết hạn, cảnh báo sớm 30-60 ngày
      ↓
Gia hạn (Renew)
      │ Gia hạn trước khi hết hạn
      ↓
Thu hồi (Revoke)
        Khi key bị lộ hoặc server decommission
```
 
> 💡 **Lưu ý quan trọng**
>
> - Thực tế: **30–40% sự cố SSL** trong doanh nghiệp là do cert hết hạn không được gia hạn kịp.
> - Giải pháp: Let's Encrypt + Certbot auto-renew **loại bỏ hoàn toàn** rủi ro này cho cert 90 ngày.
> - Nhân Hòa nên recommend khách hàng dùng auto-renew thay vì nhắc họ mua gia hạn thủ công — vừa tốt cho khách, vừa giảm support ticket.
 
---
 
# 9. Bảng so sánh tổng hợp các tiêu chuẩn
 
| Tiêu chí | PCI-DSS v4.0 | GDPR | HIPAA | ISO 27001 | NĐ 13/2023 VN |
|---|---|---|---|---|---|
| **Phạm vi địa lý** | Toàn cầu (ai xử lý thẻ) | Toàn cầu (dữ liệu EU) | Mỹ (dữ liệu y tế) | Toàn cầu (tự nguyện) | Việt Nam |
| **Bắt buộc pháp lý** | Theo hợp đồng Visa/MC | Luật EU + ngoài lãnh thổ | Luật liên bang Mỹ | Tự nguyện (hoặc hợp đồng) | Luật Việt Nam |
| **TLS tối thiểu** | TLS 1.2+ bắt buộc | Mã hóa phù hợp (TLS ngầm định) | TLS 1.2+ khuyến nghị | Theo Cryptography Policy | Mã hóa đủ mạnh |
| **Cert hết hạn** | Không được phép | Vi phạm Điều 32 | Vi phạm §164.312 | Lỗi quản lý cert | Thiếu biện pháp kỹ thuật |
| **Audit/Review** | Hàng năm bắt buộc | Khi có sự cố/thay đổi | Audit định kỳ | Hàng năm (Internal Audit) | Khi cơ quan yêu cầu |
| **Phạt tối đa** | 100.000 USD/tháng | 20 triệu EUR hoặc 4% doanh thu | 1,9 triệu USD/năm | Mất chứng chỉ | 100 triệu VNĐ hoặc hình sự |
| **Khách hàng NH liên quan** | Website e-commerce | Website có user EU | Phần mềm y tế cho Mỹ | Doanh nghiệp muốn chứng chỉ | Mọi website VN có form |
 
---
 
# 10. Áp dụng tại Nhân Hòa
 
## 10.1 Phân loại khách hàng theo mức độ compliance
 
| Loại khách hàng | Tiêu chuẩn áp dụng | SSL tối thiểu cần | Tư vấn thêm |
|---|---|---|---|
| Website giới thiệu doanh nghiệp (VN) | NĐ 13, Google | Let's Encrypt miễn phí | HSTS, auto-renew |
| Shop bán hàng online VN (không tự xử lý thẻ) | NĐ 13, Google | DV SSL Let's Encrypt | Redirect HTTP→HTTPS, SPF/DKIM |
| E-commerce có cổng thanh toán | PCI-DSS Level 3–4, NĐ 13 | OV SSL hoặc EV SSL | PCI-DSS SAQ, scan hàng quý |
| Ngân hàng, fintech VN | PCI-DSS, NĐ 13, Thông tư NHNN | EV SSL bắt buộc | QSA audit, WAF, pentest |
| Phần mềm y tế cho thị trường Mỹ | HIPAA + ISO 27001 | TLS 1.2+ minimum | BAA, encryption at-rest, audit log |
| Doanh nghiệp có khách EU | GDPR + NĐ 13 | TLS 1.2+ cho mọi endpoint | Privacy policy, cookie consent, DPO |
| Doanh nghiệp muốn chứng chỉ ISO 27001 | ISO 27001:2022 | Cryptography Policy | ISMS setup, internal audit |
 
## 10.2 Checklist SSL compliance cho kỹ thuật viên Nhân Hòa
 
Khi setup SSL cho khách hàng, kỹ thuật viên nên kiểm tra đủ các mục sau:
 
| STT | Hạng mục kiểm tra | Lý do / Tiêu chuẩn liên quan | Đạt |
|---|---|---|---|
| 1 | TLS 1.0 và TLS 1.1 đã bị tắt | PCI-DSS bắt buộc từ 2023 | ☐ |
| 2 | TLS 1.2 và TLS 1.3 đang hoạt động | PCI-DSS, HIPAA, GDPR | ☐ |
| 3 | Cipher suite không có NULL, RC4, DES, 3DES | PCI-DSS Req 4.2.1.1 | ☐ |
| 4 | Redirect HTTP → HTTPS (301) | GDPR, NĐ 13, Google ranking | ☐ |
| 5 | HSTS header được set | Bảo vệ chống downgrade attack | ☐ |
| 6 | Certificate chain đầy đủ (không thiếu intermediate) | Compatibility, trust chain | ☐ |
| 7 | SAN trong certificate khớp với domain | RFC, Chrome requirement | ☐ |
| 8 | Cert có hiệu lực ít nhất 30 ngày | Tránh downtime, PCI-DSS | ☐ |
| 9 | Auto-renew đã được cấu hình | Best practice, tránh cert expire | ☐ |
| 10 | OCSP Stapling bật (với cert có OCSP) | Performance, PCI-DSS | ☐ |
| 11 | Không có mixed content (HTTP trên HTTPS page) | GDPR, browser security | ☐ |
| 12 | Private key permission 600 (chỉ root đọc được) | ISO 27001, key management | ☐ |
 
## 10.3 Các tình huống tư vấn thực tế
 
### Tình huống 1: Khách hàng hỏi "Tôi có cần SSL không?"
 
Câu trả lời đúng: **"Không có SSL là vi phạm"**, không phải chỉ "không tốt". Cụ thể:
 
- Nếu website thu thập email/SĐT → vi phạm **Nghị định 13/2023**
- Nếu có khách truy cập từ EU → vi phạm **GDPR**
- Nếu xử lý thanh toán thẻ → vi phạm **PCI-DSS**
- Nếu không thuộc ba trường hợp trên → Google dán nhãn **"Not Secure"**, mất khách hàng
---
 
### Tình huống 2: Khách hàng hỏi "Let's Encrypt miễn phí dùng được không?"
 
Câu trả lời: **Phụ thuộc vào nhu cầu.**
 
| Tiêu chí | Let's Encrypt (DV) | Cert trả phí OV/EV |
|---|---|---|
| Mức độ xác thực | Chỉ verify domain | OV: verify tổ chức; EV: verify pháp lý |
| Độ mạnh mã hóa | **Giống nhau** — TLS giống nhau | **Giống nhau** — TLS giống nhau |
| Hiển thị browser | Ổ khóa xanh | OV: Ổ khóa xanh; EV: tên tổ chức (Chrome đã bỏ) |
| PCI-DSS | Được phép (DV đủ điều kiện) | OV/EV được ưa dùng hơn cho banking |
| Thời hạn | 90 ngày (auto-renew) | 1–2 năm |
| Chi phí | Miễn phí | 500.000 VNĐ đến vài triệu/năm |
| Phù hợp | Blog, website, startup, SME | Ngân hàng, fintech, e-commerce lớn |
 
---
 
### Tình huống 3: Khách hàng bị cert hết hạn — xử lý thế nào?
 
1. **Gia hạn ngay lập tức** — mọi phút downtime là vi phạm PCI-DSS và GDPR nếu đang có giao dịch
2. **Sau khi fix:** thiết lập monitoring cert expiry (Prometheus, cron job `check-certs.sh`)
3. **Đề xuất migrate** sang Let's Encrypt với auto-renew để không tái phát
4. **Document lại:** ghi nhận incident, nguyên nhân, biện pháp phòng ngừa (yêu cầu ISO 27001)
---
 
