# Báo cáo thực tập ngày 45 - SSL Termination
---

## 7.5 Công Cụ Kiểm Tra SSL
Trong vận hành thực tế, kỹ thuật viên cần một công cụ **tổng hợp toàn bộ** các tiêu chí (chain, cipher, protocol, HSTS, OCSP...) thành một bản đánh giá duy nhất, dễ trình bày cho khách hàng hoặc dùng để audit định kỳ. Đây là vai trò của SSL Labs và các SSL Checker.
 
## SSL Labs
 
**SSL Labs** là công cụ kiểm tra SSL/TLS được công nhận rộng rãi nhất trong ngành, chấm điểm cấu hình SSL của một domain theo thang hạng chữ.
### SSL Rating — thang điểm A+, A, B, C, F
 
| Hạng | Ý nghĩa chung |
|---|---|
| **A+** | Cấu hình xuất sắc: TLS 1.2/1.3 only, cipher mạnh, HSTS bật đúng, chain đầy đủ, OCSP Stapling hoạt động |
| **A** | Tốt, đạt chuẩn bảo mật hiện hành nhưng thiếu một số điểm cộng (ví dụ chưa bật HSTS) |
| **B** | Còn hỗ trợ giao thức/cipher cũ (ví dụ TLS 1.0/1.1) gây giảm điểm |
| **C** | Có vấn đề rõ ràng hơn: cipher yếu, chain thiếu sót, hoặc cấu hình không tối ưu |
| **F** | Lỗi nghiêm trọng: lỗ hổng đã biết (ví dụ Heartbleed cũ), chain hoàn toàn sai, hoặc cấu hình sai căn bản |


### Các tiêu chí được SSL Labs đánh giá
 
```
Certificate          → Đúng domain, đúng SAN, chưa hết hạn, đúng chain 
Protocol Support     → Có còn bật SSL 2.0/3.0, TLS 1.0/1.1 không 
Key Exchange         → Độ mạnh RSA/ECC, có hỗ trợ Forward Secrecy không 
Cipher Strength      → Có còn 3DES, RC4 (cipher yếu) không 
HSTS                 → Có bật, có includeSubDomains, có preload không
OCSP Stapling        → Có hoạt động không 
Chain of Trust        → Đầy đủ Intermediate CA không 
```
 
**Cách dùng thực tế:**
 
```
1. Truy cập: https://www.ssllabs.com/ssltest/
2. Nhập domain: demo.lab.local hoặc congty.vn
3. Đợi quét (1-3 phút)
4. Xem kết quả:
   - Overall Rating (A+/A/B/C/F)
   - Certificate 
   - Configuration (Protocol, Cipher, Key Exchange)
   - Handshake Simulation
```
 
> Lưu ý: SSL Labs chỉ test được domain có IP **public**, không quét được domain nội bộ như `demo.lab.local` trong lab — cần một domain thật trỏ DNS ra ngoài Internet để test bằng công cụ này.
 
## SSL Checker
 
Là nhóm công cụ nhẹ hơn SSL Labs, tập trung vào kiểm tra nhanh các thông tin cơ bản, không chấm điểm tổng thể chi tiết như SSL Labs. Một số công cụ phổ biến: `sslshopper.com/ssl-checker`, `whatsmychaincert.com`, hoặc tích hợp sẵn trong nhiều đại lý bán SSL (kể cả Nhân Hòa thường có sẵn link kiểm tra nhanh sau khi khách cài cert).
 
### Kiểm tra chứng chỉ
 
Xác nhận cert đang chạy đúng domain, đúng CA cấp, hiển thị thông tin Subject/Issuer giống cấu trúc đã học ở Phần 3 nhưng dạng rút gọn, dễ đọc cho người không chuyên kỹ thuật.
 
### Kiểm tra Chain
 
Tương đương việc dùng `openssl s_client -showcerts` ở Phần 5.4, nhưng hiển thị trực quan: liệt kê từng cert trong chain, cảnh báo rõ nếu thiếu Intermediate CA — đây là công cụ nhanh nhất để xác nhận lỗi "Incomplete Chain" mà không cần nhớ cú pháp OpenSSL.
 
### Kiểm tra ngày hết hạn
 
Hiển thị rõ `Not After` (Validity Period — Phần 3) và số ngày còn lại — dùng để theo dõi nhanh nhiều domain cùng lúc trong công việc support hằng ngày, đặc biệt hữu ích khi quản lý nhiều domain khách hàng cùng lúc mà không muốn chạy `openssl` riêng cho từng domain.
 
