# 🖥️ Atividade Prática — Monitor de Saúde do Sistema

**Disciplina:** Sistemas Operacionais  
**Nível:** Iniciante  
**Formato:** Individual ou dupla  

---

## 📌 Contexto

Um dos papéis fundamentais do Sistema Operacional é **gerenciar os recursos do hardware** — como processador, memória e disco — e disponibilizá-los para os programas de forma organizada.

Nesta atividade, você vai explorar um script Bash que coleta informações diretamente do kernel Linux para monitorar a saúde do sistema em tempo real.

> 💡 **Bash** é uma linguagem de script usada no terminal do Linux. Um **script** é um arquivo de texto com uma sequência de comandos que o sistema executa automaticamente.

---

## 🎯 Objetivo

Ler, entender e documentar o script `health_checker.sh`, identificando:

- O que cada bloco de código faz
- Qual recurso do sistema operacional ele acessa
- Por que aquele comando foi usado daquela forma

---

## 📁 Arquivos da Atividade

| Arquivo | Descrição |
|---|---|
| `health_checker.sh` | Script que você vai analisar |

---

## 🚀 Como executar o script

Antes de analisar o código, **execute o script** e observe a saída no terminal.

**Passo 1 — Abra o terminal**

No Debian/Ubuntu, pressione `Ctrl + Alt + T`.

**Passo 2 — Navegue até a pasta onde salvou o arquivo:**
```bash
cd ~/Downloads
```

**Passo 3 — Dê permissão de execução:**
```bash
chmod +x health_checker.sh
```
> 💡 Por padrão, arquivos no Linux não podem ser executados sem permissão explícita. O `chmod +x` concede essa permissão.

**Passo 4 — Execute:**
```bash
./health_checker.sh
```

Você verá um relatório parecido com este:

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
Temperatura CPU: 52 ºC

--- TOP 5 PROCESSOS (CPU) ---
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
gabriel     4248 10.2  5.2 ...
```

---

## 📖 Estrutura do Script

O script está dividido em 3 partes. Abra o arquivo em um editor de texto e acompanhe:

### Parte 1 — Configurações (linhas 1 a 15)
Define os **limites de alerta** e as **cores** usadas no terminal.

### Parte 2 — Funções (linhas 17 a 110)
Cada função é responsável por monitorar um recurso diferente:

| Função | O que monitora |
|---|---|
| `report_cpu()` | Uso do processador |
| `report_ram()` | Uso da memória RAM |
| `report_disk()` | Uso do disco |
| `report_temp()` | Temperatura da CPU |
| `report_top_processos()` | Processos mais pesados |

### Parte 3 — Execução Principal (linhas finais)
Chama todas as funções em sequência e monta o relatório.

---

## ✏️ Tarefa

Responda as questões abaixo com base na leitura do script. Você pode usar o terminal para testar os comandos individualmente.

---

### 🔹 Bloco 1 — Limites e Cores

**1.1)** No início do script existem quatro variáveis de limite:
```bash
THRESHOLD_RAM=90
THRESHOLD_CPU=80
THRESHOLD_DISK=90
THRESHOLD_TEMP=75
```
O que acontece no script quando um desses limites é ultrapassado? Cite um exemplo do código.

**1.2)** O script usa cores no terminal com códigos como `'\e[31m'`. Execute o comando abaixo e descreva o que acontece:
```bash
echo -e "\e[31m Isso está em vermelho \e[0m"
echo -e "\e[36m Isso está em ciano \e[0m"
```
Para que serve o `\e[0m` no final?

---

### 🔹 Bloco 2 — CPU

**2.1)** O script lê o arquivo `/proc/stat` duas vezes com um intervalo de 0.5 segundo entre as leituras. Execute o comando abaixo e observe a saída:
```bash
cat /proc/stat | head -n 1
```
O que você vê? O que esses números representam?

**2.2)** Por que o script precisa ler o arquivo **duas vezes** para calcular o uso da CPU? Não seria possível calcular com uma leitura só?

**2.3)** O script usa o comando `uptime`. Execute-o no terminal e descreva o que cada informação significa:
```bash
uptime
```

---

### 🔹 Bloco 3 — Memória RAM

**3.1)** O script lê o arquivo `/proc/meminfo`. Execute o comando abaixo e encontre as linhas `MemTotal` e `MemAvailable`:
```bash
cat /proc/meminfo
```
Qual a diferença entre `MemFree` e `MemAvailable`? O script usa qual deles e por quê?

**3.2)** O cálculo de porcentagem de RAM é feito assim:
```bash
used=$(( total - available ))
ram_pct=$(( used * 100 / total ))
```
Por que o script multiplica por 100 **antes** de dividir, e não depois?

> 💡 Dica: pense no que acontece com números inteiros em divisões no Bash.

---

### 🔹 Bloco 4 — Disco

**4.1)** O script usa o comando `df`. Execute e observe:
```bash
df -h /
```
O que cada coluna representa? O script usa as colunas `$2`, `$3` e `$5` no `awk` — quais são elas?

**4.2)** O script remove o símbolo `%` do valor com `tr -d '%'` antes de comparar. Por que isso é necessário?

---

### 🔹 Bloco 5 — Processos

**5.1)** O script usa `ps aux --sort=-%cpu`. Execute e observe:
```bash
ps aux --sort=-%cpu | head -n 6
```
O que significa o `-` antes de `%cpu` no `--sort`?

**5.2)** O `cut -c 1-100` limita a saída a 100 caracteres por linha. Por que isso foi feito? O que aconteceria sem ele?

---

### 🔹 Bloco 6 — Reflexão Final

**6.1)** O script acessa diretamente arquivos como `/proc/stat` e `/proc/meminfo` em vez de usar comandos prontos como `top`. Qual a vantagem disso?

**6.2)** Se você fosse adicionar uma nova seção ao relatório — por exemplo, **uso de rede** — como você começaria? Que arquivo ou comando você pesquisaria primeiro?

---


## 🔗 Referências para Consulta

- `man bash` — manual do Bash no terminal
- `man proc` — documentação do sistema de arquivos `/proc`
- `man ps` — documentação do comando `ps`
- [Linux Journey](https://linuxjourney.com) — guia interativo gratuito de Linux
- [Guia Foca Linux](https://www.guiafoca.org) — referência em português

---

> 🗂️ Este script foi desenvolvido como projeto prático de estudo de DevOps e adaptado para fins didáticos.
