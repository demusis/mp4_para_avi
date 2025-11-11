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
```

* Sistema operacional Windows (por usar `shell()` e caminhos de fonte padrão)

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

## ⚠️ Observações

* O script assume que cada subpasta contém arquivos `.flm` do mesmo tipo (FPS e resolução semelhantes).
* A conversão pode consumir bastante espaço em disco temporário.
* O log é sobrescrito a cada nova execução.
* O script foi testado em Windows, mas pode ser adaptado para Linux alterando os comandos `shell()`.

## Exemplo de Saída Final

Após a execução, cada subpasta processada resultará em um arquivo `.avi` na pasta de saída:

