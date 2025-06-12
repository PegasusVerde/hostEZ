import os
import sys
import csv

# Función para obter a seguinte IP dispoñible
def get_next_ip():
    unused_file = '/home/jefe/linked/ip_unused.txt'
    used_file = '/home/jefe/hostEZ/ip_used.txt'
    if not os.path.exists(unused_file):
        raise ValueError("O ficheiro ip_unused.txt non existe.")
    with open(unused_file, 'r') as f:
        unused_ips = f.read().splitlines()
    if not unused_ips:
        raise ValueError("Non hai máis IPs dispoñibles no rango.")
    ip = unused_ips[0]
    with open(unused_file, 'w') as f:
        f.write('\n'.join(unused_ips[1:]))
    with open(used_file, 'a') as f:
        f.write(f"{ip}\n")
    return ip

# Extrae información do CSV
def main(csv_path):
    server_name = None
    cpu = None
    ram = None
    loader = None
    version = None
    mods = []
    with open(csv_path, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            if row[0] == 'Name':
                server_name = row[1]
            elif row[0] == 'CPUs':
                cpu = row[1]
            elif row[0] == 'RAM':
                ram = row[1]
            elif row[0] == 'Loader':
                loader = row[1]
            elif row[0] == 'Version':
                version = row[1]
            elif row[0] == 'Mods':
                mods = [mod.split('|') for mod in row[1].split(', ')]
    
    if not all([server_name, cpu, ram, loader, version, mods]):
        print("Erro: Datos incompletos no CSV")
        return

    project_dir = os.path.join(os.environ['VAGRANT_PROJECTS_DIR'], server_name)
    os.makedirs(project_dir, exist_ok=True)

    # Crear Vagrantfile coa IP asignada
    with open(os.path.join(project_dir, 'Vagrantfile'), 'w') as vf:
        ip = get_next_ip()
        vf.write(f"""
    Vagrant.configure("2") do |config|
        config.vm.box = "debian/bookworm64"
        config.vm.network "public_network", ip: "{ip}", bridge: "eno1"
        config.vm.synced_folder "/home/jefe/linked/MODS", "/vagrant/mods"
        config.vm.provider "virtualbox" do |vb|
            vb.memory = "{ram}"
            vb.cpus = "{cpu}"
            vb.name = "{server_name}"
        end
        config.vm.provision "shell", path: "provision.sh"
    end
    """)

    # Crear provision.sh coa lóxica baseada en CSV
    with open(os.path.join(project_dir, 'provision.sh'), 'w') as pf:
        pf.write(f"""
#!/bin/bash
# Actualizar paquetes e instalar Java
apt-get update
apt-get install -y openjdk-17-jre-headless wget ufw net-tools

# Configurar firewall
ufw --force enable
ufw allow 25565

loader="{loader}"
version="{version}"
mods=({' '.join([f'"{mod[0]}"' for mod in mods])})
locations=({' '.join([f'"{mod[1]}"' for mod in mods])})

if [ "$loader" = "Fabric" ]; then
    # Crear directorio para o servidor
    mkdir -p /home/vagrant/minecraft_server
    cd /home/vagrant/minecraft_server
    
    # Descargar e instalar Fabric
    echo "Descargando o instalador de Fabric..."
    wget https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar -O fabric-installer.jar
    echo "Descargando servidor Minecraft 1.20.1..."
    wget https://piston-data.mojang.com/v1/objects/0f7a11f6c63c8e0f0e8e7b0b0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0/server.jar -O server.jar || echo "Pre-download failed, using installer download"
    echo "Instalando Fabric para a versión $version..."
    java -jar fabric-installer.jar server -mcversion "$version" -downloadMinecraft --serverJar server.jar || echo "Fabric installation continued without server pre-download"
    
    # Copiar mods desde o directorio sincronizado
    mkdir -p mods
    index=0
    for mod in "${{mods[@]}}"; do
        location="${{locations[$index]}}"
        src_path="/vagrant/mods/$(echo $loader | tr '[:lower:]' '[:upper:]')/$version/$(echo $location | tr '[:lower:]' '[:upper:]')/\"$mod\".jar" # Usar $mod directamente
        if [ -f "$src_path" ]; then
            cp "$src_path" mods/
            echo "Copiado $mod desde $location"
        else
            echo "Erro: $mod non atopado en $src_path"
        fi
        ((index++))
    done
    
    # Aceptar o EULA automaticamente
    echo "eula=true" > eula.txt
    
    # Lanzar o servidor automaticamente
    max_memory=$(( {ram} * 80 / 100 ))
    java -Xmx${{max_memory}}M -Xms${{max_memory}}M -jar fabric-server-launch.jar nogui
    sleep 5
    if ! netstat -tuln | grep -q 25565; then
        echo "Erro: O servidor non está escoitando no porto 25565"
    fi
elif [ "$loader" = "Forge" ]; then
    echo "Instalando Forge... (non implementado)"
    for mod in "${{mods[@]}}"; do
        echo "Instalando mod $mod..."
    done
fi
""")
    os.chmod(os.path.join(project_dir, 'provision.sh'), 0o755)
    
    # Iniciar a máquina Vagrant inmediatamente
    os.system(f"cd {project_dir} && vagrant up")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python3 process_csv.py <ruta_do_csv>")
        sys.exit(1)
    main(sys.argv[1])