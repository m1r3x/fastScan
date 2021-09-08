#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
	sudo rm paused.conf 2>/dev/null
        exit 1
}


if [ $# -eq 0 ]; then
  printf "Usage: ./fastscan.sh <ip address or domain>"
  exit 1
fi

target=$1

if [[ $(ping -c 1 $target -w 5 | grep received | cut -d " " -f 4) != '1' ]]; then
  printf "$target is down!"
  exit 1
fi

if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  :
else
  target=$(getent ahostsv4 $target | head -1 | awk '{ print $1 }')
  printf "Corresponding IP: $target\n"
fi

printf "Performing masscan...\n"

sudo masscan -p- $target --rate 5000 --wait 5 -oG mass.log
printf "\n"

cat mass.log | grep -i time | cut -d " " -f 5 | cut -d "/" -f 1 | sort -n > ports-$target.log
sudo rm mass.log

printf "Open Ports:\n"
cat ports-$target.log
printf "\n"

printf "Performing nmap scan...\n"
sudo nmap -p$(tr '\n' , <ports-$target.log) -sU -sS -sC -sV -Pn -oN nmap-$target.log $target &> /dev/null
printf "\n"

printf "Scan overview:\n"
cat nmap-$target.log | grep -i open
printf "\n"

printf "Detailed scan result is saved in nmap-$target.log"
