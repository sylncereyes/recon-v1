import os
import subprocess
import sys

def run_command(command, check=True):
    """Run a shell command."""
    print(f"Running command: {command}")
    result = subprocess.run(command, shell=True, check=check)
    return result

def check_root():
    """Check if the script is run as root."""
    if os.geteuid() != 0:
        print("Harap jalankan skrip ini dengan sudo atau sebagai root")
        sys.exit(1)

def install_packages():
    """Update and install necessary packages."""
    print("### Memulai proses instalasi alat-alat pentesting... ###")
    print()
    
    print("Memperbarui paket...")
    run_command("apt update -y && apt upgrade -y")

    print("Menginstal dependensi dasar...")
    packages = [
        "golang-go", "git", "wget", "curl", "jq", "nmap", "whatweb",
        "masscan", "exploitdb", "ffuf", "dnsutils", "python3-pip",
        "unzip", "sudo", "build-essential"
    ]
    run_command(f"apt install -y {' '.join(packages)}")

def install_go(go_version="1.23.4"):
    """Install Go tools."""
    print("Menginstal Go tools...")
    
    if not subprocess.run("command -v go", shell=True).returncode == 0:
        print("Go tidak ditemukan, menginstal Go...")
        run_command(f"wget https://go.dev/dl/go{go_version}.linux-amd64.tar.gz")
        run_command(f"tar -C /usr/local -xvzf go{go_version}.linux-amd64.tar.gz")
        os.environ["PATH"] += ":/usr/local/go/bin"
        print("Go berhasil diinstal.")
        os.remove(f"go{go_version}.linux-amd64.tar.gz")  # Hapus file tar.gz
    else:
        print("Go sudah terinstal.")

def install_go_tools():
    """Install tools using Go."""
    tools = [
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder",
        "github.com/hakluke/haktrails",
        "github.com/projectdiscovery/shuffledns/cmd/shuffledns",
        "github.com/d3mondev/puredns/v2",
        "github.com/projectdiscovery/dnsx/cmd/dnsx",
        "github.com/pry0cc/tew",
        "github.com/projectdiscovery/httpx/cmd/httpx",
        "github.com/hakluke/hakrawler",
        "github.com/edoardottt/cariddi/cmd/cariddi",
        "github.com/projectdiscovery/katana/cmd/katana",
        "github.com/tomnomnom/waybackurls",
        "github.com/lc/gau/v2/cmd/gau",
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei",
        "github.com/tomnomnom/qsreplace",
        "github.com/tomnomnom/anew",
        "github.com/tomnomnom/gf"
    ]

    for tool in tools:
        run_command(f"go install -v {tool}@latest")

    run_command("mv ~/go/bin/* /usr/local/bin/")

def download_wordlists():
    """Download wordlists."""
    print("Mengunduh wordlists...")
    os.makedirs(os.path.expanduser("~/.wordlists"), exist_ok=True)
    os.chdir(os.path.expanduser("~/.wordlists"))

    wordlists = [
        "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt",
        "https://raw.githubusercontent.com/bigb0x/dns-resolvers/master/resolvers.txt",
        "https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/api-endpoints.txt",
        "https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/bypasses.txt",
        "https://raw.githubusercontent.com/gotr00t0day/spyhunt/refs/heads/main/payloads/traversal.txt",
        "https://raw.githubusercontent.com/coffinxp/loxs/refs/heads/main/payloads/xsspollygots.txt",
        "https://raw.githubusercontent.com/coffinxp/loxs/refs/heads/main/payloads/or.txt",
        "https://raw.githubusercontent .com/gotr00t0day/spyhunt/refs/heads/main/payloads/xss.txt"
    ]
    
    for url in wordlists:
        run_command(f"wget {url}")

    os.makedirs(os.path.expanduser("~/.wordlists/files_xss"), exist_ok=True)
    os.chdir(os.path.expanduser("~/.wordlists/files_xss"))
    run_command("wget https://raw.githubusercontent.com/coffinxp/loxs/refs/heads/main/payloads/xss.txt")
    run_command("mv xss.txt | anew -q ../xss.txt")
    run_command("rm -rf xss.txt")

def download_nuclei_templates():
    """Download Nuclei templates."""
    print("Mengunduh template Nuclei...")
    run_command("git clone https://github.com/projectdiscovery/nuclei-templates.git ~/nuclei-templates")

def setup_haktools():
    """Setup haktools and configuration."""
    run_command("searchsploit -update")
    os.makedirs(os.path.expanduser("~/.config/haktools"), exist_ok=True)
    run_command("touch ~/.config/haktools/haktrails-config.yml")

    os.makedirs(os.path.expanduser("~/.tools"), exist_ok=True)
    os.chdir(os.path.expanduser("~/.tools"))
    run_command("git clone https://github.com/tomnomnom/gf.git")

    shell = os.environ.get("SHELL")
    if shell in ["/bin/zsh", "/usr/bin/zsh"]:
        print("Menambahkan konfigurasi gf untuk Zsh...")
        run_command("echo 'source ~/.tools/gf/gf-completion.zsh' >> ~/.zshrc")
        print("Konfigurasi Zsh berhasil diperbarui.")
    else:
        print("Menambahkan konfigurasi gf untuk Bash...")
        run_command("echo 'source ~/.tools/gf/gf-completion.bash' >> ~/.bashrc")
        print("Konfigurasi Bash berhasil diperbarui.")

    os.makedirs(os.path.expanduser("~/.gf"), exist_ok=True)
    run_command("cp -r ~/.tools/gf/examples ~/.gf")
    os.chdir(os.path.expanduser("~/.tools"))
    run_command("git clone https://github.com/1ndianl33t/Gf-Patterns.git")
    run_command("mv ~/.tools/Gf-Patterns/*.json ~/.gf")

def check_git():
    """Check if git is installed."""
    if subprocess.run("command -v git", shell=True).returncode != 0:
        print("Git belum terinstal, menginstal Git...")
        run_command("apt install -y git")

def main():
    check_root()
    install_packages()
    install_go()
    install_go_tools()
    download_wordlists()
    download_nuclei_templates()
    setup_haktools()
    check_git()

    print("### Semua alat telah berhasil diinstal. ###")
    print("Untuk menjalankan skrip reconnaissance, jalankan skrip yang sesuai setelah konfigurasi selesai.")
    print("Pastikan Anda memiliki akses ke domain dan memiliki izin untuk melakukan pemindaian.")
    print("Skrip ini menginstal alat-alat penting untuk reconnaissance dan pemindaian.")

if __name__ == "__main__":
    main()
