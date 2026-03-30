# 📚 Glossário de Comandos — health_checker.sh

Referência rápida de todos os comandos e flags usados no script, com explicação simples e exemplos práticos.

---

## 🔤 Comandos do Terminal

### `echo`
Exibe uma mensagem no terminal.
```bash
echo "Olá, mundo"
```

**Flag `-e`** — Ativa a interpretação de caracteres especiais, como cores e quebras de linha:
```bash
echo -e "\e[31m Texto em vermelho \e[0m"
echo -e "Linha 1\nLinha 2"   # \n = quebra de linha
```
> Sem o `-e`, o `echo` imprime o `\n` literalmente em vez de quebrar a linha.

---

### `printf`
Exibe texto formatado, com controle preciso sobre o formato dos números e strings.
```bash
printf "Uso Total: %d%%\n" 42
# Saída: Uso Total: 42%
```
- `%d` → número inteiro
- `%s` → texto (string)
- `%f` → número decimal
- `%%` → imprime o símbolo `%` literalmente
- `\n` → quebra de linha

> Prefira `printf` ao `echo` quando precisar formatar números ou garantir portabilidade.

---

### `read`
Lê uma linha de texto e armazena em variáveis.
```bash
read -r _ user nice sys idle < /proc/stat
```
- `-r` → não interpreta barras invertidas (`\`) como escape
- `_` → descarta o primeiro campo (no caso, a palavra "cpu")
- Os demais nomes recebem cada campo da linha em sequência

---

### `sleep`
Pausa a execução do script por um tempo determinado.
```bash
sleep 0.5   # pausa 0.5 segundo
sleep 2     # pausa 2 segundos
```

---

### `cat`
Exibe o conteúdo de um arquivo no terminal.
```bash
cat /proc/meminfo
cat /sys/class/thermal/thermal_zone0/temp
```

---

### `clear`
Limpa o terminal.
```bash
clear
```

---

### `date`
Exibe a data e hora atual do sistema.
```bash
date
# Saída: Wed Mar 25 03:59:56 PM -03 2026
```

---

### `uptime`
Mostra há quanto tempo o sistema está ligado e a média de carga da CPU.
```bash
uptime
# Saída: 14:57:42 up 4:40, 1 user, load average: 0.43, 0.40, 0.41
```
- Os três números do `load average` são as médias de carga nos últimos 1, 5 e 15 minutos.

---

### `free`
Exibe o uso de memória RAM e Swap.
```bash
free -h
```
**Flag `-h`** — Exibe os valores em formato legível (GB, MB) em vez de bytes brutos.

---

### `df`
Exibe o uso de espaço nos discos montados.
```bash
df -h /
```
- `-h` → formato legível (GB, MB)
- `/` → mostra só a partição raiz

---

### `ps`
Lista os processos em execução no sistema.
```bash
ps aux --sort=-%cpu
```
- `a` → mostra processos de todos os usuários
- `u` → exibe em formato detalhado (usuário, CPU, memória, etc.)
- `x` → inclui processos sem terminal associado
- `--sort=-%cpu` → ordena por uso de CPU do maior para o menor (o `-` inverte a ordem)
- `--sort=-%mem` → ordena por uso de memória

---

### `sensors`
Lê os sensores de temperatura e voltagem do hardware (requer o pacote `lm-sensors`).
```bash
sensors
```

---

### `command -v`
Verifica se um comando está instalado no sistema, sem executá-lo.
```bash
command -v sensors
```
- Retorna o caminho do comando se existir (ex: `/usr/bin/sensors`)
- Não retorna nada se o comando não estiver instalado
- Usado com `if` para verificar dependências antes de executar

```bash
if command -v sensors &>/dev/null; then
    echo "sensors está instalado"
fi
```
> `&>/dev/null` redireciona toda a saída (stdout e stderr) para o nada, evitando que apareça no terminal.

---

## 🔧 Filtros e Processamento de Texto

### `awk`
Ferramenta para processar e extrair colunas de texto.
```bash
awk '{print $2}' /proc/meminfo        # imprime a segunda coluna
awk '/MemTotal/{print $2}' /proc/meminfo  # filtra a linha que contém "MemTotal" e imprime a segunda coluna
awk -F'load average:' '{print $2}'    # usa "load average:" como separador de campo
```
- `$1, $2, $3...` → representam a primeira, segunda, terceira coluna, etc.
- `/padrão/` → filtra apenas as linhas que contêm aquele padrão
- `-F` → define o separador de campos (padrão é espaço)
- `gsub(/padrão/, "", $campo)` → remove caracteres que casam com o padrão em um campo

---

### `grep`
Filtra linhas que contêm um padrão de texto.
```bash
grep "MemTotal" /proc/meminfo
grep "Tctl" sensors
```

---

### `sed`
Edita texto em fluxo — substitui, remove ou transforma partes de uma string.
```bash
echo "24%" | sed 's/%//'    # remove o %
# Saída: 24
```
- `s/padrão/substituto/` → substitui a primeira ocorrência
- `s/padrão/substituto/g` → substitui todas as ocorrências

---

### `tr`
Traduz ou remove caracteres de uma string.
```bash
echo "24%" | tr -d '%'    # remove o caractere %
# Saída: 24
```
- `-d` → deleta os caracteres especificados

> No script, usado para remover o `%` do valor do disco antes de comparar como número inteiro.

---

### `cut`
Recorta colunas ou caracteres de cada linha.
```bash
ps aux | cut -c 1-100    # mantém apenas os primeiros 100 caracteres de cada linha
```
- `-c 1-100` → seleciona os caracteres da posição 1 até 100

---

### `head`
Exibe as primeiras linhas de uma saída ou arquivo.
```bash
ps aux | head -n 6    # exibe as 6 primeiras linhas
```
- `-n 6` → define o número de linhas (cabeçalho + 5 processos)

---

### `tail`
Exibe as últimas linhas de uma saída ou arquivo.
```bash
df -h / | tail -n 1    # exibe apenas a última linha
```
- `-n 1` → exibe só a última linha (ignora o cabeçalho do `df`)

---

### `xargs`
Passa a saída de um comando como argumento para outro, removendo espaços extras no processo.
```bash
uptime | awk -F'load average:' '{print $2}' | xargs
```
> No script, usado para limpar espaços em branco no início e fim da string de carga.

---

## 🔀 Operadores e Redirecionamentos

### `|` (pipe)
Passa a saída de um comando como entrada para o próximo.
```bash
df -h / | tail -n 1 | awk '{print $5}'
```
Lê-se: "pegue a saída do `df`, passe para o `tail`, e a saída do `tail` passe para o `awk`."

---

### `<` (redirecionamento de entrada)
Usa um arquivo como entrada de um comando.
```bash
read -r _ user1 nice1 sys1 idle1 < /proc/stat
```
Equivale a fazer `cat /proc/stat | read`, mas de forma mais eficiente.

---

### `&>/dev/null`
Descarta toda a saída (tanto mensagens normais quanto erros).
```bash
command -v sensors &>/dev/null
```
- `>` redireciona stdout
- `2>` redireciona stderr
- `&>` redireciona os dois ao mesmo tempo
- `/dev/null` é um "buraco negro" do Linux — tudo que vai para lá é descartado

---

## ➗ Aritmética no Bash

### `$(( ))`
Realiza operações matemáticas com inteiros diretamente no Bash, sem precisar de ferramentas externas.
```bash
total=16000
available=9000
used=$(( total - available ))
pct=$(( used * 100 / total ))
```
> ⚠️ O Bash só trabalha com **números inteiros**. Para decimais seria necessário `bc` ou `awk`.

---

## 📂 Arquivos Especiais do Linux

| Arquivo | O que contém |
|---|---|
| `/proc/stat` | Contadores de ticks de CPU desde o boot |
| `/proc/meminfo` | Informações detalhadas sobre uso de memória |
| `/sys/class/thermal/thermal_zone0/temp` | Temperatura da CPU em miligraus Celsius |

> A pasta `/proc` não existe no disco — ela é gerada pelo kernel em tempo real. Tudo que você lê de lá é informação viva do sistema operacional.
