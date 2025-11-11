# =====================================================
# CONVERSOR DE .FLM PARA .AVI
# LOG UNIFICADO: SUCESSOS, FALHAS E METADADOS
# =====================================================

# ==========================
# CONFIGURAÇÕES DO USUÁRIO
# ==========================

PASTA_ENTRADA <- "D:/FLMs/entrada"
PASTA_SAIDA   <- "D:/FLMs/saida"

FPS_PADRAO    <- 25 # fallback seguro (baseado no avg_frame_rate)
FONTE         <- "Arial"
TAMANHO_FONTE <- 32
COR_FONTE     <- "white"

LOG_ARQUIVO <- file.path(PASTA_SAIDA, "processamento_completo.log")


# ==========================
# PACOTES
# ==========================

if (!requireNamespace("progress", quietly = TRUE)) {
  install.packages("progress", repos = "https://cloud.r-project.org")
}
library(progress)
library(tools)


# ==========================
# CABEÇALHO DE EXECUÇÃO
# ==========================

gerar_id_execucao <- function() {
  paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample(1000:9999, 1))
}
ID_EXECUCAO <- gerar_id_execucao()


# ==========================
# FUNÇÕES DE LOG
# ==========================

na_to_str <- function(val, fmt = "%.1f", placeholder = "N/A") {
  if (is.null(val) || is.na(val) || length(val) == 0) return(placeholder)
  sprintf(fmt, val)
}

log_mensagem <- function(msg, tipo = "INFO", indent = 0) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  prefixo <- switch(tipo,
                    "SUCCESS" = " ✅ ",
                    "ERROR"   = " ❌ ",
                    "WARN"    = " ⚠️ ",
                    "HEADER"  = " === ",
                    "INFO"    = " ℹ️ ",
                    "SUB"     = "   ")
  espaco_indent <- strrep(" ", indent * 2)
  
  if (tipo == "HEADER") {
    linha <- sprintf("\n%s ===============================\n%s EXECUÇÃO: %s\n%s DATA: %s\n%s ===============================\n",
                     prefixo, prefixo, ID_EXECUCAO, prefixo, timestamp, prefixo)
  } else if (tipo == "SUB") {
    linha <- sprintf("%s%s%s", prefixo, espaco_indent, msg)
  } else {
    linha <- sprintf("[%s]%s%s%s", timestamp, prefixo, espaco_indent, msg)
  }
  cat(linha, "\n")
  cat(linha, "\n", file = LOG_ARQUIVO, append = TRUE)
}

log_detalhe <- function(pasta, arquivo, fps = NA, duracao = NA, largura = NA, altura = NA,
                        bitrate = NA, tamanho_in = NA, formato_out = NA, tempo_proc = NA,
                        tamanho_out = NA, status = "OK", erro = "") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  resolucao <- paste0(na_to_str(largura, "%d"), "x", na_to_str(altura, "%d"))
  linha <- paste(
    timestamp, pasta, arquivo,
    na_to_str(fps, "%.2f"),
    paste0(na_to_str(duracao, "%.1f"), "s"),
    resolucao,
    paste0(na_to_str(bitrate, "%.0f"), "kbps"),
    paste0(na_to_str(tamanho_in, "%.1f"), "MB"),
    formato_out,
    paste0(na_to_str(tempo_proc, "%.1f"), "s"),
    paste0(na_to_str(tamanho_out, "%.1f"), "MB"),
    status, gsub("[\r\n]", " ", erro),
    sep = " | "
  )
  cat(paste0("  [DETALHE] ", linha), "\n", file = LOG_ARQUIVO, append = TRUE)
}


# ==========================
# ESCAPE DE TEXTO
# ==========================

escape_drawtext <- function(texto) {
  texto <- gsub("\\\\", "\\\\\\\\", texto)
  texto <- gsub("'", "'\\\\''", texto)
  texto <- gsub(":", "\\\\:", texto)
  texto <- gsub("%", "\\\\%", texto)
  texto
}


# ==========================
# DETECÇÃO DE METADADOS
# ==========================