## So sánh SSL Labs vs SSL Checker
 
| Tiêu chí | SSL Labs | SSL Checker (nhẹ) |
|---|---|---|
| Độ chi tiết | Rất chi tiết, chấm điểm A+ → F | Cơ bản: cert, chain, ngày hết hạn |
| Thời gian quét | 1–3 phút | Vài giây |
| Phù hợp | Audit định kỳ, demo cho khách hàng, kiểm tra trước go-live | Kiểm tra nhanh hằng ngày, theo dõi nhiều domain |
| Test với nhiều OS/Browser | Có (Handshake Simulation) | Không |

 Toàn bộ tài liệu từ Phần 5 đến 7.5 đã đi qua từng thành phần kỹ thuật riêng lẻ: khóa, CSR, định dạng, chain, cài đặt trên từng loại server, redirect, HSTS, OCSP, HTTP/2, và công cụ kiểm tra. Trong công việc thực tế của System Administrator, các thành phần này không được kiểm tra rời rạc mà cần một **quy trình audit có thứ tự, lặp lại được**, áp dụng cho mọi domain trong hạ tầng — đặc biệt quan trọng khi quản lý nhiều domain khách hàng cùng lúc (bối cảnh hosting/mail server tại Nhân Hòa).
 
Quy trình dưới đây tổng hợp lại toàn bộ kiến thức đã học thành một checklist hành động theo đúng thứ tự ưu tiên xử lý vấn đề.
 
## Quy trình Audit SSL — 8 Bước
 
```
1. Kiểm tra Certificate
        |
        v
2. Kiểm tra Chain
        |
        v
3. Kiểm tra Cipher
        |
        v
4. Kiểm tra TLS Version
        |
        v
5. Kiểm tra HSTS
        |
        v
6. Kiểm tra OCSP
        |
        v
7. Kiểm tra Expiration
        |
        v
8. Đánh giá SSL Labs (tổng hợp toàn bộ)
```
 
Thứ tự này không tùy ý: các bước 1–4 kiểm tra **tính đúng đắn cấu trúc** của cert , bước 5–7 kiểm tra **cấu hình vận hành**, bước 8 là bước **tổng hợp xác nhận** lại toàn bộ.
 
---
 
### Bước 1 — Kiểm tra Certificate
 
Xác nhận cert đúng domain, đúng SAN, còn hiệu lực, đúng Issuer (liên hệ Phần 3, 5.2).
 
```bash
openssl x509 -in cert.pem -noout -subject -issuer -dates -ext subjectAltName
```
 
**Tiêu chí pass:** CN/SAN khớp đúng domain đang chạy, `Not After` còn hạn, Issuer là CA hợp lệ (không phải self-signed nếu là production).
 
### Bước 2 — Kiểm tra Chain
 
Xác nhận chain đầy đủ tới Root CA, không thiếu Intermediate (liên hệ Phần 5.4, 5.5).
 
```bash
openssl s_client -connect domain.vn:443 -showcerts < /dev/null 2>/dev/null
```
 
**Tiêu chí pass:** trả về đủ 2 cert (website cert + Intermediate CA), không có dòng cảnh báo `unable to verify the first certificate` hoặc `Verify return code` khác 0.
 
### Bước 3 — Kiểm tra Cipher
 
Xác nhận không còn cipher yếu như 3DES, RC4 (liên hệ Phần 1).
 
```bash
nmap --script ssl-enum-ciphers -p 443 domain.vn
```
 
**Tiêu chí pass:** danh sách cipher không chứa `3DES`, `RC4`, `NULL`, hoặc cipher gắn nhãn "weak"/"insecure" trong kết quả scan.
 
### Bước 4 — Kiểm tra TLS Version
 
Xác nhận đã loại bỏ SSL 2.0/3.0, TLS 1.0/1.1 (liên hệ Phần 1, 6.1).
 
```bash
openssl s_client -connect domain.vn:443 -tls1   2>&1 | grep "Cipher is"
openssl s_client -connect domain.vn:443 -tls1_1 2>&1 | grep "Cipher is"
openssl s_client -connect domain.vn:443 -tls1_2 2>&1 | grep "Cipher is"
openssl s_client -connect domain.vn:443 -tls1_3 2>&1 | grep "Cipher is"
```
 
