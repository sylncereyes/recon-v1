import os
import subprocess
import sys
import time
import logging
import tempfile

# Set up logging
logging.basicConfig(filename='script.log', level=logging.INFO, format='%(message)s')

def run_command(command, log_output=True):
    """Run a shell command and log the output."""
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        if log_output:
            logging.info(result.stdout)
        return result
    except subprocess.CalledProcessError as e:
        logging.error(e.stderr)
        return e

def check_argument():
    """Ensure the script is run with an argument."""
    if len(sys.argv) < 2:
        print("Usage: python script.py <domain>")
        sys.exit(1)
    return sys.argv[1]

def create_workdir(domain):
    """Create a working directory."""
    os.makedirs(domain, exist_ok=True)
    os.chdir(domain)

def clear_screen():
    """Clear the terminal screen."""
    os.system('clear')

def main():
    domain = check_argument()
    create_workdir(domain)
    clear_screen()

    logging.info(f"### Starting Reconnaissance for {domain} ###")

    # Subdomain Finder
    logging.info("### DNS Enumeration - Find Subdomains ###")
    run_command(f"subfinder -silent -d {domain} -all -recursive -o subdomains.txt")
    run_command(f"echo {domain} | haktrails subdomains | anew subdomains.txt")
    run_command(f"curl -s 'https://crt.sh/?q=%25.{domain}&output=json' | jq -r '.[].name_value' | sed 's/\\.//g' | sort -u | grep -o '\\w.{domain}' | anew subdomains.txt")
    run_command(f"curl -s 'https://api.hackertarget.com/hostsearch/?q={domain}' | grep -o '\\w.*{domain}' | anew subdomains.txt")
    run_command(f"curl -s 'https://riddler.io/search/exportcsv?q=pld:{domain}' | grep -Po '(([\w.-])\\.([\w])\\.([A-z]))\\w+' | grep -o '\\w.*{domain}' | anew subdomains.txt")
    run_command(f"shuffledns -silent -d {domain} -w ~/.wordlists/subdomains-top1million-5000.txt -r ~/.wordlists/resolvers.txt -mode bruteforce | anew subdomains.txt")
    time.sleep(2)
    clear_screen()

    # DNS Resolution
    logging.info("### DNS Resolution - Resolve Discovered Subdomains ###")
    run_command("puredns resolve subdomains.txt -r ~/.wordlists/resolvers.txt -w resolved.txt")
    run_command("dnsx -l resolved.txt -silent -json -o dns.json | jq -r '.a?[]?' | anew ips.txt")
    time.sleep(2)
    clear_screen()

    # Port Scanning
    logging.info("### Port Scanning & HTTP Discovery ###")
    run_command(f"nmap -T4 -vv -iL ips.txt --top-ports 3000 -n --open -oX nmap.xml")
    run_command(f"tew -x nmap.xml -dnsx dns.json --vhost -o ports.txt | httpx -silent -json -o http.json")
    run_command("cat http.json | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u | anew http.txt")
    run_command(f"tew -x nmap.xml -dnsx --vhost | anew ports.txt | httpx -silent -json -o http2.json")
    run_command("cat http2.json | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u | anew http.txt")
    time.sleep(2)
    clear_screen()

    # HTTP Probing
    logging.info("### HTTP Probing ###")
    run_command("cat subdomains.txt | httpx -silent -sc | grep 200 | cut -d' ' -f1 | anew hosts.txt")
    run_command("whatweb -i subdomains.txt | grep '200 OK' | cut -d' ' -f1 | anew urls.txt")
    run_command("sed 's/\\x1b\

\[[0-9;]*m//g' urls.txt | awk -F/ '{print $1 \"//\" $3}' | sort -u | anew hosts.txt")
    run_command("cat http.txt | anew hosts.txt")
    run_command("rm -rf urls.txt")
    run_command("cat hosts.txt | httpx -silent -sc -td -ip -o info.txt")
    time.sleep(2)
    clear_screen()

    # Crawling
    logging.info("### Crawling ###")
    run_command("cat hosts.txt | hakrawler -u | tee hak.lst")
    run_command("cat hosts.txt | cariddi -s -err -e -ext 1 -c 50 | tee cariddi.lst")
    run_command("katana -silent -jc -kf all -or -ob -list hosts.txt -concurrency 50 -depth 2 -ef woff,css,png,svg,jpg,woff2,jpeg,gif | anew kat.lst")
    run_command("cat hosts.txt | waybackurls | anew wb.lst")
    run_command("cat hosts.txt | gau --fc 200 --blacklist woff,css,png,svg,jpg,woff2,jpeg,gif | anew gau.lst")
    run_command("cat *.lst | anew crawled.txt")
    run_command("rm -rf *.lst")

    # Loop for Processing Hosts
    logging.info("### Processing Each Host in hosts.txt ###")
    with open("hosts.txt", "r") as f:
        for host in f:
            host = host.strip()
            logging.info(f"Processing host: {host}")
            run_command(f"cat crawled.txt | urldedupe | grep '{host}' | anew endpoints.txt")

    run_command("cat endpoints.txt | uro | anew -q final.txt")
    time.sleep(2)
    clear_screen()

    # Javascript Pulling
    logging.info("### Javascript Pulling ###")
    run_command("cat final.txt | grep '\\.js' | httpx -silent -sr -srd js")
    run_command("cat final.txt | grep -E '\\.js$' | anew jsFiles.txt")
    run_command("cat js/response/index.txt | cut -d' ' -f2 | anew jsFiles.txt")
    time.sleep(2)
    clear_screen()

    # Parameter Filtering
    logging.info("### Parameter Filtering ###")
    patterns = ["idor", "interestingparams", "lfi", "rce", "xss", "redirect", "sqli", "ssrf", "ssti"]
    for pattern in patterns:
        run_command(f"cat final.txt | gf '{pattern}' | anew parameters.txt")
    run_command("cat final.txt | grep '=' | anew parameters.txt")
    run_command("cat final.txt | grep '?' | anew parameters.txt")
    time.sleep(2)
    clear_screen()

    # Vulnerability Scanning
    logging.info("### Vulnerability Scanning ###")
    os.makedirs("vulns", exist_ok=True)
    run_command(f"nuclei -silent -l hosts.txt -t ~/nuclei-templates/http/vulnerabilities/generic/generic-linux-lfi.yaml -c 30 -o vulns/gen_lfi")
    run_command("cat jsFiles.txt | nuclei -silent -t ~/nuclei-templates/http/exposures/ -c 30 -o vulns/exposure")
    run_command("cat final.txt | nuclei -silent -es info,low -c 50 -t ~/nuclei-templates/dast/vulnerabilities/ -dast -o vulns/dast")
    run_command("cat parameters.txt | nuclei -silent -es info,low -c 50 -t ~/nuclei-templates/dast/vulnerabilities/ -dast -o vulns/params_dast")
    time.sleep(2)
    clear_screen()

    run_command("wc -l vulns/* | tee -a script.log")
    logging.info("\nScanning Done ...")

if __name__ == "__main__":
    main()
