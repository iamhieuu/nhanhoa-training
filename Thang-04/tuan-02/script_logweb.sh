#!/bin/bash
# =============================================================================
#  WEB SERVER LOG MONITOR - Ubuntu 22.04
#  Tác dụng: Giám sát log, phát hiện tấn công, gửi cảnh báo
#  Dành cho: Nginx / Apache Web Server thực tế
#  Cách dùng: sudo bash weblog_monitor.sh [OPTION]
#
#  Options:
#    --full-report    Báo cáo toàn bộ (mặc định)
#    --realtime       Giám sát realtime
#    --attack-check   Chỉ kiểm tra tấn công
#    --system-health  Chỉ kiểm tra sức khỏe hệ thống
#    --install        Cài đặt (logrotate, rsyslog cấu hình)
# =============================================================================

set -euo pipefail


### Web Server (chọn nginx hoặc apache2)
WEB_SERVER="nginx" 

### Log files
NGINX_ACCESS="/var/log/nginx/access.log"
NGINX_ERROR="/var/log/nginx/error.log"
APACHE_ACCESS="/var/log/apache2/access.log"
APACHE_ERROR="/var/log/apache2/error.log"
AUTH_LOG="/var/log/auth.log"
SYSLOG="/var/log/syslog"
KERN_LOG="/var/log/kern.log"

### Thư mục lưu báo cáo
REPORT_DIR="/var/log/webserver_monitor"
REPORT_FILE="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).log"
ALERT_FILE="$REPORT_DIR/alerts.log"
SUMMARY_FILE="$REPORT_DIR/daily_summary.log"

### Ngưỡng cảnh báo (thresholds)
SSH_FAIL_THRESHOLD=5  
HTTP_4XX_THRESHOLD=50  
HTTP_5XX_THRESHOLD=20 
BRUTE_FORCE_THRESHOLD=20
DISK_USAGE_THRESHOLD=85 
CPU_THRESHOLD=90 
MEM_THRESHOLD=90 

ALERT_EMAIL=""                # vd: admin@yourdomain.com
SEND_EMAIL=false              # true | false

### Telegram Bot (để trống nếu không dùng)
TELEGRAM_TOKEN=""             # Bot token
TELEGRAM_CHAT_ID=""           # Chat ID
SEND_TELEGRAM=false           # true | false

# =============================================================================
#  MÀUSẮC VÀ HELPER FUNCTIONS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

_info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
_alert()   { echo -e "${RED}[ALERT]${NC} $*"; }
_section() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }
_ok()      { echo -e "${GREEN}✔${NC} $*"; }
_fail()    { echo -e "${RED}✘${NC} $*"; }
_bullet()  { echo -e "  ${BLUE}•${NC} $*"; }

# Ghi log vào file
log_write() {
    local level="$1"; shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$REPORT_FILE"
}

# Ghi alert
alert_write() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ALERT] $*" | tee -a "$ALERT_FILE"
}

# Gửi Telegram (nếu cấu hình)
send_telegram() {
    local message="$1"
    if [[ "$SEND_TELEGRAM" == true && -n "$TELEGRAM_TOKEN" ]]; then
        curl -s -X POST \
            "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${message}" \
            -d "parse_mode=HTML" > /dev/null 2>&1 || true
    fi
}

# Gửi email (nếu cấu hình)
send_email() {
    local subject="$1"
    local body="$2"
    if [[ "$SEND_EMAIL" == true && -n "$ALERT_EMAIL" ]]; then
        echo "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
    fi
}

# =============================================================================
#  KIỂM TRA ĐIỀU KIỆN
# =============================================================================

check_requirements() {
    # Phải chạy với quyền root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Lỗi: Script cần quyền root!${NC}"
        echo "Dùng: sudo bash $0"
        exit 1
    fi

    # Tạo thư mục báo cáo
    mkdir -p "$REPORT_DIR"
    touch "$REPORT_FILE" "$ALERT_FILE" "$SUMMARY_FILE"

    # Xác định log file web server
    if [[ "$WEB_SERVER" == "nginx" ]]; then
        ACCESS_LOG="$NGINX_ACCESS"
        ERROR_LOG="$NGINX_ERROR"
    else
        ACCESS_LOG="$APACHE_ACCESS"
        ERROR_LOG="$APACHE_ERROR"
    fi
}

# =============================================================================
#  PHẦN 1: LOG REBOOT / SHUTDOWN
# =============================================================================

check_reboot_shutdown() {
    _section "LOG REBOOT / SHUTDOWN"

    echo ""
    echo -e "${BOLD}◆ 5 lần khởi động/tắt gần nhất:${NC}"

    # Dùng journalctl (hệ thống systemd)
    if command -v journalctl &>/dev/null; then
        journalctl -u systemd-logind.service --no-pager -n 0 2>/dev/null | head -1 > /dev/null
        
        # Lần reboot gần nhất
        echo ""
        echo -e "  ${YELLOW}Thời gian boot:${NC}"
        last reboot 2>/dev/null | head -6 | while read -r line; do
            [[ -n "$line" ]] && _bullet "$line"
        done

        # Lần shutdown gần nhất
        echo ""
        echo -e "  ${YELLOW}Thời gian shutdown:${NC}"
        last -x shutdown 2>/dev/null | head -6 | while read -r line; do
            [[ -n "$line" ]] && _bullet "$line"
        done

        # Thời gian uptime hiện tại
        echo ""
        echo -e "  ${YELLOW}Uptime hiện tại:${NC}"
        _bullet "$(uptime -p)"
        _bullet "Boot lúc: $(uptime -s)"

        # Kernel panic gần đây (nếu có)
        echo ""
        echo -e "  ${YELLOW}Kernel panic / crash (24h qua):${NC}"
        local panic_count
        panic_count=$(journalctl -k --since "24 hours ago" 2>/dev/null | \
            grep -c "kernel panic\|Oops\|BUG:" 2>/dev/null || echo "0")
        if [[ "$panic_count" -gt 0 ]]; then
            _fail "Phát hiện $panic_count kernel error trong 24h!"
            alert_write "Kernel panic/error: $panic_count lần trong 24h"
        else
            _ok "Không có kernel panic trong 24h"
        fi

    else
        _warn "journalctl không khả dụng. Kiểm tra /var/log/syslog"
        grep -E "shutdown|reboot|Stopping" "$SYSLOG" 2>/dev/null | tail -10 | \
            while read -r line; do _bullet "$line"; done
    fi

    log_write "INFO" "Kiểm tra reboot/shutdown hoàn thành"
}

