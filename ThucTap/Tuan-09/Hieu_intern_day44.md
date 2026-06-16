# Báo cáo thực tập day 44 - SSL Termination

## 5. Thành phần kỹ thuật cần làm rõ hơn
# 5.1 Public Key và Private Key

## Định nghĩa

Public Key và Private Key là một cặp khóa toán học liên kết với nhau trong hệ mã hóa bất đối xứng (Asymmetric Cryptography).

Nguyên tắc hoạt động:

* Dữ liệu mã hóa bằng Public Key chỉ có thể giải mã bằng Private Key tương ứng.
* Dữ liệu được ký bằng Private Key có thể được xác thực bằng Public Key.

```text
Public Key  → Mã hóa dữ liệu
Private Key → Giải mã dữ liệu

Private Key → Ký số
Public Key  → Xác thực chữ ký
```

---

## Tại sao Public Key và Private Key tồn tại?

Trong mã hóa đối xứng (AES), hai bên phải sở hữu cùng một khóa bí mật trước khi giao tiếp.

Vấn đề đặt ra:

```text
Client ------------------- Server

Làm sao gửi khóa AES cho nhau
mà không bị nghe lén?
```

Đây được gọi là bài toán phân phối khóa (Key Distribution Problem).

Mã hóa bất đối xứng giải quyết vấn đề này bằng cách:

* Public Key được công khai cho mọi người.
* Private Key chỉ chủ sở hữu nắm giữ.
* Không cần trao đổi khóa bí mật trước.

```text
Client nhận Public Key của Server
            │
            ▼
     Mã hóa dữ liệu
            │
            ▼
        Server
            │
            ▼
Dùng Private Key để giải mã
```

---

## Vai trò trong SSL/TLS

Public Key và Private Key không dùng để mã hóa toàn bộ lưu lượng mạng vì tốc độ xử lý chậm.

Trong TLS, chúng chỉ được sử dụng trong giai đoạn Handshake để tạo Session Key.

Sau khi Session Key được tạo:

```text
TLS Handshake
      │
      ▼
Public Key / Private Key
      │
      ▼
Tạo Session Key
      │
      ▼
AES hoặc ChaCha20
      │
      ▼
Mã hóa toàn bộ dữ liệu
```

Do đó:

* Asymmetric Crypto → Trao đổi khóa.
* Symmetric Crypto → Mã hóa dữ liệu thực tế.

---

## Nếu mất Private Key?

Private Key phải được bảo vệ tuyệt đối.

Nếu Private Key bị lộ:

* Kẻ tấn công có thể giả mạo Server.
* Có thể thực hiện tấn công Man-in-the-Middle.
* Chứng chỉ SSL không còn an toàn.

Cách xử lý:

1. Thu hồi (Revoke) chứng chỉ hiện tại.
2. Tạo cặp khóa mới.
3. Tạo CSR mới.
4. Cấp lại chứng chỉ SSL.

---

## Có thể tạo lại Private Key từ Public Key không?

Không.

Đây là tính chất quan trọng nhất của mã hóa bất đối xứng.

```text
Private Key ─────► Public Key

Dễ tính toán
```

```text
Public Key ─────► Private Key

Không khả thi về mặt tính toán
```

Đây được gọi là hàm một chiều (One-Way Function).

Tính chất này là nền tảng bảo mật của:

* SSL/TLS
* SSH
* VPN
* Chữ ký số
* Blockchain

---

## So sánh RSA và ECC

| Tiêu chí                | RSA                                   | ECC                                      |
| ----------------------- | ------------------------------------- | ---------------------------------------- |
| Cơ sở toán học          | Phân tích số nguyên lớn thành thừa số | Logarit rời rạc trên đường cong Elliptic |
| Độ dài khóa tương đương | 2048-bit                              | 256-bit                                  |
| Hiệu năng               | Chậm hơn                              | Nhanh hơn                                |
| Tài nguyên CPU          | Cao hơn                               | Thấp hơn                                 |
| Kích thước chứng chỉ    | Lớn hơn                               | Nhỏ hơn                                  |
| Băng thông sử dụng      | Nhiều hơn                             | Ít hơn                                   |
| Tính tương thích        | Rất cao                               | Cao                                      |
| Khuyến nghị hiện nay    | Vẫn phổ biến                          | Khuyến nghị cho hệ thống mới             |

