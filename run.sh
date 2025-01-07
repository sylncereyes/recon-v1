#!/bin/bash

# Ensure the script is run with an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

DOMAIN=$1
WORKDIR=$1

mkdir -p "$WORKDIR" && cd "$WORKDIR"
clear

# Log file setup
LOGFILE="script.log"
echo "### Starting Reconnaissance for $DOMAIN ###" | tee -a "$LOGFILE"

## Subdomain Finder
echo "### DNS Enumeration - Find Subdomains" | tee -a "$LOGFILE"
subfinder -silent -d "$DOMAIN" -all -recursive -o subdomains.txt 2>> "$LOGFILE"
echo "$DOMAIN" | haktrails subdomains | anew subdomains.txt >> "$LOGFILE"
curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" | jq -r '.[].name_value' 2>/dev/null | sed 's/\\.//g' | sort -u | grep -o "\w.$DOMAIN" | anew subdomains.txt >> "$LOGFILE"
curl -s "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" | grep -o "\w.*$DOMAIN" | anew subdomains.txt >> "$LOGFILE"
curl -s "https://riddler.io/search/exportcsv?q=pld:$DOMAIN" | grep -Po "(([\w.-])\.([\w])\.([A-z]))\w+" | grep -o "\w.*$DOMAIN" | anew subdomains.txt >> "$LOGFILE"
shuffledns -silent -d "$DOMAIN" -w ~/wordlists/subdomains-top1million-5000.txt -r ~/wordlists/resolvers.txt -mode bruteforce | anew subdomains.txt >> "$LOGFILE"
sleep 2
clear

## DNS Enumeration
echo "### DNS Resolution - Resolve Discovered Subdomains" | tee -a "$LOGFILE"
puredns resolve subdomains.txt -r ~/wordlists/resolvers.txt -w resolved.txt 2>> "$LOGFILE"
dnsx -l resolved.txt -silent -json -o dns.json | jq -r '.a?[]?' | anew ips.txt >> "$LOGFILE"
dnsx -l subdomains.txt -silent -json -o dns2.json | jq -r '.a?[]?' | anew ips.txt >> "$LOGFILE"
sleep 2
clear

## Port Scanning
echo "### Port Scanning & HTTP Discovery" | tee -a "$LOGFILE"
nmap -T4 -vv -iL ips.txt --top-ports 3000 -n --open -oX nmap.xml 2>> "$LOGFILE"
tew -x nmap.xml -dnsx dns.json --vhost -o ports.txt | httpx -silent -json -o http.json 2>> "$LOGFILE"
cat http.json | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u | anew http.txt >> "$LOGFILE"
tew -x nmap.xml -dnsx --vhost | anew ports.txt | httpx -silent -json -o http2.json 2>> "$LOGFILE"
cat http2.json | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u | anew http.txt >> "$LOGFILE"

nmap -T4 -vv -iL subdomains.txt --top-ports 3000 -n --open -oX nmap2.xml 2>> "$LOGFILE"
tew -x nmap2.xml -dnsx dns2.json --vhost | anew ports.txt | httpx -silent -json -o http3.json 2>> "$LOGFILE"
cat http3.json | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u | anew http.txt >> "$LOGFILE"
tew -x nmap2.xml -dnsx --vhost | anew ports.txt | httpx -silent -json -o http4.json 2>> "$LOGFILE"
cat http4.json | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u | anew http.txt >> "$LOGFILE"
sleep 2
clear

## HTTP Probing
echo "### HTTP Probing" | tee -a "$LOGFILE"
cat subdomains.txt | httpx -silent -sc | grep 200 | cut -d" " -f1 | anew hosts.txt >> "$LOGFILE"
whatweb -i subdomains.txt | grep "200 OK" | cut -d" " -f1 | anew urls.txt >> "$LOGFILE"
sed 's/\x1b\[[0-9;]*m//g' urls.txt | awk -F/ '{print $1 "//" $3}' | sort -u | anew hosts.txt >> "$LOGFILE"
cat http.txt | anew hosts.txt >> "$LOGFILE"
sleep 2
clear

## Crawling
echo "### Crawling" | tee -a "$LOGFILE"
cat hosts.txt | hakrawler -u | tee hak.lst >> "$LOGFILE"
cat hosts.txt | cariddi -s -err -e -ext 1 -c 50 | tee cariddi.lst >> "$LOGFILE"
katana -silent -jc -kf all -or -ob -list hosts.txt -concurrency 50 -depth 2 -ef woff,css,png,svg,jpg,woff2,jpeg,gif | anew kat.lst >> "$LOGFILE"
cat hosts.txt | waybackurls | anew wb.lst >> "$LOGFILE"
cat hosts.txt | gau --fc 200 --blacklist woff,css,png,svg,jpg,woff2,jpeg,gif | anew gau.lst >> "$LOGFILE"
cat *.lst | anew crawled.txt >> "$LOGFILE"
rm -rf *.lst

# Loop for Processing Hosts
echo "### Processing Each Host in hosts.txt" | tee -a "$LOGFILE"
while IFS= read -r host; do
  echo "Processing host: $host" | tee -a "$LOGFILE"
  cat crawled.txt | urldedupe | grep "$host" | anew endpoints.txt >> "$LOGFILE"
done < hosts.txt
sleep 2
clear

## Javascript Pulling
echo "### Javascript Pulling" | tee -a "$LOGFILE"
cat endpoints.txt | grep "\.js" | httpx -silent -sr -srd js >> "$LOGFILE"
cat endpoints.txt | grep -E "\.js$" | anew jsFiles.txt >> "$LOGFILE"
cat js/response/index.txt | cut -d" " -f2 | anew jsFiles.txt >> "$LOGFILE"
sleep 2
clear

## Parameter Filtering
echo "### Parameter Filtering" | tee -a "$LOGFILE"
for pattern in idor interestingparams lfi rce xss redirect sqli ssrf ssti; do
  cat endpoints.txt | gf "$pattern" | anew parameters.txt >> "$LOGFILE"
done
cat endpoints.txt | grep "=" | anew parameters.txt >> "$LOGFILE"
cat endpoints.txt | grep "?" | anew parameters.txt >> "$LOGFILE"
sleep 2
clear

## Vuln Scanning
echo "### Vulnerability Scanning" | tee -a "$LOGFILE"
mkdir -p vulns
nuclei -silent -l hosts.txt -t ~/nuclei-templates/http/vulnerabilities/generic/generic-linux-lfi.yaml -c 30 -o vulns/gen_lfi >> "$LOGFILE"
cat jsFiles.txt | nuclei -silent -t ~/nuclei-templates/http/exposures/ -c 30 -o vulns/exposure >> "$LOGFILE"
cat endpoints.txt | nuclei -silent -es info,low -c 50 -t ~/nuclei-templates/dast/vulnerabilities/ -dast -o vulns/dast >> "$LOGFILE"
cat parameters.txt | nuclei -silent -es info,low -c 50 -t ~/nuclei-templates/dast/vulnerabilities/ -dast -o vulns/params_dast >> "$LOGFILE"
cat parameters.txt | grep "?" | qsreplace ../../../../etc/passwd | ffuf -u 'FUZZ' -w - -mr '^root:' -c -mc 200 -o vulns/lfi >> "$LOGFILE"
sleep 2
clear

wc -l vulns/* | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"
echo "Scanning Done ..." | tee -a "$LOGFILE"