**Tiêu chí pass:** TLS 1.0/1.1 trả về lỗi kết nối (handshake failure), chỉ TLS 1.2/1.3 thành công.
 
### Bước 5 — Kiểm tra HSTS
 
Xác nhận header có tồn tại và cấu hình đúng (liên hệ Phần 7.2).
 
```bash
curl -I https://domain.vn | grep -i strict-transport-security
```
 
**Tiêu chí pass:** có header `Strict-Transport-Security` với `max-age` đủ dài (khuyến nghị tối thiểu vài tháng trước khi tăng lên 1 năm).
 
### Bước 6 — Kiểm tra OCSP
 
Xác nhận OCSP Stapling đang hoạt động (liên hệ Phần 7.3).
 
```bash
openssl s_client -connect domain.vn:443 -status < /dev/null 2>/dev/null | grep "OCSP Response Status"
```
 
**Tiêu chí pass:** trả về `OCSP Response Status: successful (0x0)`, không phải `no response sent`.
 
### Bước 7 — Kiểm tra Expiration
 
Xác nhận cert chưa gần hết hạn và cơ chế auto-renewal đang hoạt động đúng (liên hệ Phần 6.7).
 
```bash
echo | openssl s_client -connect domain.vn:443 2>/dev/null | \
    openssl x509 -noout -enddate
 
# Kiểm tra timer renew có đang chạy đúng lịch
systemctl status certbot.timer
```
 
**Tiêu chí pass:** còn trên 15–30 ngày trước hết hạn (với Let's Encrypt 90 ngày, đây là ngưỡng cảnh báo cần theo dõi sát); `certbot.timer` ở trạng thái `active`.
 
### Bước 8 — Đánh giá SSL Labs
 
Chạy bài test tổng hợp để xác nhận lại toàn bộ 7 bước trên cùng lúc, lấy hạng điểm chính thức để báo cáo (liên hệ Phần 7.5).
 
```
Truy cập: https://www.ssllabs.com/ssltest/
Nhập: domain.vn
Mục tiêu tối thiểu: hạng A
Mục tiêu tốt nhất: hạng A+
```
 
**Tiêu chí pass:** hạng A hoặc A+; nếu thấp hơn, đối chiếu lại báo cáo chi tiết của SSL Labs với từng bước 1–7 ở trên để xác định bước nào đang gây giảm điểm.
 
---
 
## Bảng tổng hợp Checklist Audit (dùng khi audit nhiều domain)
 
| # | Bước | Lệnh kiểm tra chính | Pass khi |
|---|---|---|---|
| 1 | Certificate | `openssl x509 -noout -dates -ext subjectAltName` | Đúng domain, còn hạn |
| 2 | Chain | `openssl s_client -showcerts` | Đủ Intermediate, verify return 0 |
| 3 | Cipher | `nmap --script ssl-enum-ciphers` | Không còn 3DES/RC4 |
| 4 | TLS Version | `openssl s_client -tls1/-tls1_1/...` | Chỉ TLS 1.2/1.3 thành công |
| 5 | HSTS | `curl -I \| grep strict-transport` | Có header, max-age hợp lý |
| 6 | OCSP | `openssl s_client -status` | `successful (0x0)` |
| 7 | Expiration | `openssl x509 -enddate` + `systemctl status certbot.timer` | Còn hạn, timer active |
| 8 | SSL Labs | Web UI ssllabs.com | Hạng A hoặc A+ |
 
## Ứng dụng thực tế trong công việc
 
Khi audit hàng loạt domain trên một server hosting (bối cảnh cPanel/Plesk — Phần 6.5), có thể viết script bash lặp qua danh sách domain, chạy 7 bước dòng lệnh (1–7) tự động, xuất kết quả ra file log, chỉ domain nào fail mới cần vào SSL Labs kiểm tra sâu (bước 8) — tránh phải chạy SSL Labs cho từng domain (giới hạn tốc độ và mất nhiều thời gian hơn dòng lệnh).
 
```bash
#!/bin/bash
# Audit nhanh nhiều domain — 7 bước dòng lệnh đầu tiên
DOMAINS=("congty.vn" "shop.congty.vn" "mail.congty.vn")
 
for d in "${DOMAINS[@]}"; do
    echo "===== $d ====="
    echo | openssl s_client -connect "$d:443" -servername "$d" 2>/dev/null | \
        openssl x509 -noout -subject -enddate
    echo "---"
done
```
 
