#!/bin/bash

# Определение самых быстрых для QTH серверов Brandmeister
# https://brandmeister.network/#/masters
# Version 2.20260828 by R7KIN 

# Список мастер-серверов BrandMeister в формате "домен|страна"
servers=(
    "2022.master.brandmeister.network|Греция (GR)"
    "2041.master.brandmeister.network|Нидерланды (NL)"
    "2061.master.brandmeister.network|Бельгия (BE)"
    "2081.master.brandmeister.network|Франция 1 (FR)"
    "2082.master.brandmeister.network|Франция 2 (FR)"
    "2141.master.brandmeister.network|Испания (ES)"
    "2162.master.brandmeister.network|Венгрия (HU)"
    "2221.master.brandmeister.network|Италия 1 (IT)"
    "2222.master.brandmeister.network|Италия 2 (IT)"
    "2262.master.brandmeister.network|Румыния (RO)"
    "2282.master.brandmeister.network|Швейцария (CH)"
    "2302.master.brandmeister.network|Чехия (CZ)"
    "2322.master.brandmeister.network|Австрия (AT)"
    "2341.master.brandmeister.network|Великобритания 1 (GB)"
    "2342.master.brandmeister.network|Великобритания 2 (GB)"
    "2382.master.brandmeister.network|Дания (DK)"
    "2402.master.brandmeister.network|Швеция (SE)"
    "2421.master.brandmeister.network|Норвегия (NO)"
    "2441.master.brandmeister.network|Финляндия (FI)"
    "2501.master.brandmeister.network|Россия 1 (RU)"
    "2502.master.brandmeister.network|Россия 2 (RU)"
    "2503.master.brandmeister.network|Россия 3 (RU)"
    "2601.master.brandmeister.network|Польша 1 (PL)"
    "2602.master.brandmeister.network|Польша 2 (PL)"
    "2621.master.brandmeister.network|Германия 1 (DE)"
    "2622.master.brandmeister.network|Германия 2 (DE)"
    "2682.master.brandmeister.network|Португалия (PT)"
    "2721.master.brandmeister.network|Ирландия (IE)"
    "2841.master.brandmeister.network|Болгария (BG)"
    "2931.master.brandmeister.network|Словения (SI)"
    "3021.master.brandmeister.network|Канада (CA)"
    "3101.master.brandmeister.network|США 1 (US)"
    "3102.master.brandmeister.network|США 2 (US)"
    "3103.master.brandmeister.network|США 3 (US)"
    "3104.master.brandmeister.network|США 4 (US)"
    "3341.master.brandmeister.network|Мексика (MX)"
    "4251.master.brandmeister.network|Израиль (IL)"
    "4501.master.brandmeister.network|Южная Корея (KR)"
    "4602.master.brandmeister.network|Китай (CN)"
    "5021.master.brandmeister.network|Малайзия (MY)"
    "5051.master.brandmeister.network|Австралия (AU)"
    "5151.master.brandmeister.network|Филиппины (PH)"
    "6551.master.brandmeister.network|ЮАР (ZA)"
    "7242.master.brandmeister.network|Бразилия (BR)"
    "7301.master.brandmeister.network|Чили (CL)"
)

total_count=${#servers[@]}
echo "Опрос $total_count серверов (по 3 пакета на каждый). Пожалуйста, подождите..."

results=()

for entry in "${servers[@]}"; do
    IFS="|" read -r server country <<< "$entry"

    # Пингуем сервер (3 пакета, таймаут 2 секунды)
    ping_out=$(ping -c 3 -W 2 -q "$server" 2>/dev/null | tail -n 1)

    if [[ $ping_out == rtt* ]]; then
        # Извлекаем среднее значение пинга
        avg=$(echo "$ping_out" | awk '{print $4}' | cut -d '/' -f 2)
        results+=("$avg|$server|$country")
    else
        # Если сервер не ответил
        results+=("9999.9|$server|$country")
    fi
done

# Сортируем полный список по задержке
sorted_raw=$(printf "%s\n" "${results[@]}" | sort -n -t '|' -k1,1)

echo -e "\nТоп-5 самых быстрых серверов:"
echo "-------------------------------------------------------------------------"
printf "%-7s %-38s %-20s %-15s\n" "Место" "Сервер" "Страна" "Средний пинг"
echo "-------------------------------------------------------------------------"

rank=1
ru_ranks=()

while IFS="|" read -r ping server country; do
    # Печать первых 5 мест
    if [[ $rank -le 5 ]]; then
        if [[ "$ping" == "9999.9" ]]; then
            printf "%-7s %-38s %-20s %-15s\n" "#$rank" "$server" "$country" "Недоступен"
        else
            printf "%-7s %-38s %-20s %-15s\n" "#$rank" "$server" "$country" "${ping} мс"
        fi
    fi

    # Фиксация позиций российских серверов
    if [[ "$country" == *"Россия"* ]]; then
        ru_ranks+=("$rank|$server|$country|$ping")
    fi

    ((rank++))
done <<< "$sorted_raw"

echo -e "\nПоложение российских серверов в общем рейтинге (из $total_count серверов):"
echo "-------------------------------------------------------------------------"
printf "%-7s %-38s %-20s %-15s\n" "Место" "Сервер" "Страна" "Средний пинг"
echo "-------------------------------------------------------------------------"

for ru_entry in "${ru_ranks[@]}"; do
    IFS="|" read -r r_rank r_server r_country r_ping <<< "$ru_entry"
    if [[ "$r_ping" == "9999.9" ]]; then
        printf "%-7s %-38s %-20s %-15s\n" "#$r_rank" "$r_server" "$r_country" "Недоступен"
    else
        printf "%-7s %-38s %-20s %-15s\n" "#$r_rank" "$r_server" "$r_country" "${r_ping} мс"
    fi
done
