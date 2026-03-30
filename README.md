# 🖥️ health_checker.sh

Script Bash para monitoramento de saúde do sistema Linux em tempo real, com alertas coloridos no terminal.

---

## 📋 O que o script faz

Ao executar, exibe um relatório completo com:

-  Uso total da CPU (calculado via `/proc/stat`)
-  Uso de memória RAM (livre vs usado + porcentagem)
-  Uso de disco (livre vs usado + porcentagem)
-  Temperatura da CPU (via `lm-sensors`)
-  Top 5 processos por CPU
-  Top 5 processos por Memória
-  Alertas em vermelho quando um limite é ultrapassado

---

## ⚙️ Pré-requisitos

- Sistema Linux (Debian/Ubuntu recomendado)
- Bash 4+
- `lm-sensors` (opcional, para leitura de temperatura):

```bash
sudo apt install lm-sensors -y
sudo sensors-detect
```

---

## 🚀 Como executar

**1. Clone o repositório:**
```bash
git clone https://github.com/seu-usuario/health-checker.git
cd health-checker
```

**2. Dê permissão de execução:**
```bash
chmod +x health_checker.sh
```

**3. Execute:**
```bash
./health_checker.sh
```

---

## 🔧 Configuração de Alertas

No topo do script você pode ajustar os limites de alerta:

```bash
THRESHOLD_RAM=90    # Alerta se RAM > 90%
THRESHOLD_CPU=80    # Alerta se CPU > 80%
THRESHOLD_DISK=90   # Alerta se Disco > 90%
THRESHOLD_TEMP=75   # Alerta se Temperatura > 75°C
```

---

## 📖 Explicação linha a linha

### Shebang e Limites

```bash
#!/bin/bash
```
Define que o script deve ser interpretado pelo Bash.

```bash
THRESHOLD_RAM=90
THRESHOLD_CPU=80
THRESHOLD_DISK=90
THRESHOLD_TEMP=75
```
Variáveis globais com os limites percentuais para disparar alertas. Podem ser editadas conforme a necessidade.

---

### Cores do Terminal

```bash
RED='\e[31m'
YELLO='\e[33m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'
```
Códigos ANSI de escape para colorir o terminal. O `RESET` é usado ao final de cada linha colorida para não "vazar" a cor para o restante do output.

---

### `report_cpu()` — Uso da CPU

```bash
local user1 nice1 sys1 idle1 iowait1 irq1 sirq1
local user2 nice2 sys2 idle2 iowait2 irq2 sirq2
```
Declara variáveis locais para armazenar os contadores de CPU lidos do sistema em dois momentos diferentes.

```bash
read -r _ user1 nice1 sys1 idle1 iowait1 irq1 sirq1 _ < /proc/stat
sleep 0.5
read -r _ user2 nice2 sys2 idle2 iowait2 irq2 sirq2 _ < /proc/stat
```
Lê o arquivo `/proc/stat` duas vezes com 0.5 segundo de intervalo. Esse arquivo contém os ticks de CPU acumulados desde o boot. A diferença entre as duas leituras representa o que aconteceu nesse intervalo — é assim que se calcula o uso real da CPU sem depender de ferramentas externas como `top` ou `bc`.

```bash
local total1=$(( user1 + nice1 + sys1 + idle1 + iowait1 + irq1 + sirq1 ))
local total2=$(( user2 + nice2 + sys2 + idle2 + iowait2 + irq2 + sirq2 ))
```
Soma todos os contadores de cada leitura para obter o total de ticks.

```bash
local diff_total=$(( total2 - total1 ))
local diff_idle=$(( idle2 - idle1 ))
local used_pct=$(( (diff_total - diff_idle) * 100 / diff_total ))
```
Calcula a diferença de ticks totais e de ticks ociosos (idle). O uso da CPU é: `(total - idle) / total * 100`. Aritmética inteira nativa do Bash, sem precisar de `bc`.

```bash
load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
```
Extrai a média de carga do sistema do comando `uptime`, usando `awk` para pegar tudo após "load average:" e `xargs` para remover espaços extras.

```bash
if [ "$used_pct" -gt "$THRESHOLD_CPU" ]; then
    echo -e "${RED}[ALERTA] Uso do CPU acima de ${THRESHOLD_CPU}%!${RESET}"
fi
```
Compara o uso calculado com o limite definido. Se ultrapassar, exibe alerta em vermelho.

---

### `report_ram()` — Uso de Memória RAM

```bash
free -h
```
Exibe a tabela completa de memória em formato legível (GB/MB).

```bash
total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
available=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
```
Lê diretamente do `/proc/meminfo` os valores brutos em kB. `MemAvailable` é mais preciso que `MemFree` pois inclui cache disponível para reutilização.

```bash
used=$(( total - available ))
ram_pct=$(( used * 100 / total ))
```
Calcula a memória usada e converte para porcentagem usando aritmética inteira do Bash.

