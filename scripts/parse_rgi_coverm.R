#!/usr/bin/env Rscript
# Script to parse the results from CoverM (tsv), in order to keep only the genes identified as resistance genes by RGI, saved in the json
#
# Usage:
#   Rscript parse_rgi_coverm.R <carpeta_json> <carpeta_coverm> [carpeta_salida]
#
# Expected folder structure:
#   Json_folder/
#     SAMPLE1_rgi_annotation.json
#     SAMPLE2_rgi_annotation.json
#   coverm_folder/
#     SAMPLE1/
#       SAMPLE1_genes_cobertura.tsv
#     SAMPLE2/
#       SAMPLE2_genes_cobertura.tsv
#
# The sample's name is obtained from the JSON (taking out "_rgi_annotation.json"), and it must match the name of the subfolder.

#Suppress the package loading messages
suppressPackageStartupMessages({
  library(jsonlite)
  library(readr)
  library(dplyr)
})

# Arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2 || length(args) > 3) {
  cat("Uso: Rscript parsear_rgi_coverm_lote.R <carpeta_json> <carpeta_coverm> [carpeta_salida]\n")
  quit(status = 1)
} # if there are less than 2 args or more than 3 it raises an error (the exit folder is optional)

dir_json   <- args[1]
dir_coverm <- args[2]
dir_salida <- if (length(args) == 3) args[3] else "resultados"

for (d in c(dir_json, dir_coverm)) {
  if (!dir.exists(d)) {
    cat("ERROR: folder does not exist:", d, "\n")
    quit(status = 1)
  }
} # Error if the folder does not exist

dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE) # creat output folder

# Helper functions to parse the json and modify the samples

# Changes all genes ids to the format 1_1, for example:
# NODE_52_length_43896_cov_14.055108_33 turns to 52_33
# Those that are already in the correct format do not change
normalizar_id <- function(x) {
  sub("^NODE_(\\d+)_.*_(\\d+)$", "\\1_\\2", x)
}

# Extracs a field from the json, returns NA if it does not exist or if it is empty
campo <- function(lista, n) {
  v <- lista[[n]] #busca el nombre del campo n en el json, extrae su contenido y lo guarda en la variable v
  if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[[1]])
}

# Summarizes ARO categories in | separated text 
colapsar_cat <- function(cats, clase) {
  if (is.null(cats) || length(cats) == 0) return(NA_character_)
  nom <- vapply(cats, function(c) {
    if (identical(c$category_aro_class_name, clase)) c$category_aro_name else NA_character_
  }, character(1))
  nom <- unique(nom[!is.na(nom)])
  if (length(nom) == 0) NA_character_ else paste(nom, collapse = "|")
}

# Reads the JSON and returns a dataframe with a row per hit, using the helper functions created above
leer_rgi <- function(ruta_json) {
  datos <- fromJSON(ruta_json, simplifyVector = FALSE)

  filas <- list() # creamos una lista vacía para almacenar todo
  for (cabecera in names(datos)) { #extracts the fields from the json and saves them in the orf variable
    orf <- datos[[cabecera]]
    if (!is.list(orf)) next  # cheks it is a list, if not, it skips it
    id <- normalizar_id(trimws(strsplit(cabecera, " # ", fixed = TRUE)[[1]][1])) #takes the header identifier, splits it by # and keeps only the first field

    for (hsp_key in names(orf)) {
      h <- orf[[hsp_key]]
      if (!is.list(h) || is.null(h$orf_start)) next 

      cats <- h$ARO_category #now for every extracted field we organised them into cols with their specific names
      filas[[length(filas) + 1]] <- list(
        id            = id,
        hsp           = sub(".*hsp_num:", "", hsp_key),
        contig        = campo(h, "orf_from"),
        strand        = campo(h, "orf_strand"),
        orf_start     = campo(h, "orf_start"),
        orf_end       = campo(h, "orf_end"),
        query_start   = campo(h, "query_start"),
        query_end     = campo(h, "query_end"),
        type_match    = campo(h, "type_match"),
        model_name    = campo(h, "model_name"),
        model_type    = campo(h, "model_type"),
        ARO_accession = campo(h, "ARO_accession"),
        ARO_name      = campo(h, "ARO_name"),
        evalue        = campo(h, "evalue"),
        bit_score     = campo(h, "bit_score"),
        pass_bitscore = campo(h, "pass_bitscore"),
        perc_identity = campo(h, "perc_identity"),
        gene_family   = colapsar_cat(cats, "AMR Gene Family"),
        drug_class    = colapsar_cat(cats, "Drug Class"),
        mechanism     = colapsar_cat(cats, "Resistance Mechanism"),
        antibiotic    = colapsar_cat(cats, "Antibiotic")
      )
    }
  }

  if (length(filas) == 0) stop("No valid hit in the JSON")

  df <- do.call(rbind, lapply(filas, as.data.frame, stringsAsFactors = FALSE)) #Finally we create a df by joining the cols created above
  df
}

