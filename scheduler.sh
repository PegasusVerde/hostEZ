#!/bin/bash

# Definir directorios e rutas
UNPROCESSED_DIR=/home/jefe/linked/csv
PROCESSED_DIR=/home/jefe/linked/csvPROCESADO
VAGRANT_PROJECTS_DIR=~/hostEZ/vagrant_projects
PROCESS_SCRIPT=~/hostEZ/process_csv.py
LOG_FILE=/home/jefe/vagrant_scheduler.log

# Verificar e crear directorios se non existen
for dir in "$UNPROCESSED_DIR" "$PROCESSED_DIR" "$VAGRANT_PROJECTS_DIR"; do
    [ -d "$dir" ] || mkdir -p "$dir"
done

# Función para rexistrar mensaxes
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

while true; do
    log "Verificando $UNPROCESSED_DIR ás $(date)"
    for csv in "$UNPROCESSED_DIR"/*.csv; do
        if [ -f "$csv" ]; then
            log "Atopado ficheiro: $csv"
            server_name=$(basename "$csv" .csv | cut -d'_' -f1)
            project_dir="$VAGRANT_PROJECTS_DIR/$server_name"
            export VAGRANT_PROJECTS_DIR

            log "Executando procesamento para $csv"
            python3 "$PROCESS_SCRIPT" "$csv"
            if [ $? -eq 0 ]; then
                log "Procesamento exitoso, movendo $csv a $PROCESSED_DIR"
                mv "$csv" "$PROCESSED_DIR"

                # Iniciando vagrant up en un proceso separado
                log "Iniciando vagrant up en $project_dir nun proceso separado"
                if [ -n "$DISPLAY" ] && command -v xterm >/dev/null 2>&1; then
                    log "Tentando abrir xterm..."
                    xterm -e "bash -c 'cd \"$project_dir\" && vagrant up > vagrant_up.log 2>&1; read -p \"Preme Enter para pechar...\"'" &
                elif [ -n "$DISPLAY" ] && command -v gnome-terminal >/dev/null 2>&1; then
                    log "Tentando abrir gnome-terminal..."
                    gnome-terminal --tab --working-directory="$project_dir" --command="bash -c 'vagrant up > vagrant_up.log 2>&1; read -p \"Preme Enter para pechar...\"'" &
                else
                    log "Sen soporte gráfico, executando en segundo plano..."
                    (cd "$project_dir" && nohup vagrant up > vagrant_up.log 2>&1 & disown) &
                fi
            else
                log "Erro ao procesar $csv"
            fi
        else
            log "Ningún ficheiro CSV atopado nesta iteración"
        fi
    done
    sleep 1
done
