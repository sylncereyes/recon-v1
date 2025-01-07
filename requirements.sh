#!/bin/bash

set -e  # Hentikan skrip jika ada perintah yang gagal

# Periksa apakah skrip dijalankan dengan akses root (sudo)
if [[ $EUID -ne 0 ]]; then
    echo "Harap jalankan skrip ini dengan sudo atau sebagai root"
    exit 1
fi

echo "### Memulai proses instalasi alat-alat pentesting... ###"
echo

# Update paket dan upgrade
echo "Memperbarui paket..."
apt update -y && apt upgrade -y

# Instalasi alat dasar
echo "Menginstal dependensi dasar..."
apt install -y \
    golang-go \
    git \
    wget \
    curl \
    jq \
    nmap \
    whatweb \
    masscan \
    exploitdb \
    ffuf \
    dnsutils \
    python3-pip \
    unzip \
    sudo \
    build-essential

# Menginstal Go tools
GO_VERSION="1.23.4"
echo "Menginstal Go tools..."

# Pastikan Go terinstal
if ! command -v go &> /dev/null; then
    echo "Go tidak ditemukan, menginstal Go..."
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    tar -C /usr/local -xvzf go${GO_VERSION}.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo "Go berhasil diinstal."
    rm go${GO_VERSION}.linux-amd64.tar.gz  # Hapus file tar.gz
else
    echo "Go sudah terinstal."
fi

# Menginstal alat menggunakan Go
declare -a tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/hakluke/haktrails"
    "github.com/projectdiscovery/shuffledns/cmd/shuffledns"
    "github.com/d3mondev/puredns/v2"
    "github.com/projectdiscovery/dnsx/cmd/dnsx"
    "github.com/pry0cc/tew"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/hakluke/hakrawler"
    "github.com/edoardottt/cariddi/cmd/cariddi"
    "github.com/projectdiscovery/katana/cmd/katana"
    "github.com/tomnomnom/waybackurls"
    "github.com/lc/gau/v2/cmd/gau"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "github.com/tomnomnom/qsreplace"
    "github.com/tomnomnom/anew"
    "github.com/tomnomnom/gf"
)

for tool in "${tools[@]}"; do
    go install -v "$tool"@latest
done

mv ~/go/bin/* /usr/local/bin/

# Mengunduh wordlists
echo "Mengunduh wordlists..."
mkdir -p ~/.wordlists
cd ~/.wordlists

# Und uh wordlist subdomains dan resolvers
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt
wget https://raw.githubusercontent.com/bigb0x/dns-resolvers/master/resolvers.txt
wget https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/api-endpoints.txt
wget https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/bypasses.txt
wget https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/traversal.txt
wget https://raw.githubusercontent.com/coffinxp/loxs/refs/heads/main/payloads/xsspollygots.txt
wget https://raw.githubusercontent.com/coffinxp/loxs/refs/heads/main/payloads/or.txt
wget https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/xss.txt
mkdir -p files_xss
cd files_xss
wget https://raw.githubusercontent.com/coffinxp/loxs/refs/heads/main/payloads/xss.txt
mv xss.txt | anew -q ../xss.txt
rm -rf xss.txt

# Mengunduh template Nuclei
cd
echo "Mengunduh template Nuclei..."
git clone https://github.com/projectdiscovery/nuclei-templates.git ~/nuclei-templates

# Mengunduh tools pendukung
searchsploit -update
cd
mkdir -p .config/haktools
touch .config/haktools/haktrails-config.yml

mkdir -p .tools
cd .tools
git clone https://github.com/tomnomnom/gf.git
# Periksa apakah shell yang digunakan adalah zsh
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    echo "Menambahkan konfigurasi gf untuk Zsh..."
    echo 'source ~/.tools/gf/gf-completion.zsh' >> ~/.zshrc
    echo "Konfigurasi Zsh berhasil diperbarui."
else
    echo "Menambahkan konfigurasi gf untuk Bash..."
    echo 'source ~/.tools/gf/gf-completion.bash' >> ~/.bashrc
    echo "Konfigurasi Bash berhasil diperbarui."
fi
cd
mkdir .gf
cp -r ~/.tools/gf/examples ~/.gf
cd .tools
git clone https://github.com/1ndianl33t/Gf-Patterns.git
cd
mv ~/.tools/Gf-Patterns/*.json ~/.gf
cd

# Periksa apakah git telah terinstal
if ! command -v git &> /dev/null; then
    echo "Git belum terinstal, menginstal Git..."
    apt install -y git
fi

# Semua alat telah berhasil diinstal
echo "### Semua alat telah berhasil diinstal. ###"
echo "Untuk menjalankan skrip reconnaissance, jalankan skrip yang sesuai setelah konfigurasi selesai."
echo "Pastikan Anda memiliki akses ke domain dan memiliki izin untuk melakukan pemindaian."
echo "Skrip ini menginstal alat-alat penting untuk reconnaissance dan pemindaian."

exit 0
