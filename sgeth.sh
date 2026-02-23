geth --dev \
  --http --http.addr localhost --http.port 8545 \
  --http.api eth,net,web3,debug \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --ws --ws.addr localhost --ws.port 8546 \
  --ws.api eth,net,web3,debug \
  --allow-insecure-unlock