### Mức bảo mật tương đương

| RSA      | ECC     |
| -------- | ------- |
| 2048 bit | 256 bit |
| 3072 bit | 384 bit |
| 7680 bit | 521 bit |

---

## Kết luận

* Public Key và Private Key là nền tảng của SSL/TLS.
* Chúng giải quyết bài toán phân phối khóa an toàn trên Internet.
* Trong TLS hiện đại, chúng chỉ dùng để xác thực và trao đổi khóa.
* Dữ liệu thực tế được mã hóa bằng AES hoặc ChaCha20.
* ECC đang dần thay thế RSA nhờ hiệu năng tốt hơn và khóa ngắn hơn nhưng vẫn đảm bảo mức bảo mật tương đương.

Lệnh OpenSSL:

```
# Tạo RSA private key 2048-bit
openssl genrsa -out private.key 2048

# Tạo ECC private key (curve prime256v1)
openssl ecparam -name prime256v1 -genkey -noout -out ecc_private.key

# Xem nội dung chi tiết key
openssl rsa -in private.key -text -noout

# Trích public key ra từ private key
openssl pkey -in private.key -pubout -out public.key
```
## 5.2 CSR (Certificate Signing Request)

### Định nghĩa

CSR (Certificate Signing Request) là một tệp yêu cầu cấp chứng chỉ SSL theo chuẩn PKCS#10.

CSR chứa:

* Public Key của Server.
* Thông tin định danh Domain hoặc Doanh nghiệp.
* Chữ ký được tạo từ Private Key tương ứng.

CSR được gửi tới CA để yêu cầu cấp chứng chỉ SSL/TLS.

---

### Vì sao phải tạo CSR trước khi xin SSL?

Khi cấp SSL, CA cần xác minh hai thông tin:

1. Ai đang yêu cầu cấp chứng chỉ.
2. Public Key nào sẽ được gắn vào chứng chỉ.

CSR đóng gói cả hai thông tin này trong cùng một tệp.

```text
Thông tin Domain/Tổ chức
           +
       Public Key
           +
     Chữ ký số
           ↓
          CSR
```

Điểm quan trọng:

* Private Key luôn được giữ trên Server.
* CA không bao giờ nhận Private Key.
* CA chỉ nhận CSR.

---

## CSR chứa những thông tin gì?

