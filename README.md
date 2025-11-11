# Conversor de FLM para AVI com Log Unificado

Script em **R** para conversão automatizada de arquivos `.flm` em `.avi`, com **extração de metadados**, **anotações de texto sobre o vídeo**, **concatenação automática por pastas** e **registro detalhado de logs** (sucessos, falhas e metadados).

---

## Visão Geral

Este script percorre uma pasta de entrada com subpastas contendo arquivos `.flm`, converte cada um em `.avi` (com legenda sobreposta informando a pasta e o nome do arquivo), e em seguida concatena todos os vídeos convertidos de cada subpasta em um único `.avi`.

Durante o processo, o script gera um **log unificado** com todas as operações executadas, incluindo:
- Metadados de cada vídeo (resolução, bitrate, FPS, duração estimada);
- Tempo de processamento;
- Tamanho dos arquivos;
- Status de sucesso ou falha.

---

## Requisitos

- **R (≥ 4.0)**
- **FFmpeg** e **FFprobe** instalados e disponíveis no PATH do sistema
- Pacotes R necessários:
  ```r
  install.packages("progress", repos = "https://cloud.r-project.org")
````

* Sistema operacional Windows (por usar `shell()` e caminhos de fonte padrão)

---

## Estrutura de Pastas

```
D:/
 └── FLMs/
     ├── entrada/
     │    ├── Pasta1/
     │    │    ├── video1.flm
     │    │    └── video2.flm
     │    └── Pasta2/
     │         └── videoX.flm
     └── saida/
```

O script buscará os arquivos `.flm` dentro de `PASTA_ENTRADA` (e suas subpastas), gerará arquivos `.avi` temporários e criará, na pasta `PASTA_SAIDA`, um `.avi` final por subpasta processada.

---

## Configurações Principais

As variáveis configuráveis no início do script são:

```r
PASTA_ENTRADA <- "D:/FLMs/entrada"
PASTA_SAIDA   <- "D:/FLMs/saida"

FPS_PADRAO    <- 25
FONTE         <- "Arial"
TAMANHO_FONTE <- 32
COR_FONTE     <- "white"

LOG_ARQUIVO <- file.path(PASTA_SAIDA, "processamento_completo.log")
```

---

## Execução

Basta rodar o script em um ambiente R com o `FFmpeg` disponível:

```r
source("conversor_flm_para_avi.R")
```

O processo completo será iniciado automaticamente.
Durante a execução, serão exibidas barras de progresso no console e todas as mensagens serão salvas no log.

---

## Estrutura do Log

O arquivo de log (`processamento_completo.log`) contém:

* Cabeçalho da execução (ID, data/hora)
* Logs informativos e de progresso
* Detalhes de cada vídeo processado, com formato:

```
[YYYY-MM-DD HH:MM:SS] | Pasta | Arquivo | FPS | Duração | Resolução | Bitrate | Tamanho_In | Formato_Out | Tempo_Process | Tamanho_Out | Status | Erro
```

Exemplo:

```
2025-11-11 10:12:32 | Pasta1 | video1.flm | 25.00 | 12.3s | 1920x1080 | 4500kbps | 35.6MB | AVI(temp) | 4.2s | 38.1MB | OK
```

---

## Principais Funções

| Função                       | Descrição                                      |
| ---------------------------- | ---------------------------------------------- |
| `gerar_id_execucao()`        | Gera um identificador único para cada execução |
| `log_mensagem()`             | Registra mensagens formatadas no console e log |
| `get_metadata()`             | Extrai metadados de vídeo via FFprobe          |
| `converter_e_anotar_video()` | Converte `.flm` em `.avi` e adiciona legenda   |
| `processar_pasta()`          | Processa uma pasta específica                  |
| `processar_todas()`          | Percorre todas as subpastas e processa em lote |

---

## ⚠️ Observações

* O script assume que cada subpasta contém arquivos `.flm` do mesmo tipo (FPS e resolução semelhantes).
* A conversão pode consumir bastante espaço em disco temporário.
* O log é sobrescrito a cada nova execução.
* O script foi testado em Windows, mas pode ser adaptado para Linux alterando os comandos `shell()`.

## Exemplo de Saída Final

Após a execução, cada subpasta processada resultará em um arquivo `.avi` na pasta de saída:

```
D:/FLMs/saida/
 ├── Pasta1.avi
 ├── Pasta2.avi
 └── processamento_completo.log
```

---

## Exemplo de Execução (trecho do log)

```
=== ===============================
=== EXECUÇÃO: 2025-11-11_103522_4728
=== DATA: 2025-11-11 10:35:22
=== ===============================

[2025-11-11 10:35:23] ℹ️ Iniciando processamento em D:/FLMs/entrada
[2025-11-11 10:35:23] ℹ️ Log completo salvo em: D:/FLMs/saida/processamento_completo.log
[2025-11-11 10:35:24] 🎞️ Pasta1 [:bar] 100% 00:00 (10/10)
[2025-11-11 10:35:26] ✅ Arquivo final salvo: Pasta1.avi (135.4 MB)
[2025-11-11 10:35:26] ✅ Processamento concluído.
```