get_metadata <- function(video_path) {
  cmd <- sprintf(
    'ffprobe -v error -i "%s" -select_streams v:0 -show_entries stream=width,height,bit_rate,avg_frame_rate -of default=noprint_wrappers=1:nokey=1',
    video_path
  )
  meta <- tryCatch(shell(cmd, intern = TRUE), error = function(e) "")
  if (length(meta) < 4) {
    return(list(width = NA, height = NA, bitrate = NA, fps = FPS_PADRAO))
  }
  
  width <- as.numeric(meta[1])
  height <- as.numeric(meta[2])
  bitrate <- as.numeric(meta[3]) / 1000
  
  # Pega o avg_frame_rate (valor real, não o r_frame_rate)
  parts <- strsplit(meta[4], "/")[[1]]
  fps <- if (length(parts) == 2) as.numeric(parts[1]) / as.numeric(parts[2]) else as.numeric(meta[4])
  
  # Proteção contra aberrações como 1200000 fps
  if (is.na(fps) || fps < 5 || fps > 120) fps <- FPS_PADRAO
  
  list(width = width, height = height, bitrate = bitrate, fps = fps)
}


# ==========================
# CONVERSÃO DE VÍDEO
# ==========================

converter_e_anotar_video <- function(caminho_entrada, nome_pasta, fps_pasta) {
  nome_arquivo <- basename(caminho_entrada)
  nome_sem_ext <- file_path_sans_ext(nome_arquivo)
  
  legenda <- sprintf("%s - %s", nome_pasta, nome_arquivo)
  legenda_escapada <- escape_drawtext(legenda)
  
  inicio <- Sys.time()
  
  meta <- get_metadata(caminho_entrada)
  tamanho_in <- file.info(caminho_entrada)$size / (1024^2)
  
  arquivo_avi_temp <- tempfile(pattern = nome_sem_ext, fileext = ".avi")
  arquivo_erro_log <- tempfile(fileext = ".txt")
  
  # FPS aplicado na ENTRADA (não na saída)
  cmd_avi <- sprintf(
    'ffmpeg -y -framerate %.2f -i "%s" -vf "drawtext=fontfile=/Windows/Fonts/%s.ttf: text=\'%s\': fontcolor=%s: fontsize=%d: x=(w-text_w)/2: y=h-(text_h*2)" -c:v mjpeg -qscale:v 3 -an "%s"',
    fps_pasta, caminho_entrada,
    FONTE, legenda_escapada, COR_FONTE, TAMANHO_FONTE,
    arquivo_avi_temp
  )
  
  status_conversao <- shell(paste(cmd_avi, "2>", shQuote(arquivo_erro_log)), ignore.stdout = TRUE)
  tempo_proc <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
  
  msg_erro <- ""
  if (status_conversao != 0) {
    if (file.exists(arquivo_erro_log))
      msg_erro <- paste(readLines(arquivo_erro_log, warn = FALSE), collapse = " ")
    else msg_erro <- "Falha na conversão (ffmpeg retornou código != 0)."
  }
  try(file.remove(arquivo_erro_log), silent = TRUE)
  
  if (status_conversao == 0 && file.exists(arquivo_avi_temp) && file.info(arquivo_avi_temp)$size > 0) {
    tamanho_out <- file.info(arquivo_avi_temp)$size / (1024^2)
    log_detalhe(nome_pasta, nome_arquivo, fps_pasta, NA, meta$width, meta$height,
                meta$bitrate, tamanho_in, "AVI(temp)", tempo_proc, tamanho_out, "OK")
    return(arquivo_avi_temp)
  }
  
  log_detalhe(nome_pasta, nome_arquivo, fps_pasta, NA, meta$width, meta$height,
              meta$bitrate, tamanho_in, "N/A", tempo_proc, 0, "FAIL", msg_erro)
  NULL
}


# ==========================
# PROCESSAMENTO DE PASTAS
# ==========================

