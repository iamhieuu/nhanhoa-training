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
