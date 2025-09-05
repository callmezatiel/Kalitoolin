#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ───────────────────────────────────────────────
#  BANNER
# ───────────────────────────────────────────────
banner() {
  printf "\e[1;93m"
  printf "   _  __     _       _     _             _       _ \n"
  printf "  | |/ /__ _| |_ ___| |__ (_)_ __   __ _| |_ ___| |\n"
  printf "  | ' // _\` | __/ __| '_ \\| | '_ \\ / _\` | __/ _ \\ |\n"
  printf "  | . \\ (_| | || (__| | | | | | | | (_| | ||  __/ |\n"
  printf "  |_|\\_\\__,_|\\__\\___|_| |_|_|_| |_|\\__,_|\\__\\___|_|\n"
  printf "\e[0m\n"
  printf "\e[1;77m        Kali Tools Installer · by Zatiel 🧠\e[0m\n\n"
}

# ───────────────────────────────────────────────
#  DEPENDENCIAS
# ───────────────────────────────────────────────
check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[+] Instalando dependencia: $1"
    sudo apt-get update && sudo apt-get install -y "$1"
  }
}

# ───────────────────────────────────────────────
#  CREAR LANZADOR .DESKTOP
# ───────────────────────────────────────────────
create_desktop_launcher() {
  local name="$1" exec_cmd="$2" icon="$3"
  local file="$HOME/.local/share/applications/${name// /_}.desktop"
  cat > "$file" <<EOF
[Desktop Entry]
Name=$name
Exec=$exec_cmd
Icon=$icon
Type=Application
Categories=Security;Network;
Terminal=false
EOF
  chmod +x "$file"
  echo "[*] Lanzador creado: $name"
}

# ───────────────────────────────────────────────
#  INSTALADORES DE TOOLS
# ───────────────────────────────────────────────

install_tool() {
  echo "[*] Instalando $1 desde repositorios..."
  sudo apt-get install -y "$1"
  create_desktop_launcher "$(echo "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')" "$1" ""
}

install_maltego() {
  echo "[*] Instalando Maltego desde fuente oficial..."
  local wd="$HOME/maltego_tmp"
  mkdir -p "$wd" && cd "$wd"
  wget -q -c https://downloads.maltego.com/maltego-v4/linux/Maltego.v4.10.0.deb
  sudo apt-get install -y default-jre ./Maltego.v4.10.0.deb
  cd ~ && rm -rf "$wd"
  create_desktop_launcher "Maltego" "/usr/bin/maltego" "maltego"
}

install_burp() {
  echo "[*] Burp Suite requiere descarga manual por licencia."
  echo "[!] Abriendo navegador para descargar Burp Suite Community..."
  xdg-open "https://portswigger.net/burp/communitydownload" &>/dev/null || true
  echo "[*] Una vez descargado el archivo .sh, ejecútalo con:"
  echo "    chmod +x burpsuite_community_linux*.sh && ./burpsuite_community_linux*.sh"
}

install_metasploit() {
  echo "[*] Instalando Metasploit Framework desde fuente oficial..."
  curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o msfinstall
  chmod +x msfinstall && sudo ./msfinstall && rm msfinstall
  msfdb init || true
  create_desktop_launcher "Metasploit" "msfconsole" ""
}

# ───────────────────────────────────────────────
#  TOP 10 TOOLS DE KALI – LISTADO
# ───────────────────────────────────────────────
top10_tools=(
  "nmap|Nmap: escáner de red"
  "metasploit|Metasploit: explotación y pruebas de intrusión"
  "wireshark|Wireshark: analizador de protocolos de red"
  "burpsuite|Burp Suite: análisis de seguridad web"
  "owasp-zap|OWASP ZAP: escáner automatizado de apps web"
  "aircrack-ng|Aircrack-ng: auditoría de redes WiFi"
  "hydra|Hydra: ataques de fuerza bruta a contraseñas"
  "john|John the Ripper: cracking de contraseñas"
  "sqlmap|SQLMap: ataques de inyección SQL"
  "nikto|Nikto: escáner de vulnerabilidades web"
)

# ───────────────────────────────────────────────
#  INSTALACIÓN INTERACTIVA DEL TOP 10
# ───────────────────────────────────────────────
install_top10_interactive() {
  while true; do
    echo -e "\nSeleccione una herramienta del Top 10 para instalar:"
    for i in "${!top10_tools[@]}"; do
      IFS='|' read -r id desc <<< "${top10_tools[$i]}"
      printf "  %2d) %-12s - %s\n" $((i+1)) "$id" "$desc"
    done
    echo "  0) Volver al menú principal"
    read -rp "Opción [0-${#top10_tools[@]}]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#top10_tools[@]} )); then
      IFS='|' read -r tool_id tool_desc <<< "${top10_tools[$((choice-1))]}"
      echo -e "\n[*] Instalando $tool_id..."
      case "$tool_id" in
        burpsuite)
          install_burp ;;
        metasploit)
          install_metasploit ;;
        maltego)
          install_maltego ;;
        *)
          install_tool "$tool_id" ;;
      esac
    elif [[ "$choice" == "0" ]]; then
      break
    else
      echo "Opción no válida. Intente de nuevo."
    fi
  done
}

# ───────────────────────────────────────────────
#  MENÚ PRINCIPAL
# ───────────────────────────────────────────────
show_menu() {
  echo -e "\nSeleccione qué desea hacer:"
  echo "  1) Instalar herramientas individuales del Top 10 de Kali"
  echo "  2) Instalar TODO el Top 10 + herramientas desde sitios oficiales"
  echo "  3) Salir"
  read -rp "Opción [1-3]: " opt
  case "$opt" in
    1)
      install_top10_interactive
      ;;
    2)
      for entry in "${top10_tools[@]}"; do
        IFS='|' read -r tool_id _ <<< "$entry"
        case "$tool_id" in
          burpsuite)
            install_burp ;;
          metasploit)
            install_metasploit ;;
          maltego)
            install_maltego ;;
          *)
            install_tool "$tool_id" ;;
        esac
      done
      install_maltego
      ;;
    *)
      echo "Saliendo..."; exit 0 ;;
  esac
}

# ───────────────────────────────────────────────
#  MAIN
# ───────────────────────────────────────────────
main() {
  banner
  for cmd in apt wget curl; do check_command "$cmd"; done
  show_menu
  echo -e "\n[*] Instalación finalizada. ¡Feliz hacking ético!"
}

main "$@"
