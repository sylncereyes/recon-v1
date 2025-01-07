#!/bin/bash

# Periksa apakah skrip dijalankan dengan akses root (sudo)
if [[ $EUID -ne 0 ]]; then
    echo "Harap jalankan skrip ini dengan sudo atau sebagai root"
    exit 1
fi

echo "### Memulai proses instalasi alat-alat pentesting... ###"
echo

# Update paket dan upgrade
echo "Memperbarui paket..."
apt-get update && apt-get upgrade -y

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
    exploitdb \
    ffuf \
    dnsutils \
    python3-pip \
    unzip \
    sudo \
    build-essential

# Menginstal Go tools (subfinder, haktrails, shuffledns, puredns, dnsx, tew, httpx, hakrawler, cariddi, katana, waybackurls, gau, nuclei, gf, qsreplace)
echo "Menginstal Go tools..."

# Pastikan Go terinstal
if ! command -v go &> /dev/null; then
    echo "Go tidak ditemukan, menginstal Go..."
    wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
    tar -C /usr/local -xvzf go1.23.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo "Go berhasil diinstal."
else
    echo "Go sudah terinstal."
fi

# Menginstal alat menggunakan Go
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/hakluke/haktrails@latest
go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install github.com/d3v0lver/puredns@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/s0md3v/tew@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/hakluke/hakrawler@latest
go install github.com/mitre/cariddi@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/1ndianl33t/Gf@latest
go install github.com/eq4/qsreplace@latest
go install -v github.com/tomnomnom/anew@latest
mv /go/bin/* /usr/local/bin/

# Mengunduh wordlists (subdomain, resolvers, dan lainnya)
echo "Mengunduh wordlists..."
mkdir -p ~/.wordlists
cd ~/.wordlists

# Unduh wordlist subdomains dan resolvers
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
cat xss.txt | anew -q ../xss.txt
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

# Periksa apakah git telah terinstal
if ! command -v git &> /dev/null; then
    echo "Git belum terinstal, menginstal Git..."
    apt-get install -y git
fi

# Semua alat telah berhasil diinstal
echo "### Semua alat telah berhasil diinstal. ###"
echo "Untuk menjalankan skrip reconnaissance, jalankan skrip yang sesuai setelah konfigurasi selesai."
echo "Pastikan Anda memiliki akses ke domain dan memiliki izin untuk melakukan pemindaian."
echo "Skrip ini menginstal alat-alat penting untuk reconnaissance dan pemindaian kerentanan."

exit 0
