#!/bin/bash

# Definir rutas para os servizos
# Directorio do ficheiro docker-compose.yml
DOCKER_COMPOSE_DIR="/home/jefe/hostEZ-web"
# Directorio dos proxectos Vagrant
VAGRANT_PROJECTS_DIR="/home/jefe/hostEZ/vagrant_projects"
# Ruta do script scheduler.sh
SCHEDULER_SCRIPT="/home/jefe/hostEZ/scheduler.sh"
# Directorio para almacenar os logs
LOG_DIR="/home/jefe/hostEZ"

# Crear directorio de logs se non existe
# Asegurar que o directorio estea dispoñible para escribir logs
mkdir -p "$LOG_DIR"

# Comprobar se os directorios e ficheiros existen
# Validar a existencia do directorio de Docker Compose
if [ ! -d "$DOCKER_COMPOSE_DIR" ]; then
    echo "Erro: O directorio de Docker Compose non existe."
    exit 1
fi
# Validar a existencia do directorio de proxectos Vagrant
if [ ! -d "$VAGRANT_PROJECTS_DIR" ]; then
    echo "Erro: O directorio de proxectos Vagrant non existe."
    exit 1
fi
# Validar a existencia do script scheduler
if [ ! -f "$SCHEDULER_SCRIPT" ]; then
    echo "Erro: O script scheduler non existe."
    exit 1
fi

# Iniciar o contedor Docker
# Usar docker-compose para levantar o contedor en modo detached
echo "Iniciando contedor Docker..."
(cd "$DOCKER_COMPOSE_DIR" && docker-compose up -d >> "$LOG_DIR/startup.log" 2>&1) || { echo "Erro ao iniciar o contedor Docker"; exit 1; }

# Iniciar todas as máquinas Vagrant
# Iterar sobre os directorios de proxectos Vagrant e iniciarlos
echo "Iniciando máquinas Vagrant..."
for dir in "$VAGRANT_PROJECTS_DIR"/*; do
    if [ -d "$dir" ]; then
        (cd "$dir" && vagrant up >> "$LOG_DIR/startup.log" 2>&1 &)
    fi
done

# Iniciar o scheduler en segundo plano
# Executar o script scheduler e rexistrar a saída
echo "Iniciando scheduler..."
("$SCHEDULER_SCRIPT" >> "$LOG_DIR/startup.log" 2>&1 &)

echo "Todos os servizos iniciados con éxito."
echo "Comproba o ficheiro de log en $LOG_DIR/startup.log para detalles."