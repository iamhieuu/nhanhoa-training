#!/bin/bash
# File: /tmp/capture_and_analyze.sh
# Script tự động bắt và phân tích gói tin

# ===== CẤU HÌNH =====
INTERFACE="ens33"
CAPTURE_DIR="/var/log/tcpdump"
DURATION=30  
FILTER="port 80 or port 443 or port 53"

# ===== KIỂM TRA QUYỀN =====
if [[ $EUID -ne 0 ]]; then
   echo "❌ Cần chạy với sudo!"
   echo "   Dùng: sudo bash /tmp/capture_and_analyze.sh"
   exit 1
fi

# ===== KIỂM TRA CÔNG CỤ =====
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "⚠️  $1 chưa cài. Cài đặt: sudo apt install $2"
        return 1
    fi
    return 0
}

check_tool tcpdump tcpdump || exit 1
check_tool tshark tshark   || exit 1

# ===== TẠO THƯ MỤC =====
mkdir -p $CAPTURE_DIR
FILENAME="$CAPTURE_DIR/capture_$(date +%Y%m%d_%H%M%S).pcap"

# ===== THÔNG TIN =====
echo "======================================"
echo "  Auto Capture & Analyze Script"
echo "======================================"
echo "Interface : $INTERFACE"
echo "Filter    : $FILTER"
echo "Duration  : ${DURATION}s"
echo "Output    : $FILENAME"
echo "======================================"
echo ""

echo "📡 Bắt đầu capture..."
timeout $DURATION tcpdump -i $INTERFACE \
    -f "$FILTER" \
    -s 0 \
    -n \
    -w $FILENAME 2>/dev/null &

TCPDUMP_PID=$!
echo "   TCPDump PID: $TCPDUMP_PID"
echo "   Đang capture trong ${DURATION} giây..."

for i in $(seq $DURATION -1 1); do
    printf "\r   Còn lại: %2d giây..." $i
    sleep 1
done
echo ""

wait $TCPDUMP_PID 2>/dev/null
echo "   ✅ Capture hoàn thành!"
echo ""

# ===== KIỂM TRA FILE =====
if [ ! -f "$FILENAME" ]; then
    echo "❌ File không được tạo!"
    exit 1
fi

FILE_SIZE=$(du -sh "$FILENAME" | cut -f1)
echo "📁 File: $FILENAME ($FILE_SIZE)"
echo ""

echo "======================================"
echo "  Kết Quả Phân Tích"
echo "======================================"

TOTAL=$(tshark -r $FILENAME -q 2>/dev/null | wc -l)
echo "📊 Tổng gói tin: $TOTAL"

echo ""
echo "📋 Phân loại giao thức:"
tshark -r $FILENAME -q -z io,phs 2>/dev/null | \
    grep -E "tcp|udp|dns|http|icmp" | \
    awk '{printf "   %-20s: %s frames\n", $1, $2}'

echo ""
echo "🌐 Top 5 IP nguồn:"
tshark -r $FILENAME -T fields -e ip.src 2>/dev/null | \
    sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "   %-20s: %s packets\n", $2, $1}'

echo ""
echo "🎯 Top 5 IP đích:"
tshark -r $FILENAME -T fields -e ip.dst 2>/dev/null | \
    sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "   %-20s: %s packets\n", $2, $1}'

echo ""
echo "🔍 DNS Queries:"
tshark -r $FILENAME -Y dns -T fields -e dns.qry.name 2>/dev/null | \
    grep -v "^$" | sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "   %-40s: %s queries\n", $2, $1}'

echo ""
echo "======================================"
echo "✅ Hoàn thành! File lưu tại: $FILENAME"
echo ""
echo "📌 Để phân tích thêm:"
echo "   tshark -r $FILENAME -Y 'http'"
echo "   tshark -r $FILENAME -Y 'dns'"
echo "   tshark -r $FILENAME -q -z conv,tcp"
echo ""
echo "📌 Copy về máy local để dùng Wireshark:"
echo "   scp $(hostname -I | awk '{print $1}'):$FILENAME ~/Downloads/"
echo "======================================"