```bash
if [ "$ram_pct" -gt "$THRESHOLD_RAM" ]; then
    echo -e "${RED}[ALERTA] RAM crítica: ${ram_pct}%!${RESET}"
fi
```
Dispara o alerta se o uso ultrapassar o limite configurado.

---

### `report_disk()` — Uso de Disco

```bash
df -h / | tail -n 1 | awk '{print "Uso: " $3 " usado / " $2 " total ( " $5 " ) "}'
```
`df -h /` mostra o uso da partição raiz. `tail -n 1` pega só a linha de dados (ignora o cabeçalho). `awk` formata a saída exibindo usado, total e percentual.

```bash
disk_pct=$(df / | tail -n 1 | awk '{print $5}' | tr -d '%')
```
Extrai apenas o percentual de uso do disco. O `tr -d '%'` remove o símbolo `%` para que o valor possa ser comparado como inteiro pelo Bash.

```bash
if [ -n "$disk_pct" ] && [ "$disk_pct" -gt "$THRESHOLD_DISK" ]; then
    echo -e "${RED}[ALERTA] Espaço em disco insuficiente!${RESET}"
fi
```
O `-n` verifica se a variável não está vazia antes de comparar, evitando erros de sintaxe caso o `df` não retorne valor.

---

### `report_temp()` — Temperatura da CPU

```bash
if command -v sensors &>/dev/null; then
```
Verifica se o comando `sensors` (do pacote `lm-sensors`) está instalado, sem exibir nenhuma saída na tela (`&>/dev/null` redireciona stdout e stderr para o nada).

```bash
temp_c=$(sensors | awk '/Tctl/{gsub(/[^0-9.]/,"",$2); print int($2)}')
```
Filtra a linha `Tctl` (sensor de temperatura AMD — equivalente seria `Package id 0` em Intel), remove todos os caracteres não numéricos com `gsub` e converte para inteiro com `int()`.

```bash
if [ -n "$temp_c" ]; then
    echo "Temperatura CPU (Tct1): ${temp_c} ºC"
    if [ "$temp_c" -gt "$THRESHOLD_TEMP" ]; then
        echo -e "${RED}[ALERTA] Superaquecimento detectado: ${temp_c}ºC${RESET}"
    fi
else
    echo "Sensor não encontrado."
fi
```
Se o valor foi capturado com sucesso, exibe a temperatura e verifica o alerta. Caso contrário, informa que o sensor não foi encontrado.

```bash
else
    echo -e "${YELLOW}lm-sensors não instalado. Rode: sudo apt install lm-sensors${RESET}"
fi
```
Se o `sensors` não estiver instalado, orienta o usuário a instalar.

---

### `report_top_processos()` — Top 5 Processos

```bash
ps aux --sort=-%cpu | head -n 6 | cut -c 1-100
```
`ps aux` lista todos os processos. `--sort=-%cpu` ordena do maior para o menor uso de CPU. `head -n 6` pega o cabeçalho + 5 processos. `cut -c 1-100` limita a 100 caracteres por linha para não quebrar o terminal.

```bash
ps aux --sort=-%mem | head -n 6 | cut -c 1-100
```
Mesmo comando, mas ordenado por uso de memória.

---

### Execução Principal

```bash
clear
```
Limpa o terminal antes de exibir o relatório.

```bash
echo -e "${BOLD}=====================${RESET}"
echo -e "${BOLD}RELATORIO DE SAUDE - $(date)${RESET}"
echo -e "${BOLD}=====================${RESET}"
```
Exibe o cabeçalho em negrito com a data e hora atual via `$(date)`.

```bash
report_cpu
report_ram
report_disk
report_temp
report_top_processos
```
Chama cada função em sequência para montar o relatório completo.

---

## 📸 Exemplo de saída

```
=====================
RELATORIO DE SAUDE - Wed Mar 25 03:59:56 PM -03 2026
=====================

--- CPU ---
Uso Total: 12%
Media de Carga: 0.43, 0.40, 0.41

--- MEMORIA RAM ---
               total        used        free      shared  buff/cache   available
Mem:            15Gi       6.1Gi       5.5Gi       232Mi       4.4Gi       9.4Gi
Porcentagem de Uso: 39%

--- DISCOS ---
Uso: 94G usado / 423G total ( 24% )

--- TEMPERATURA ---
Temperatura CPU (Tct1): 52 ºC

--- TOP 5 PROCESSOS(CPU) ---
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
gabriel     4248 10.2  5.2 255321828 851956 ?    Sl   10:18  28:31 /usr/lib/firefox-esr/...
...
```

---

## 📁 Estrutura do Repositório

```
health-checker/
├── health_checker.sh   # Script principal
└── README.md           # Este arquivo
```

---

## 👤 Autor

Feito como projeto para  fins educativos dos meus alunos de Sistema Operacional.
