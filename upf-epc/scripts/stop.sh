docker stop pause bess bess-routectl bess-web bess-pfcpiface || true
docker rm -f pause bess bess-routectl bess-web bess-pfcpiface || true
sudo rm -rf /var/run/netns/pause