# =============================================================================
#  PHẦN 2: JOURNALCTL — PHÂN TÍCH LOG HỆ THỐNG
# =============================================================================

check_journalctl() {
    _section "JOURNALCTL — PHÂN TÍCH LOG HỆ THỐNG"

    echo ""
    echo -e "${BOLD}◆ Lỗi nghiêm trọng trong 24h qua:${NC}"

    # Lỗi CRITICAL và EMERGENCY
    local critical_count
    critical_count=$(journalctl -p crit --since "24 hours ago" \
        --no-pager 2>/dev/null | grep -v "^--" | wc -l)

    if [[ "$critical_count" -gt 0 ]]; then
        _fail "Có $critical_count lỗi CRITICAL trong 24h!"
        journalctl -p crit --since "24 hours ago" \
            --no-pager -n 5 2>/dev/null | grep -v "^--" | \
            while read -r line; do _bullet "${RED}$line${NC}"; done
        alert_write "CRITICAL errors: $critical_count trong 24h"
    else
        _ok "Không có lỗi CRITICAL trong 24h"
    fi

    echo ""
    echo -e "${BOLD}◆ Trạng thái các service quan trọng:${NC}"

    # Kiểm tra các service thiết yếu
    local services=("$WEB_SERVER" "ssh" "ufw" "fail2ban" "rsyslog" "cron")
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            _ok "$svc: ${GREEN}đang chạy${NC}"
        elif systemctl list-unit-files --quiet "$svc.service" &>/dev/null; then
            _fail "$svc: ${RED}không chạy!${NC}"
            alert_write "Service $svc không chạy!"
        else
            echo -e "  ${YELLOW}⚠${NC}  $svc: chưa cài đặt"
        fi
    done

    echo ""
    echo -e "${BOLD}◆ Dung lượng journal log:${NC}"
    journalctl --disk-usage 2>/dev/null | _bullet
    
    log_write "INFO" "Kiểm tra journalctl hoàn thành"
}

# =============================================================================
#  PHẦN 3: LOGROTATE — KIỂM TRA CẤU HÌNH
# =============================================================================

check_logrotate() {
    _section "LOGROTATE — KIỂM TRA TÌNH TRẠNG"

    echo ""
    echo -e "${BOLD}◆ Cấu hình logrotate hiện tại:${NC}"

    if command -v logrotate &>/dev/null; then
        _ok "logrotate đã cài đặt: $(logrotate --version 2>&1 | head -1)"
        
        # Kiểm tra cấu hình web server
        if [[ -f "/etc/logrotate.d/$WEB_SERVER" ]]; then
            _ok "Config logrotate $WEB_SERVER: có"
            _bullet "$(head -3 /etc/logrotate.d/$WEB_SERVER)"
        else
            _fail "Chưa có config logrotate cho $WEB_SERVER"
        fi

        # Kích thước các log file hiện tại
        echo ""
        echo -e "${BOLD}◆ Kích thước log files:${NC}"
        local log_files=("$ACCESS_LOG" "$ERROR_LOG" "$AUTH_LOG" "$SYSLOG")
        for f in "${log_files[@]}"; do
            if [[ -f "$f" ]]; then
                local size
                size=$(du -sh "$f" 2>/dev/null | cut -f1)
                local modified
                modified=$(stat -c '%y' "$f" 2>/dev/null | cut -d' ' -f1)
                _bullet "$(basename $f): ${YELLOW}$size${NC} (cập nhật: $modified)"
            fi
        done

        # Log files quá lớn (>100MB)
        echo ""
        echo -e "${BOLD}◆ Log files lớn hơn 100MB:${NC}"
        local big_logs
        big_logs=$(find /var/log -type f -size +100M 2>/dev/null)
        if [[ -n "$big_logs" ]]; then
            echo "$big_logs" | while read -r f; do
                local s; s=$(du -sh "$f" | cut -f1)
                _warn "$f ($s) — cần rotate gấp!"
                alert_write "Log file quá lớn: $f ($s)"
            done
        else
            _ok "Không có log file nào > 100MB"
        fi

    else
        _fail "logrotate chưa được cài đặt"
    fi

    log_write "INFO" "Kiểm tra logrotate hoàn thành"
}

# =============================================================================
#  PHẦN 4: RSYSLOG — KIỂM TRA REMOTE LOGGING
# =============================================================================

