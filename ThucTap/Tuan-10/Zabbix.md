# Labs thực hành cài đặt zabbix

Lab 01 — Cài đặt Zabbix 7.0 LTS trên Ubuntu 22.04
Sơ đồ mô hình Lab:
┌─────────────────────────────────────────────────┐
│  VMware / VirtualBox Lab Environment            │
│                                                 │
│  ┌──────────────────────┐   ┌────────────────┐  │
│  │  zabbix-server       │   │  zabbix-agent  │  │
│  │  Ubuntu 22.04        │   │  Ubuntu 22.04  │  │
│  │  192.168.56.10       │   │  192.168.56.20 │  │
│  │  RAM: 4GB, Disk: 40G │   │  RAM: 1GB      │  │
│  └──────────────────────┘   └────────────────┘  │
│                                                 │
│  Host-only Network: 192.168.56.0/24             │
└─────────────────────────────────────────────────┘
