#!/bin/bash

# Функция для проверки, выполняется ли скрипт от имени root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Вы не выполнили вход как root. Пожалуйста, используйте 'sudo -i' для получения прав root."
        exit 1
    fi
}

# Проверяем права root
check_root

# Объявление переменной для логирования и создание файла логов в /tmp по наименованию скрипта
LOGFILE="/tmp/$(basename "$0").log"

# Функция для записи сообщений в лог-файл
log_message() {
    local message="$1"
    echo "$message" >> "$LOGFILE"
}

# Функция для вывода сообщений о старте и финише
print_message() {
    local message="$1"
    echo "$message"
}

# Перенаправляем stdout и stderr всех команд в лог-файл
exec > >(tee -a "$LOGFILE") 2>&1

# Вывод и запись сообщения о начале выполнения скрипта
print_message "Начало"
log_message "Начало"

# Очистка файлов журналов
log_files=(
    "/var/log/syslog"
    "/var/log/auth.log"
    "/var/log/kern.log"
    "/var/log/dmesg"
    "/var/log/ufw.log"
)

for log_file in "${log_files[@]}"; do
    if [ -f "$log_file" ]; then
        log_message "Очищаем $log_file"  # Это сообщение будет направлено в лог
        truncate -s 0 "$log_file"
    fi
done

# Очистка буфера dmesg
log_message "Очищаем буфер dmesg"  # Это сообщение будет направлено в лог
dmesg -C

# Очистка кэша DNS
log_message "Очищаем кэш DNS"  # Это сообщение будет направлено в лог
systemctl restart systemd-resolved
if [ -x "$(command -v nscd)" ]; then
    systemctl restart nscd
fi

# Очистка статистики сетевых интерфейсов
network_interfaces=$(ip -o link show | awk -F': ' '{print $2}')
for interface in $network_interfaces; do
    log_message "Очищаем статистику для интерфейса $interface"  # Это сообщение будет направлено в лог
    ip link set "$interface" down
    ip link set "$interface" up
done

# Очистка правил iptables
log_message "Очищаем счетчики iptables"  # Это сообщение будет направлено в лог
# Сброс счетчиков в таблице filter (по умолчанию)
iptables -Z 
# Сброс счетчиков в таблице nat
iptables -t nat -Z 
# Сброс счетчиков в таблице mangle
iptables -t mangle -Z

# Очистка истории входов в систему
for log_file in /var/log/wtmp /var/log/btmp /var/log/lastlog; do
    if [ -f "$log_file" ]; then
        log_message "Очищаем $log_file"  # Это сообщение будет направлено в лог
        truncate -s 0 "$log_file"
    fi
done

# Удаление информации о ранее использованных IP и DNS
log_message "Очищаем информацию о ранее использованных IP и DNS"  # Это сообщение будет направлено в лог
rm -f /var/lib/dhcp/dhclient*.leases

# Очистка истории команд
log_message "Очищаем историю команд"  # Это сообщение будет направлено в лог
history -c
history -w
rm -f ~/.bash_history

# Вывод и запись сообщения о завершении выполнения скрипта
print_message "Конец"
log_message "Конец"

```
