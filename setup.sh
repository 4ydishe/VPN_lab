#!/bin/bash
set -e

MODE="${1:-tap}"   # Режим туннеля: tap или tun
ROLE="$2"          # Роль машины: server или client

if [[ "$ROLE" != "server" && "$ROLE" != "client" ]]; then
  echo "Usage: $0 [tap|tun] [server|client]"
  exit 1
fi

echo "[INFO] Установка зависимостей..."
sudo apt update
sudo apt install -y openvpn iperf3 selinux-utils

echo "[INFO] Отключение SELinux (если активно)..."
setenforce 0 2>/dev/null || true

echo "[INFO] Создание systemd unit-файла OpenVPN..."
sudo tee /etc/systemd/system/openvpn@.service > /dev/null <<EOF
[Unit]
Description=OpenVPN Tunneling Application On %%I
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn --config %%I.conf

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Общие IP-адреса
SERVER_VPN_IP="10.10.10.1"
CLIENT_VPN_IP="10.10.10.2"
NETMASK="255.255.255.0"

if [[ "$ROLE" == "server" ]]; then
  echo "[INFO] Настройка сервера OpenVPN..."

  if [[ ! -f /etc/openvpn/static.key ]]; then
    echo "[INFO] Генерация ключа static.key..."
    sudo openvpn --genkey --secret /etc/openvpn/static.key
  fi

  echo "[INFO] Создание /etc/openvpn/server.conf..."
  sudo tee /etc/openvpn/server.conf > /dev/null <<EOF
dev $MODE
ifconfig $SERVER_VPN_IP $NETMASK
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
EOF

  echo "[INFO] Запуск OpenVPN на сервере..."
  sudo systemctl enable --now openvpn@server

  echo "[INFO] Запуск iperf3-сервера..."
  nohup iperf3 -s > /dev/null 2>&1 &

  echo "[ACTION REQUIRED] Скопируй ключ на клиент:"
  echo "scp /etc/openvpn/static.key vagrant@192.168.56.20:/home/vagrant/static.key"
  echo "Затем на клиенте: sudo cp /home/vagrant/static.key /etc/openvpn/static.key && sudo chmod 600 ..."

elif [[ "$ROLE" == "client" ]]; then
  echo "[INFO] Подготовка клиента OpenVPN..."

  if [[ ! -f /etc/openvpn/static.key ]]; then
    if [[ -f /home/vagrant/static.key ]]; then
      echo "[INFO] Копируем static.key в /etc/openvpn..."
      sudo cp /home/vagrant/static.key /etc/openvpn/static.key
      sudo chmod 600 /etc/openvpn/static.key
    else
      echo "[ERROR] Нет /etc/openvpn/static.key и /home/vagrant/static.key"
      echo "➡️ Сначала скопируй ключ с сервера:"
      echo "scp vagrant@192.168.56.10:/etc/openvpn/static.key /home/vagrant/static.key"
      exit 1
    fi
  fi

  echo "[INFO] Создание /etc/openvpn/server.conf (клиент)..."
  sudo tee /etc/openvpn/server.conf > /dev/null <<EOF
dev $MODE
remote 192.168.56.10
ifconfig $CLIENT_VPN_IP $NETMASK
topology subnet
route 192.168.56.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
EOF

  echo "[INFO] Запуск OpenVPN на клиенте..."
  sudo systemctl enable --now openvpn@server

  echo "[INFO] Ожидание туннеля..."
  sleep 2
  ip a | grep $CLIENT_VPN_IP || echo "[WARN] Интерфейс ещё не поднят"

  echo "[INFO] Проверка пинга до сервера ($SERVER_VPN_IP)..."
  ping -c 4 $SERVER_VPN_IP || echo "[WARN] Ping не прошёл — проверь сервер"

  echo "[INFO] Тест скорости (iperf3)..."
  iperf3 -c $SERVER_VPN_IP -t 10 -i 2
fi