check_rsyslog() {
    _section "RSYSLOG — REMOTE LOGGING"

    echo ""
    if systemctl is-active --quiet rsyslog 2>/dev/null; then
        _ok "rsyslog: đang chạy"
        _bullet "Config: /etc/rsyslog.conf"
        _bullet "Config.d: $(ls /etc/rsyslog.d/*.conf 2>/dev/null | wc -l) files"
        
        # Kiểm tra remote logging
        if grep -q "@\|@@" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
            _ok "Remote logging: đang cấu hình"
            grep -E "@{1,2}[0-9a-zA-Z]" /etc/rsyslog.conf \
                /etc/rsyslog.d/*.conf 2>/dev/null | \
                grep -v "^#" | \
                while read -r line; do _bullet "$line"; done
        else
            _warn "Remote logging: chưa cấu hình (log chỉ lưu local)"
        fi
    else
        _warn "rsyslog không chạy. Kiểm tra: systemctl status rsyslog"
    fi
    
    log_write "INFO" "Kiểm tra rsyslog hoàn thành"
}

# =============================================================================
#  PHẦN 5: SECURITY CƠ BẢN — KIỂM TRA BẢO MẬT
# =============================================================================

check_security_baseline() {
    _section "SECURITY BASELINE — KIỂM TRA BẢO MẬT CƠ BẢN"

    local issues=0

    echo ""
    echo -e "${BOLD}◆ Bảo mật đăng nhập SSH:${NC}"

    local sshd_config="/etc/ssh/sshd_config"
    if [[ -f "$sshd_config" ]]; then
        # Root login
        local root_login
        root_login=$(grep -i "^PermitRootLogin" "$sshd_config" 2>/dev/null | awk '{print $2}')
        if [[ "$root_login" == "no" ]]; then
            _ok "PermitRootLogin: no (tốt)"
        else
            _fail "PermitRootLogin: ${root_login:-chưa tắt} (nguy hiểm!)"
            ((issues++))
        fi

        # Password auth
        local pass_auth
        pass_auth=$(grep -i "^PasswordAuthentication" "$sshd_config" 2>/dev/null | awk '{print $2}')
        if [[ "$pass_auth" == "no" ]]; then
            _ok "PasswordAuthentication: no (chỉ dùng SSH key - tốt)"
        else
            _warn "PasswordAuthentication: ${pass_auth:-yes} (nên đổi sang key-only)"
        fi

        # SSH Port
        local ssh_port
        ssh_port=$(grep -i "^Port" "$sshd_config" 2>/dev/null | awk '{print $2}')
        if [[ -n "$ssh_port" && "$ssh_port" != "22" ]]; then
            _ok "SSH Port: $ssh_port (đã đổi port - tốt)"
        else
            _warn "SSH Port: 22 (đang dùng port mặc định)"
        fi

        # Max Auth Tries
        local max_tries
        max_tries=$(grep -i "^MaxAuthTries" "$sshd_config" 2>/dev/null | awk '{print $2}')
        if [[ -n "$max_tries" && "$max_tries" -le 3 ]]; then
            _ok "MaxAuthTries: $max_tries (tốt)"
        else
            _warn "MaxAuthTries: ${max_tries:-6} (nên đặt ≤ 3)"
        fi
    fi

    echo ""
    echo -e "${BOLD}◆ Firewall (UFW):${NC}"
    if command -v ufw &>/dev/null; then
        local ufw_status
        ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "active"; then
            _ok "UFW: active (tốt)"
            ufw status 2>/dev/null | grep -v "^Status" | grep -v "^$" | \
                grep -v "To " | grep -v "\-\-" | head -10 | \
                while read -r line; do [[ -n "$line" ]] && _bullet "$line"; done
        else
            _fail "UFW: không active! (nguy hiểm)"
            ((issues++))
            alert_write "UFW firewall không active!"
        fi
    else
        _warn "UFW chưa cài đặt"
    fi

    echo ""
    echo -e "${BOLD}◆ Fail2Ban (chống Brute Force):${NC}"
    if command -v fail2ban-client &>/dev/null; then
        if systemctl is-active --quiet fail2ban 2>/dev/null; then
            _ok "fail2ban: đang chạy"
            # Số IP đang bị ban
            local banned_count
            banned_count=$(fail2ban-client status 2>/dev/null | \
                grep "Jail list" | sed 's/.*://;s/,/ /g' | \
                xargs -I{} fail2ban-client status {} 2>/dev/null | \
                grep "Currently banned" | awk '{sum+=$NF} END{print sum}' || echo "0")
            _bullet "IP đang bị ban: ${YELLOW}${banned_count:-0}${NC}"
            
            # Hiển thị các jail đang active
            fail2ban-client status 2>/dev/null | grep "Jail list" | \
                sed 's/.*: //' | tr ',' '\n' | \
                while read -r jail; do
                    [[ -n "$(echo $jail | tr -d ' ')" ]] && \
                    _bullet "Jail: $(echo $jail | tr -d ' ')"
                done
        else
            _fail "fail2ban: không chạy!"
            ((issues++))
            alert_write "fail2ban không chạy!"
        fi
    else
        _fail "fail2ban chưa cài đặt (nên cài!)"
        ((issues++))
    fi

    echo ""
    echo -e "${BOLD}◆ Cập nhật hệ thống:${NC}"
    local updates
    updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
    if [[ "$updates" -eq 0 ]]; then
        _ok "Hệ thống đã cập nhật đầy đủ"
    elif [[ "$updates" -lt 10 ]]; then
        _warn "Có $updates package cần cập nhật"
    else
        _fail "Có $updates package chưa cập nhật!"
        ((issues++))
    fi

    # Kiểm tra unattended-upgrades
    if systemctl is-active --quiet unattended-upgrades 2>/dev/null; then
        _ok "Auto security updates: đang bật"
    else
        _warn "Auto security updates: chưa bật (nên bật)"
    fi

    echo ""
    echo -e "${BOLD}◆ User và Quyền:${NC}"

    # User có shell login (không phải nologin)
    local login_users
    login_users=$(grep -v "nologin\|false" /etc/passwd | \
        grep -v "^#" | cut -d: -f1 | tr '\n' ' ')
    _bullet "User có thể login: ${YELLOW}$login_users${NC}"

    # User có UID 0 (root privilege)
    local root_users
    root_users=$(awk -F: '($3==0){print $1}' /etc/passwd | tr '\n' ' ')
    if [[ "$root_users" == "root " ]]; then
        _ok "Chỉ root có UID 0 (tốt)"
    else
        _fail "Nhiều user có UID 0: ${root_users} (nguy hiểm!)"
        ((issues++))
        alert_write "User không phải root có UID 0: $root_users"
    fi

    # File SUID bất thường
    local suid_count
    suid_count=$(find / -type f -perm -4000 2>/dev/null | \
        grep -v "proc\|sys" | wc -l)
    if [[ "$suid_count" -gt 20 ]]; then
        _warn "Có $suid_count file SUID (nhiều bất thường, kiểm tra lại)"
    else
        _ok "Số lượng file SUID: $suid_count (bình thường)"
    fi

    echo ""
    if [[ "$issues" -eq 0 ]]; then
        _ok "${GREEN}Security baseline: PASS — Không có vấn đề nghiêm trọng${NC}"
    else
        _fail "${RED}Security baseline: FAIL — Có $issues vấn đề cần xử lý!${NC}"
        alert_write "Security baseline FAIL: $issues vấn đề"
    fi

    log_write "INFO" "Security baseline: $issues vấn đề"
}

# =============================================================================
#  PHẦN 6: SỨC KHỎE HỆ THỐNG
# =============================================================================

check_system_health() {
    _section "SỨC KHỎE HỆ THỐNG"

    echo ""
    echo -e "${BOLD}◆ CPU, RAM, Disk:${NC}"

    # CPU Usage (lấy trung bình 1 giây)
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1 2>/dev/null || echo "0")
    local cpu_usage=$((100 - cpu_idle))
    if [[ "$cpu_usage" -ge "$CPU_THRESHOLD" ]]; then
        _fail "CPU: ${RED}${cpu_usage}%${NC} (ngưỡng: ${CPU_THRESHOLD}%)"
        alert_write "CPU cao: ${cpu_usage}%"
    else
        _ok "CPU: ${GREEN}${cpu_usage}%${NC}"
    fi

    # RAM Usage
    local mem_info
    mem_info=$(free | grep Mem)
    local mem_total; mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used;  mem_used=$(echo "$mem_info"  | awk '{print $3}')
    local mem_pct;   mem_pct=$(( mem_used * 100 / mem_total ))
    local mem_used_mb; mem_used_mb=$((mem_used / 1024))
    local mem_total_mb; mem_total_mb=$((mem_total / 1024))

    if [[ "$mem_pct" -ge "$MEM_THRESHOLD" ]]; then
        _fail "RAM: ${RED}${mem_pct}%${NC} (${mem_used_mb}MB / ${mem_total_mb}MB)"
        alert_write "RAM cao: ${mem_pct}%"
    else
        _ok "RAM: ${mem_pct}% (${mem_used_mb}MB / ${mem_total_mb}MB)"
    fi

    # Disk Usage — tất cả mount points
    echo ""
    echo -e "${BOLD}◆ Dung lượng Disk:${NC}"
    df -h --output=target,pcent,used,avail 2>/dev/null | grep -v "tmpfs\|udev\|loop" | \
        tail -n +2 | while read -r mount pct used avail; do
            local pct_num; pct_num=$(echo "$pct" | tr -d '%')
            if [[ "$pct_num" -ge "$DISK_USAGE_THRESHOLD" ]]; then
                _fail "$mount: ${RED}${pct}${NC} đã dùng (còn $avail)"
                alert_write "Disk đầy: $mount $pct"
            else
                _ok "$mount: ${pct} đã dùng (còn $avail)"
            fi
        done

    # Load Average
    echo ""
    echo -e "${BOLD}◆ Load Average:${NC}"
    local load; load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    local cpu_cores; cpu_cores=$(nproc)
    _bullet "Load (1m/5m/15m): ${YELLOW}${load}${NC}"
    _bullet "CPU cores: $cpu_cores"

    # Process nặng nhất
    echo ""
    echo -e "${BOLD}◆ Top 5 Process ngốn CPU:${NC}"
    ps aux --sort=-%cpu 2>/dev/null | \
        awk 'NR>1 && NR<=6 {printf "  • %-20s CPU: %s%% MEM: %s%%\n", $11, $3, $4}'

    # Kết nối mạng
    echo ""
    echo -e "${BOLD}◆ Kết nối mạng hiện tại:${NC}"
    local established; established=$(ss -tn state established 2>/dev/null | tail -n +2 | wc -l)
    local time_wait;   time_wait=$(ss -tn state time-wait 2>/dev/null | tail -n +2 | wc -l)
    local listening;   listening=$(ss -tln 2>/dev/null | tail -n +2 | wc -l)
    _bullet "ESTABLISHED: ${YELLOW}${established}${NC}"
    _bullet "TIME_WAIT:   ${time_wait}"
    _bullet "LISTENING:   ${listening}"

    log_write "INFO" "System health: CPU=$cpu_usage% RAM=$mem_pct% Connections=$established"
}

# =============================================================================
#  PHẦN 7: PHÂN TÍCH WEB SERVER ACCESS LOG
# =============================================================================

analyze_web_logs() {
    _section "PHÂN TÍCH WEB SERVER ACCESS LOG ($WEB_SERVER)"

    if [[ ! -f "$ACCESS_LOG" ]]; then
        _warn "Access log không tìm thấy: $ACCESS_LOG"
        return
    fi

    local log_lines; log_lines=$(wc -l < "$ACCESS_LOG" 2>/dev/null)
    _bullet "Tổng số dòng log: ${YELLOW}${log_lines}${NC}"
    _bullet "Kích thước file: $(du -sh "$ACCESS_LOG" | cut -f1)"

    echo ""
    echo -e "${BOLD}◆ Thống kê HTTP Status Codes:${NC}"
    awk '{print $9}' "$ACCESS_LOG" 2>/dev/null | \
        grep -E "^[0-9]{3}$" | sort | uniq -c | sort -rn | \
        while read -r count code; do
            local label=""
            case "${code:0:1}" in
                2) label="${GREEN}(Success)${NC}" ;;
                3) label="${CYAN}(Redirect)${NC}" ;;
                4) label="${YELLOW}(Client Error)${NC}" ;;
                5) label="${RED}(Server Error)${NC}" ;;
            esac
            printf "  • HTTP %-5s : %-8s %b\n" "$code" "$count" "$label"
        done

    echo ""
    echo -e "${BOLD}◆ Top 10 IP truy cập nhiều nhất (24h):${NC}"
    awk '{print $1}' "$ACCESS_LOG" 2>/dev/null | \
        sort | uniq -c | sort -rn | head -10 | \
        while read -r count ip; do
            # Highlight IP truy cập quá nhiều
            if [[ "$count" -gt 1000 ]]; then
                printf "  ${RED}• %-18s : %d requests ⚠ Suspicious!${NC}\n" "$ip" "$count"
            else
                printf "  • %-18s : %d requests\n" "$ip" "$count"
            fi
        done

    echo ""
    echo -e "${BOLD}◆ Top 10 URL được truy cập:${NC}"
    awk '{print $7}' "$ACCESS_LOG" 2>/dev/null | \
        cut -d'?' -f1 | sort | uniq -c | sort -rn | head -10 | \
        while read -r count url; do
            printf "  • %-45s : %d\n" "$url" "$count"
        done

    echo ""
    echo -e "${BOLD}◆ Top 10 User-Agent:${NC}"
    # Trích xuất user agent (field sau "HTTP/x.x" đến cuối)
    awk -F'"' '{print $6}' "$ACCESS_LOG" 2>/dev/null | \
        grep -v "^-$" | sort | uniq -c | sort -rn | head -10 | \
        while read -r count ua; do
            local ua_short; ua_short=$(echo "$ua" | cut -c1-60)
            printf "  • %-65s : %d\n" "$ua_short" "$count"
        done

    echo ""
    echo -e "${BOLD}◆ Lỗi 4xx và 5xx gần nhất:${NC}"
    grep -E '" [45][0-9]{2} ' "$ACCESS_LOG" 2>/dev/null | \
        tail -10 | \
        while read -r line; do
            local code; code=$(echo "$line" | awk '{print $9}')
            local ip;   ip=$(echo "$line"   | awk '{print $1}')
            local url;  url=$(echo "$line"  | awk '{print $7}')
            printf "  ${YELLOW}• %-6s${NC} | %-18s | %s\n" "$code" "$ip" "$url"
        done

    log_write "INFO" "Phân tích access log hoàn thành: $log_lines dòng"
}

# =============================================================================
#  PHẦN 8: PHÁT HIỆN TẤN CÔNG
# =============================================================================

detect_attacks() {
    _section "PHÁT HIỆN TẤN CÔNG"

    local attack_count=0

    # ─────────────────────────────────────────
    # 8.1 Brute Force SSH
    # ─────────────────────────────────────────
    echo ""
    echo -e "${BOLD}◆ SSH Brute Force (từ auth.log):${NC}"

    if [[ -f "$AUTH_LOG" ]]; then
        # Đếm tổng số lần SSH failed hôm nay
        local ssh_fails_today
        ssh_fails_today=$(grep "$(date '+%b %e')" "$AUTH_LOG" 2>/dev/null | \
            grep -c "Failed password\|Invalid user\|authentication failure" 2>/dev/null || echo "0")

        if [[ "$ssh_fails_today" -gt "$SSH_FAIL_THRESHOLD" ]]; then
            _fail "SSH failed hôm nay: ${RED}${ssh_fails_today} lần${NC}"
            ((attack_count++))
            alert_write "SSH brute force: $ssh_fails_today lần thất bại hôm nay"
            send_telegram "🚨 <b>ALERT</b>: SSH brute force trên $(hostname)
Số lần thất bại: $ssh_fails_today
Thời gian: $(date)"
        else
            _ok "SSH failed hôm nay: ${ssh_fails_today} lần (bình thường)"
        fi

        # Top IP tấn công SSH
        echo ""
        echo -e "  ${YELLOW}Top 5 IP tấn công SSH:${NC}"
        grep "Failed password\|Invalid user" "$AUTH_LOG" 2>/dev/null | \
            grep "$(date '+%b')" | \
            grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | \
            sort | uniq -c | sort -rn | head -5 | \
            while read -r count ip; do
                if [[ "$count" -ge 10 ]]; then
                    _bullet "${RED}$ip: $count lần ⚠ Nguy hiểm!${NC}"
                else
                    _bullet "$ip: $count lần"
                fi
            done

        # User bị thử đăng nhập
        echo ""
        echo -e "  ${YELLOW}Username bị brute force:${NC}"
        grep "Invalid user" "$AUTH_LOG" 2>/dev/null | \
            grep "$(date '+%b')" | \
            awk '{print $8}' | sort | uniq -c | sort -rn | head -5 | \
            while read -r count user; do
                _bullet "$user: $count lần"
            done

        # Đăng nhập SSH thành công
        echo ""
        echo -e "  ${YELLOW}Đăng nhập SSH thành công (hôm nay):${NC}"
        local success_logins
        success_logins=$(grep "$(date '+%b %e')" "$AUTH_LOG" 2>/dev/null | \
            grep "Accepted\|session opened for user" | grep -v "sudo" | \
            tail -10)
        if [[ -n "$success_logins" ]]; then
            echo "$success_logins" | while read -r line; do
                _bullet "${GREEN}$line${NC}"
            done
        else
            _ok "Không có đăng nhập SSH thành công hôm nay"
        fi
    else
        _warn "Không tìm thấy $AUTH_LOG"
    fi

    # ─────────────────────────────────────────
    # 8.2 Web Scanning / Attacks
    # ─────────────────────────────────────────
    echo ""
    echo -e "${BOLD}◆ Web Attack Patterns (từ access.log):${NC}"

    if [[ -f "$ACCESS_LOG" ]]; then
        # SQL Injection
        local sqli_count
        sqli_count=$(grep -c -iE \
            "union.*select|select.*from|drop.*table|insert.*into|\
            or.*1.*=.*1|and.*1.*=.*1|exec.*xp_|information_schema|\
            benchmark.*\(|sleep.*\(|load_file|outfile" \
            "$ACCESS_LOG" 2>/dev/null || echo "0")
        if [[ "$sqli_count" -gt 0 ]]; then
            _fail "SQL Injection attempts: ${RED}${sqli_count}${NC}"
            ((attack_count++))
            alert_write "SQL Injection: $sqli_count attempts"
        else
            _ok "SQL Injection: không phát hiện"
        fi

        # XSS
        local xss_count
        xss_count=$(grep -c -iE \
            "<script|javascript:|onerror=|onload=|alert\(|document\.cookie|\
            eval\(|src=.*javascript" \
            "$ACCESS_LOG" 2>/dev/null || echo "0")
        if [[ "$xss_count" -gt 0 ]]; then
            _fail "XSS attempts: ${RED}${xss_count}${NC}"
            ((attack_count++))
            alert_write "XSS: $xss_count attempts"
        else
            _ok "XSS: không phát hiện"
        fi

        # Path Traversal
        local traversal_count
        traversal_count=$(grep -c -E \
            "\.\./|\.\.%2f|%2e%2e/|/etc/passwd|/etc/shadow|\
            /proc/self|/var/www/|\.htaccess|\.htpasswd" \
            "$ACCESS_LOG" 2>/dev/null || echo "0")
        if [[ "$traversal_count" -gt 0 ]]; then
            _fail "Path Traversal attempts: ${RED}${traversal_count}${NC}"
            ((attack_count++))
            alert_write "Path Traversal: $traversal_count attempts"
        else
            _ok "Path Traversal: không phát hiện"
        fi

        # Scanner Tools
        local scanner_count
        scanner_count=$(grep -c -iE \
            "nikto|sqlmap|nmap|masscan|dirbuster|gobuster|wfuzz|\
            burpsuite|metasploit|zgrab|shodan|censys" \
            "$ACCESS_LOG" 2>/dev/null || echo "0")
        if [[ "$scanner_count" -gt 0 ]]; then
            _fail "Scanner tools detected: ${RED}${scanner_count}${NC}"
            ((attack_count++))
            alert_write "Security scanners: $scanner_count requests"
            # Hiển thị chi tiết scanner
            grep -iE "nikto|sqlmap|nmap|masscan|dirbuster|gobuster|wfuzz|burpsuite" \
                "$ACCESS_LOG" 2>/dev/null | awk '{print $1}' | \
                sort | uniq -c | sort -rn | head -5 | \
                while read -r c ip; do _bullet "Scanner IP: $ip ($c lần)"; done
        else
            _ok "Scanner tools: không phát hiện"
        fi

        # DDoS / Rate Limit: IP request quá nhiều trong giờ gần nhất
        echo ""
        echo -e "  ${YELLOW}IP request nhiều nhất (giờ gần nhất):${NC}"
        local current_hour; current_hour=$(date '+%d/%b/%Y:%H')
        local ddos_ips
        ddos_ips=$(grep "$current_hour" "$ACCESS_LOG" 2>/dev/null | \
            awk '{print $1}' | sort | uniq -c | sort -rn | head -5)
        
        if [[ -n "$ddos_ips" ]]; then
            echo "$ddos_ips" | while read -r count ip; do
                if [[ "$count" -ge "$BRUTE_FORCE_THRESHOLD" ]]; then
                    _fail "${RED}$ip: $count requests/giờ ⚠ DDoS?${NC}"
                    ((attack_count++))
                    alert_write "Potential DDoS from $ip: $count req/h"
                else
                    _bullet "$ip: $count requests/giờ"
                fi
            done
        fi

        # HTTP Methods bất thường
        echo ""
        echo -e "  ${YELLOW}HTTP Methods:${NC}"
        awk '{print $6}' "$ACCESS_LOG" 2>/dev/null | \
            tr -d '"' | sort | uniq -c | sort -rn | \
            while read -r count method; do
                case "$method" in
                    GET|POST|HEAD)
                        _bullet "$method: $count (bình thường)"
                        ;;
                    PUT|DELETE|PATCH)
                        _bullet "${YELLOW}$method: $count (chú ý)${NC}"
                        ;;
                    CONNECT|TRACE|OPTIONS)
                        if [[ "$count" -gt 10 ]]; then
                            _warn "$method: $count (nghi vấn!)"
                        fi
                        ;;
                    *)
                        [[ -n "$method" && "$method" != "-" ]] && \
                            _warn "Unknown method $method: $count"
                        ;;
                esac
            done
    fi

    # ─────────────────────────────────────────
    # 8.3 Sudo / Privilege Escalation
    # ─────────────────────────────────────────
    echo ""
    echo -e "${BOLD}◆ Sudo và Privilege Escalation:${NC}"

    if [[ -f "$AUTH_LOG" ]]; then
        local sudo_today
        sudo_today=$(grep "$(date '+%b %e')" "$AUTH_LOG" 2>/dev/null | \
            grep "sudo" | tail -10)
        if [[ -n "$sudo_today" ]]; then
            echo "$sudo_today" | while read -r line; do
                _bullet "$line"
            done
        else
            _ok "Không có hoạt động sudo hôm nay"
        fi

        # Su attempts (switch user)
        local su_attempts
        su_attempts=$(grep "$(date '+%b %e')" "$AUTH_LOG" 2>/dev/null | \
            grep -c "su:" 2>/dev/null || echo "0")
        if [[ "$su_attempts" -gt 0 ]]; then
            _warn "su command được dùng: $su_attempts lần hôm nay"
        fi
    fi

    # ─────────────────────────────────────────
    # 8.4 Tổng kết tấn công
    # ─────────────────────────────────────────
    echo ""
    if [[ "$attack_count" -gt 0 ]]; then
        echo -e "${RED}${BOLD}⚠  Phát hiện $attack_count loại tấn công! Kiểm tra ngay!${NC}"
        alert_write "TỔNG KẾT: $attack_count loại tấn công phát hiện"
        send_telegram "🔴 <b>SECURITY ALERT</b>: Phát hiện $attack_count loại tấn công trên $(hostname) lúc $(date)"
    else
        echo -e "${GREEN}${BOLD}✔  Không phát hiện tấn công nguy hiểm${NC}"
    fi

    log_write "INFO" "Attack detection: $attack_count loại tấn công"
}

# =============================================================================
#  PHẦN 9: PHÂN TÍCH ERROR LOG
# =============================================================================

analyze_error_log() {
    _section "WEB SERVER ERROR LOG"

    if [[ ! -f "$ERROR_LOG" ]]; then
        _warn "Error log không tìm thấy: $ERROR_LOG"
        return
    fi

    echo ""
    echo -e "${BOLD}◆ Phân loại lỗi (hôm nay):${NC}"

    local today; today=$(date '+%Y/%m/%d')

    # Nginx error levels
    local levels=("emerg" "alert" "crit" "error" "warn" "notice")
    for level in "${levels[@]}"; do
        local count
        count=$(grep -c "\[$level\]" "$ERROR_LOG" 2>/dev/null || echo "0")
        if [[ "$count" -gt 0 ]]; then
            case "$level" in
                emerg|alert|crit)
                    _fail "$level: ${RED}$count${NC}"
                    alert_write "Web server [$level]: $count errors"
                    ;;
                error)
                    if [[ "$count" -gt 100 ]]; then
                        _warn "$level: ${YELLOW}$count${NC} (nhiều)"
                    else
                        _bullet "$level: $count"
                    fi
                    ;;
                *)
                    _bullet "$level: $count"
                    ;;
            esac
        fi
    done

    echo ""
    echo -e "${BOLD}◆ 10 lỗi gần nhất:${NC}"
    grep -E "\[error\]|\[crit\]|\[alert\]" "$ERROR_LOG" 2>/dev/null | \
        tail -10 | while read -r line; do
            local short; short=$(echo "$line" | cut -c1-120)
            _bullet "$short"
        done

    log_write "INFO" "Error log phân tích hoàn thành"
}

# =============================================================================
#  PHẦN 10: GIÁM SÁT REALTIME
# =============================================================================

realtime_monitor() {
    _section "GIÁM SÁT REALTIME (Ctrl+C để dừng)"

    if [[ ! -f "$ACCESS_LOG" ]]; then
        _fail "Không tìm thấy access log: $ACCESS_LOG"
        exit 1
    fi

    echo ""
    echo -e "${CYAN}Đang giám sát: $ACCESS_LOG${NC}"
    echo -e "${YELLOW}Hiển thị request realtime + cảnh báo tự động${NC}"
    echo ""

    # Theo dõi access log realtime, highlight theo status code
    tail -f "$ACCESS_LOG" 2>/dev/null | while read -r line; do
        local status_code; status_code=$(echo "$line" | awk '{print $9}')
        local ip;          ip=$(echo "$line" | awk '{print $1}')
        local method;      method=$(echo "$line" | awk '{print $6}' | tr -d '"')
        local url;         url=$(echo "$line" | awk '{print $7}')

        # Màu theo status code
        case "${status_code:0:1}" in
            2) printf "${GREEN}[%s] %s %-7s %s${NC}\n" \
                "$(date '+%H:%M:%S')" "$ip" "$method" "$url" ;;
            3) printf "${CYAN}[%s] %s %-7s %s${NC}\n" \
                "$(date '+%H:%M:%S')" "$ip" "$method" "$url" ;;
            4) printf "${YELLOW}[%s] %s %-7s %s → HTTP $status_code${NC}\n" \
                "$(date '+%H:%M:%S')" "$ip" "$method" "$url" ;;
            5) printf "${RED}[%s] %s %-7s %s → HTTP $status_code !!${NC}\n" \
                "$(date '+%H:%M:%S')" "$ip" "$method" "$url" ;;
            *) echo "[$( date '+%H:%M:%S')] $line" ;;
        esac

        # Phát hiện pattern nguy hiểm realtime
        if echo "$line" | grep -qiE \
            "union.*select|<script|\.\.\/|/etc/passwd|sqlmap|nikto"; then
            echo -e "${RED}${BOLD}⚠  ATTACK DETECTED! IP: $ip URL: $url${NC}"
            alert_write "REALTIME ATTACK: $ip → $url"
        fi
    done
}

# =============================================================================
#  PHẦN 11: BÁO CÁO TỔNG HỢP
# =============================================================================

generate_summary() {
    _section "TÓM TẮT BÁO CÁO"

    local report_time; report_time=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname;    hostname=$(hostname)
    local ip;          ip=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${BOLD}Máy chủ   :${NC} $hostname ($ip)"
    echo -e "${BOLD}Thời gian :${NC} $report_time"
    echo -e "${BOLD}Uptime    :${NC} $(uptime -p)"
    echo -e "${BOLD}Báo cáo   :${NC} $REPORT_FILE"
    echo -e "${BOLD}Alerts    :${NC} $ALERT_FILE"
    echo ""

    # Đếm alerts
    local alert_count
    alert_count=$(wc -l < "$ALERT_FILE" 2>/dev/null || echo "0")
    if [[ "$alert_count" -gt 0 ]]; then
        echo -e "${RED}${BOLD}⚠  Có $alert_count cảnh báo! Xem: $ALERT_FILE${NC}"
    else
        echo -e "${GREEN}${BOLD}✔  Không có cảnh báo nào${NC}"
    fi

    # Lưu summary hàng ngày
    {
        echo "=========================================="
        echo "  DAILY SUMMARY: $report_time"
        echo "  Host: $hostname ($ip)"
        echo "=========================================="
        echo "Alerts: $alert_count"
        cat "$ALERT_FILE" 2>/dev/null
        echo ""
    } >> "$SUMMARY_FILE"

    echo ""
    echo -e "─────────────────────────────────────────"
    echo -e "Báo cáo lưu tại: ${CYAN}$REPORT_FILE${NC}"
    echo -e "─────────────────────────────────────────"
}

# =============================================================================
#  PHẦN 12: INSTALL / SETUP
# =============================================================================

install_setup() {
    _section "INSTALL & SETUP — Cấu hình hệ thống"

    echo ""
    echo -e "${BOLD}Cài đặt các công cụ cần thiết...${NC}"

    # Cài đặt packages
    apt-get install -y \
        fail2ban \
        logwatch \
        rsyslog \
        mailutils 2>/dev/null || true

    echo ""
    echo -e "${BOLD}Cấu hình logrotate cho $WEB_SERVER...${NC}"

    # Tạo logrotate config cho nginx
    cat > "/etc/logrotate.d/${WEB_SERVER}_custom" << 'LOGROTATE'
/var/log/nginx/access.log
/var/log/nginx/error.log
/var/log/nginx/*.log {
    daily                   # Rotate mỗi ngày
    missingok               # Không lỗi nếu file không tồn tại
    rotate 30               # Giữ 30 bản backup
    compress                # Nén file cũ bằng gzip
    delaycompress           # Giữ file hôm qua chưa nén (nginx vẫn ghi)
    notifempty              # Không rotate nếu file rỗng
    create 0640 www-data adm  # Tạo file mới với quyền này
    sharedscripts           # Chạy postrotate 1 lần dù nhiều files
    postrotate
        # Reload nginx để dùng file log mới
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 $(cat /var/run/nginx.pid)
        fi
    endscript
}
LOGROTATE
    _ok "logrotate config tạo tại: /etc/logrotate.d/${WEB_SERVER}_custom"

    echo ""
    echo -e "${BOLD}Cấu hình rsyslog remote logging...${NC}"
    cat > "/etc/rsyslog.d/99-webserver.conf" << 'RSYSLOG'
# Ghi auth log riêng (SSH, sudo, login)
auth,authpriv.*     /var/log/auth.log

# Ghi kernel log riêng
kern.*              /var/log/kern.log

# Ghi cron log riêng
cron.*              /var/log/cron.log

# Ghi lỗi nghiêm trọng ra file riêng
*.emerg             /var/log/emergency.log
*.crit              /var/log/critical.log

# Nếu muốn gửi log đến remote server, bỏ comment dòng dưới:
# *.* @192.168.1.200:514     # UDP
# *.* @@192.168.1.200:514    # TCP (tin cậy hơn)
RSYSLOG
    _ok "rsyslog config tạo tại: /etc/rsyslog.d/99-webserver.conf"
    systemctl restart rsyslog 2>/dev/null || true

    echo ""
    echo -e "${BOLD}Cấu hình fail2ban cho SSH và nginx...${NC}"
    cat > "/etc/fail2ban/jail.d/webserver.conf" << 'FAIL2BAN'
[DEFAULT]
bantime  = 3600       # Ban 1 giờ
findtime = 600        # Trong 10 phút
maxretry = 5          # 5 lần thất bại
ignoreip = 127.0.0.1/8 ::1   # Không ban localhost

[sshd]
enabled  = true
port     = ssh
logpath  = /var/log/auth.log
maxretry = 3          # SSH chỉ cho 3 lần
bantime  = 86400      # Ban SSH 24 giờ

[nginx-http-auth]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
maxretry = 5

[nginx-botsearch]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/access.log
maxretry = 2
FAIL2BAN
    systemctl enable fail2ban 2>/dev/null || true
    systemctl restart fail2ban 2>/dev/null || true
    _ok "fail2ban config tạo và khởi động"

    echo ""
    echo -e "${BOLD}Thiết lập cron job chạy monitor mỗi giờ...${NC}"
    local script_path; script_path=$(realpath "$0")
    local cron_job="0 * * * * root bash $script_path --full-report >> /var/log/webserver_monitor/cron.log 2>&1"
    
    # Thêm vào crontab nếu chưa có
    if ! crontab -l 2>/dev/null | grep -q "weblog_monitor"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        _ok "Cron job thêm thành công: mỗi giờ"
    else
        _warn "Cron job đã tồn tại"
    fi

    echo ""
    _ok "${GREEN}${BOLD}Cài đặt hoàn thành!${NC}"
    echo ""
    echo -e "  Chạy báo cáo đầy đủ : ${CYAN}sudo bash $0 --full-report${NC}"
    echo -e "  Giám sát realtime   : ${CYAN}sudo bash $0 --realtime${NC}"
    echo -e "  Kiểm tra tấn công   : ${CYAN}sudo bash $0 --attack-check${NC}"
}

# =============================================================================
#  MAIN — XỬ LÝ THAM SỐ
# =============================================================================

main() {
    check_requirements

    # In header
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║      WEB SERVER LOG MONITOR — Ubuntu 22.04           ║"
    echo "║      $(date '+%Y-%m-%d %H:%M:%S')  |  $(hostname)  "
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    local option="${1:---full-report}"

    case "$option" in
        --full-report)
            check_reboot_shutdown
            check_journalctl
            check_logrotate
            check_rsyslog
            check_security_baseline
            check_system_health
            analyze_web_logs
            analyze_error_log
            detect_attacks
            generate_summary
            ;;
        --realtime)
            realtime_monitor
            ;;
        --attack-check)
            detect_attacks
            ;;
        --system-health)
            check_system_health
            check_journalctl
            ;;
        --install)
            install_setup
            ;;
        --help|-h)
            echo "Cách dùng: sudo bash $0 [OPTION]"
            echo ""
            echo "  --full-report    Báo cáo toàn bộ (mặc định)"
            echo "  --realtime       Giám sát realtime"
            echo "  --attack-check   Chỉ kiểm tra tấn công"
            echo "  --system-health  Chỉ kiểm tra sức khỏe hệ thống"
            echo "  --install        Cài đặt cấu hình (logrotate, fail2ban...)"
            echo "  --help           Hiển thị trợ giúp này"
            ;;
        *)
            echo "Option không hợp lệ: $option"
            echo "Dùng --help để xem hướng dẫn"
            exit 1
            ;;
    esac
}

main "$@"
