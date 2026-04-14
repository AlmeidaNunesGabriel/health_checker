#!/bin/bash

#1. Limites para Alertas
THRESHOLD_RAM=90
THRESHOLD_CPU=80
THRESHOLD_DISK=90
THRESHOLD_TEMP=75

#CORES

RED='\e[31m'
YELLOW='\e[33m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

#2. Funções

report_cpu(){
	echo -e "${CYAN}${BOLD}--- CPU --- ${RESET}"
	#lÊ /proc/stat duas vezes para calcular o uso rea
	local user1 nice1 sys1 idle1 iowait1 irq1 sirq1
	local user2 nice2 sys2 idle2 iowait2 irq2 sirq2

	read -r _ user1 nice1 sys1 idle1 iowait1 irq1 sirq1 _ < /proc/stat
	sleep 0.5
	read -r _ user2 nice2 sys2 idle2 iowait2 irq2 sirq2 _ < /proc/stat

	local total1=$(( user1 + nice1 + sys1 + idle1 + iowait1 +irq1 + sirq1))
	local total2=$((user2 + nice2 + sys2 +idle2 + iowait2 +irq2 + sirq2))
	local diff_total=$((total2 - total1))
	local diff_idle=$((idle2 - idle1))
	local used_pct=$(( (diff_total - diff_idle) * 100 / diff_total ))

	local load 
	load=$(uptime | awk -F'load average:' '{print $2}' | xargs)

	printf "Uso Total: %d%%\n" "$used_pct"
	echo "Media de Carga: $load"

	if [ "$used_pct" -gt "$THRESHOLD_CPU" ]; then
		echo -e "${RED}[ALERTA] Uso do CPU acima de ${THRESHOLD_CPU}%!${RESET}"
	fi
}

report_ram(){
	echo -e "${CYAN}${BOLD}--- MEMORIA RAM ---${RESET}"
	free -h

	# usa /proc/meminfo para calcular % (apenas inteiros)
	local total available used ram_pct
	total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
	available=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
	used=$(( total - available ))
	ram_pct=$(( used * 100 / total))

	echo "Porcentagem de Uso: ${ram_pct}%"
	if [ "$ram_pct" -gt "$THRESHOLD_RAM" ]; then
		echo -e "${RED}[ALERTA] RAM crítica: ${ram_pct}%!${RESET}"
	fi
}

report_disk(){
	echo -e "${CYAN}${BOLD}--- DISCOS ---${RESET}"
	df -h / | tail -n 1 | awk '{print "Uso: " $3 " usado / " $2 " total ( " $5 " ) "}'

	#tr -d remove o % antes da comparação

	local disk_pct
	disk_pct=$(df / | tail -n 1 | awk '{print $5}' | tr -d '%')

	if [ -n "$disk_pct" ] &&  [ "$disk_pct" -gt "$THRESHOLD_DISK" ]; then
		echo -e "${RED}[ALERTA] Espaço em disco insuficiente!${RESET}":
	fi
}

report_temp(){
	echo -e "${CYAN}${BOLD}--- TEMPERATURA ---${RESET}"
	
	if command -v sensors &>/dev/null; then
		local temp_c
		temp_c=$(sensors | awk '/Tctl/{gsub(/[^0-9.]/,"",$2); print int($2)}')
		
		if [ -n "$temp_c" ]; then
			echo "Temperatura CPU (Tct1): ${temp_c} ºC"
			if [ "$temp_c" -gt "$THRESHOLD_TEMP" ]; then 
				echo -e "${RED}[ALERTA] Superaquecimento detectado: ${temp_c}ºC${RESET}"
			fi
		else
			echo "Sensor não encontrado."
		fi
	else
		echo -e "${YELLOW}1m-sensors não instalado. Rode: sudo apt install 1m-sensors${RESET}"
	fi

}


report_top_processos(){

	echo -e "${CYAN}${BOLD}--- TOP 5 PROCESSOS(CPU) ---${RESET}"
	ps aux --sort=-%cpu | head -n 6 | cut -c 1-100

	echo ""
	
	echo -e "${CYAN}${BOLD} --- TOP 5 PROCESSOS (MEMORIA) ---${RESET}"
	ps aux --sort=-%mem | head -n 6 | cut -c 1-100
}


#3. Execução Principal

clear
echo -e "${BOLD}=====================${RESET}"
echo -e "${BOLD}RELATORIO DE SAUDE - $(date)${RESET}"
echo -e "${BOLD}=====================${RESET}"
echo ""
report_cpu
echo ""
report_ram
echo ""
report_disk
echo ""
report_temp
echo ""
report_top_processos

