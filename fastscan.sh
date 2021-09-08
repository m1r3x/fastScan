#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "Usage: ./fastscan.sh <ip address or domain>"
    exit 1
fi

target=$1

#read -p "Enter domain name/ip to be scanned: " target

if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  :
else
  target=$(getent ahostsv4 $target | head -1 | awk '{ print $1 }')
  echo "Corresponding IP: $target"
fi

echo "Performing masscan..."

sudo masscan -p- $target --rate 5000 -oG mass.log

cat mass.log | grep -i time | cut -d " " -f 5 | cut -d "/" -f 1 | sort -n > mass-$target.log
sudo rm mass.log

echo "Open Ports:"
cat mass-$target.log

echo "Performing nmap scan..."
nmap -p$(tr '\n' , <mass-$target.log) -sV -sC -vv -T4 -Pn -oN nmap-$target.log $target

echo "Results:"
cat nmap-$target.log

