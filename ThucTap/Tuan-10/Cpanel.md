# Báo cáo thực tập ngày 50 - Cpanel

## Thiết lập hostname

```bash
sudo hostnamectl set-hostname cpanel.lab.local
```

---

## Cấu hình IP tĩnh

```bash
sudo nmcli connection modify ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.136.148/24 \
  ipv4.gateway 192.168.136.2 \
  ipv4.dns "8.8.8.8,8.8.4.4"

sudo nmcli connection up ens160
```

---

## Cập nhật /etc/hosts

```bash
echo "192.168.136.148 cpanel.lab.local cpanel" | sudo tee -a /etc/hosts
```

---

## Cập nhật hệ thống

```bash
sudo dnf update -y
```

---

## Firewalld và SELinux

```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld

sudo setenforce 0

sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

getenforce
```

---

## Kiểm tra kết nối

```bash
curl -I https://securedownloads.cpanel.net
```

(Không cần sudo)

---

## Cài đặt cPanel

```bash
cd /home

curl -o latest -L https://securedownloads.cpanel.net/latest

sudo sh latest
```

---

## Theo dõi log

```bash
sudo tail -f /var/log/cpanel-install.log

sudo tail -f /var/log/cpanel-install.log | grep -E "Installing|Configuring|Starting|Error|Warning"
```

---

## Kiểm tra service

```bash
sudo systemctl status cpanel

sudo ss -tlnp | grep -E '80|443|2083|2087|2086|2082'
```

---

## Kích hoạt Trial License

```bash
sudo /usr/local/cpanel/cpkeyclt
```

---

## Restart dịch vụ

```bash
sudo /usr/local/cpanel/scripts/restartsrv_httpd

sudo /usr/local/cpanel/scripts/restartsrv_exim

sudo /usr/local/cpanel/scripts/restartsrv_dovecot

sudo /usr/local/cpanel/scripts/restartsrv_mysql
```

---

## Kiểm tra version

```bash
sudo cat /usr/local/cpanel/version
```

---

## Kiểm tra account

```bash
sudo cat /etc/trueuserdomains

sudo ls -la /home/customer1/

sudo cat /etc/apache2/conf.d/userdata/std/2_4/customer1/customer1.local/
```

---

## Tạo file test

```bash
echo "<h1>Hello from customer1</h1>" | sudo tee /home/customer1/public_html/index.html

sudo chown customer1:customer1 /home/customer1/public_html/index.html
```

---

## Troubleshooting

### Log lỗi cPanel

```bash
sudo tail -100 /var/log/cpanel-install.log | grep -i "error\|fail\|cannot"
```

### Chạy lại installer

```bash
sudo sh latest
```

### Restart cPanel

```bash
sudo systemctl restart cpanel
```

### Kiểm tra firewall

```bash
sudo csf -l | grep 2087

sudo csf -a 192.168.136.0/24
```

### Sửa hostname

```bash
sudo hostnamectl set-hostname cpanel.lab.local

sudo sed -i 's/^127.0.0.1.*/127.0.0.1 localhost/' /etc/hosts

echo "192.168.136.148 cpanel.lab.local cpanel" | sudo tee -a /etc/hosts
```

### License

```bash
sudo /usr/local/cpanel/cpkeyclt

sudo cat /usr/local/cpanel/cpanelinfo

sudo curl -o /usr/local/cpanel/cpanelinfo \
https://verify.cpanel.net/getkey?ip=192.168.136.148
```