| Trường                   | Ý nghĩa                  | Ví dụ                                                 |
| ------------------------ | ------------------------ | ----------------------------------------------------- |
| CN (Common Name)         | Domain chính cần cấp SSL | congty.vn                                             |
| O (Organization)         | Tên tổ chức              | Cong Ty ABC                                           |
| OU (Organizational Unit) | Phòng ban (tùy chọn)     | IT Department                                         |
| C (Country)              | Mã quốc gia              | VN                                                    |
| ST (State/Province)      | Tỉnh/Thành phố           | Ha Noi                                                |
| L (Locality)             | Quận/Huyện               | Dong Da                                               |
| SAN                      | Danh sách Domain bổ sung | [www.congty.vn](http://www.congty.vn), mail.congty.vn |

Ví dụ:

```
CN  = congty.vn
O   = Cong Ty ABC
OU  = IT Department
C   = VN
ST  = Ha Noi
L   = Dong Da
```

---

## CA sử dụng CSR như thế nào?

Sau khi nhận CSR, CA sẽ:

1. Đọc thông tin định danh trong CSR.
2. Xác minh quyền sở hữu Domain.
3. Lấy Public Key từ CSR.
4. Tạo Certificate.
5. Ký Certificate bằng Private Key của CA.

```text
CSR
 │
 ▼
CA đọc thông tin
 │
 ▼
Xác minh Domain
 │
 ▼
Tạo Certificate
 │
 ▼
Ký bằng Private Key của CA
 │
 ▼
SSL Certificate
```

Lưu ý:

* CSR không chứa Private Key.
* Có thể gửi CSR qua Internet mà không lo lộ khóa bí mật.

---

## Luồng xử lý CSR

```
Private Key
(Giữ trên Server)
      │
      │ Ký CSR
      ▼
     CSR
      │
      ▼
      CA
      │
      │ Xác minh Domain
      │ Ký Certificate
      ▼
 SSL Certificate
      │
      ▼
Cài lên Server
      │
      ▼
Sử dụng cùng Private Key ban đầu
```

---

## Tạo CSR bằng OpenSSL

### Tạo CSR và Private Key mới

```
openssl req -new -newkey rsa:2048 -nodes \
-keyout congty.key \
-out congty.csr \
-subj "/C=VN/ST=Ha Noi/L=Dong Da/O=Cong Ty ABC/CN=congty.vn"
```

---
### Tạo CSR từ Private Key có sẵn

```
openssl req -new \
-key congty.key \
-out congty.csr
```

---
### Tạo CSR có SAN (Multi-Domain)

```bash
openssl req -new \
-key congty.key \
-out congty.csr \
-subj "/CN=congty.vn" \
-addext "subjectAltName=DNS:congty.vn,DNS:www.congty.vn,DNS:mail.congty.vn"
```

---

### Kiểm tra nội dung CSR
openssl req -in congty.csr -noout -text

---
## 5.3 Định Dạng Chứng Chỉ

### Khái niệm

Chứng chỉ SSL sử dụng chuẩn X.509 nhưng có thể được lưu dưới nhiều định dạng khác nhau tùy hệ điều hành và ứng dụng.

---

### Các định dạng phổ biến

#### PEM

* Dạng văn bản (Base64).
* Phổ biến nhất trên Linux.
* Dùng cho Apache, Nginx.
* Có thể chứa Certificate, Private Key hoặc Chain.

```text
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

#### CRT

* Thường là Certificate dạng PEM.
* Không chứa Private Key.
* Phổ biến trên Linux/Unix.

#### CER

* Tương tự CRT.
* Thường dùng trên Windows.
* Có thể là PEM hoặc DER.

#### DER

* Dạng nhị phân (Binary).
* Không đọc được bằng text editor.
* Thường dùng cho Java hoặc một số ứng dụng Windows.

#### PFX / P12

* Chuẩn PKCS#12.
* Chứa Certificate + Private Key + Chain.
* Được bảo vệ bằng mật khẩu.
* Thường dùng trên IIS, Windows và Java.

---

### Bảng so sánh

| Định dạng | Dạng lưu trữ  | Chứa Private Key | Thường dùng          |
| --------- | ------------- | ---------------- | -------------------- |
| PEM       | Text          | Có thể           | Apache, Nginx, Linux |
| CRT       | PEM           | Không            | Linux/Unix           |
| CER       | PEM hoặc DER  | Không            | Windows              |
| DER       | Binary        | Có thể           | Java, Windows        |
| PFX       | Binary        | Có               | IIS, Windows         |
| P12       | Binary        | Có               | Java, macOS          |

---

### Server sử dụng định dạng nào?

| Hệ thống | Định dạng         |
| -------- | ----------------- |
| Apache   | PEM (.crt + .key) |
| Nginx    | PEM (.crt + .key) |
| IIS      | PFX               |
| Windows  | CER, PFX          |
| Java     | P12, JKS          |

---

### Chuyển đổi định dạng

#### PEM → DER

```bash
openssl x509 -in cert.pem -outform der -out cert.der
```

#### DER → PEM

```bash
openssl x509 -in cert.der -inform der -out cert.pem
```

#### Tạo PFX cho IIS

```bash
openssl pkcs12 -export \
-out cert.pfx \
-inkey private.key \
-in cert.pem \
-certfile chain.pem
```

#### Tách PFX thành PEM

```bash
openssl pkcs12 -in cert.pfx -nocerts -nodes -out private.key

openssl pkcs12 -in cert.pfx -clcerts -nokeys -out cert.pem
```

---