# Searches the tsv inside the subfolder 
buscar_tsv <- function(carpeta_muestra) {
  tsvs <- list.files(carpeta_muestra, pattern = "\\.tsv$", full.names = TRUE)
  if (length(tsvs) == 0) stop("No .tsv found in ", carpeta_muestra)
  if (length(tsvs) > 1) {
    cob <- tsvs[grepl("cobertura", basename(tsvs))]
    if (length(cob) == 1) return(cob)
    stop("Several .tsv in ", carpeta_muestra, " not sure which one to use")
  }
  tsvs
}

# Processes a sample and saves the result
procesar_muestra <- function(muestra, ruta_json, ruta_tsv, dir_salida) {
  df <- leer_rgi(ruta_json)
  n_hits <- nrow(df)

  # suppressMessages 
  estadisticas <- suppressMessages(read_tsv(ruta_tsv))
  #Now we have our tsv as a df, but the cols names are really long, so we shorten them
  colnames(estadisticas) <- sub(".* ", "", colnames(estadisticas))
  
  # Check that Gene has the 1_1 format
  estadisticas$Gene <- normalizar_id(estadisticas$Gene)

  # inner_join: only the genes present in both dfs are kept, repeated ids return repeated rows
  # important to keep so it works no matter the dplyr version
  if (packageVersion("dplyr") >= "1.1.0") {
    resultado <- inner_join(estadisticas, df, by = c("Gene" = "id"),
                            relationship = "many-to-many")
  } else {
    resultado <- inner_join(estadisticas, df, by = c("Gene" = "id"))
  }
  # For the repeated genes we keep the one with the highest bitscore
  # Important to turn the bitscore col into numeric, other wise R treats it as text
  resultado_filter <- resultado %>%
    group_by(Gene) %>%
    slice_max(order_by = as.numeric(bit_score), n = 1, with_ties = TRUE) %>% #if two rows have the same id and bitscore value, both are kept
    ungroup()

  salida <- file.path(dir_salida, paste0(muestra, "_genes_resistencia.tsv"))
  write.table(resultado, file = salida, sep = "\t", row.names = FALSE, quote = FALSE)
  nrow(resultado)

  salida_filter <- file.path(dir_salida, paste0(muestra, "_genes_resistencia_filtrado.tsv"))
  write.table(resultado_filter, file = salida_filter, sep = "\t", row.names = FALSE, quote = FALSE)
}

# Now that we have created all the helper functions, we match the samples
jsons <- list.files(dir_json, pattern = "\\.json$", full.names = TRUE)
if (length(jsons) == 0) {
  cat("ERROR: no .json files in", dir_json, "\n")
  quit(status = 1)
}

muestras_json <- sub("(_rgi_annotation)?\\.json$", "", basename(jsons))
names(jsons) <- muestras_json

subcarpetas <- list.dirs(dir_coverm, recursive = FALSE, full.names = TRUE)
names(subcarpetas) <- basename(subcarpetas)

sin_carpeta <- setdiff(muestras_json, names(subcarpetas))
sin_json    <- setdiff(names(subcarpetas), muestras_json)
if (length(sin_carpeta) > 0)
  cat("AVISO: JSON without CoverM subfolder (skipped):",
      paste(sin_carpeta, collapse = ", "), "\n")
if (length(sin_json) > 0)
  cat("AVISO: subfolders without JSON (skipped):",
      paste(sin_json, collapse = ", "), "\n")

muestras <- intersect(muestras_json, names(subcarpetas))
if (length(muestras) == 0) {
  cat("ERROR: no sample has both JSON and CoverM subfile.\n")
  quit(status = 1)
}

# Sample processing

cat("Samples to process:", length(muestras), "\n")
fallidas <- character(0)
 
for (m in muestras) {
  ok <- tryCatch({ # tryCatch processes the samples errors and stores them in the ok variable
    ruta_tsv <- buscar_tsv(subcarpetas[[m]])
    procesar_muestra(m, jsons[[m]], ruta_tsv, dir_salida)
    TRUE # if there are no errors TRUE, otherwise it returns the ERROR messages
  }, error = function(e) {
    cat("ERROR en ", m, ": ", conditionMessage(e), "\n", sep = "")
    FALSE
  })
  if (!ok) fallidas <- c(fallidas, m)
}
 
cat("Properly parsed:", length(muestras) - length(fallidas), "de", length(muestras), "\n")
if (length(fallidas) > 0) {
  cat("With errors:", paste(fallidas, collapse = ", "), "\n")
  quit(status = 1)
}