processar_pasta <- function(pasta) {
  nome_pasta <- basename(pasta)
  saida_pasta <- file.path(PASTA_SAIDA, paste0(nome_pasta, ".avi"))
  
  log_mensagem(paste("Processando pasta:", nome_pasta))
  
  arquivos_flm <- list.files(pasta, pattern = "\\.flm$", full.names = TRUE, ignore.case = TRUE)
  if (length(arquivos_flm) == 0) {
    log_mensagem(paste("Nenhum arquivo .flm encontrado em", pasta), "WARN", indent = 1)
    return(invisible())
  }
  
  meta_ref <- get_metadata(arquivos_flm[1])
  fps_pasta <- meta_ref$fps
  log_mensagem(sprintf("FPS detectado para '%s': %.2f", nome_pasta, fps_pasta), "INFO", indent = 1)
  
  pb <- progress_bar$new(
    total = length(arquivos_flm),
    format = paste0("  🎞️ ", nome_pasta, " [:bar] :percent :eta (:current/:total)"),
    clear = FALSE, width = 70
  )
  
  convertidos <- character()
  for (f in arquivos_flm) {
    out <- converter_e_anotar_video(f, nome_pasta, fps_pasta)
    if (!is.null(out)) convertidos <- c(convertidos, out)
    pb$tick()
  }
  
  if (length(convertidos) > 0) {
    lista_txt <- tempfile(fileext = ".txt")
    writeLines(paste0("file '", gsub("\\\\", "/", convertidos), "'"), lista_txt)
    
    log_mensagem(paste("Concatenando", length(convertidos), "vídeos em:", basename(saida_pasta)), "SUB", indent = 1)
    
    cmd_concat <- sprintf('ffmpeg -y -f concat -safe 0 -i "%s" -c copy "%s"', lista_txt, saida_pasta)
    status_concat <- shell(cmd_concat, ignore.stdout = TRUE, ignore.stderr = TRUE)
    
    if (status_concat == 0 && file.exists(saida_pasta) && file.info(saida_pasta)$size > 0) {
      tamanho_final <- file.info(saida_pasta)$size / (1024^2)
      log_mensagem(paste("Arquivo final salvo:", basename(saida_pasta),
                         sprintf("(%.1f MB)", tamanho_final)), "SUCCESS", indent = 1)
    } else {
      log_mensagem(paste("Falha ao concatenar:", basename(saida_pasta)), "ERROR", indent = 1)
    }
    
    try(file.remove(lista_txt, convertidos), silent = TRUE)
  } else {
    log_mensagem(paste("Nenhum vídeo válido foi convertido em", nome_pasta), "WARN", indent = 1)
  }
}


# ==========================
# EXECUÇÃO PRINCIPAL
# ==========================

processar_todas <- function() {
  dir.create(PASTA_SAIDA, showWarnings = FALSE, recursive = TRUE)
  if (file.exists(LOG_ARQUIVO)) file.remove(LOG_ARQUIVO)
  
  log_mensagem("Nova Execução", tipo = "HEADER")
  log_mensagem(paste("Iniciando processamento em", PASTA_ENTRADA))
  log_mensagem(paste("Log completo salvo em:", LOG_ARQUIVO))
  log_mensagem(paste("ID da Execução:", ID_EXECUCAO))
  
  subpastas <- list.dirs(PASTA_ENTRADA, recursive = TRUE, full.names = TRUE)
  subpastas <- subpastas[subpastas != PASTA_ENTRADA]
  
  if (length(subpastas) == 0) {
    log_mensagem("Nenhuma subpasta encontrada. Verificando arquivos .flm na pasta raiz...", "WARN")
    processar_pasta(PASTA_ENTRADA)
  } else {
    pb_global <- progress_bar$new(
      total = length(subpastas),
      format = "  🌍 Processando pastas [:bar] :percent :eta",
      clear = FALSE, width = 70
    )
    
    for (sub in subpastas) {
      processar_pasta(sub)
      pb_global$tick()
    }
  }
  
  log_mensagem("Processamento concluído.", tipo = "SUCCESS")
}


# ==========================
# EXECUTAR
# ==========================

if (file.exists(LOG_ARQUIVO)) file.remove(LOG_ARQUIVO)
processar_todas()
