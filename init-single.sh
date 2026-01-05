#!/bin/bash
# init-single.sh - FINAL FIX (BaseFee=0)

NETWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$NETWORK_DIR/config"
DATA_DIR="$NETWORK_DIR/data"
TEMP_CONF_DIR="$NETWORK_DIR/temp_conf"
TARGET_WALLET="e27534CBa9D72450d90e3B4cF747c7DA5DB128e2"
CURRENT_UID=$(id -u); CURRENT_GID=$(id -g)

echo ">>> KHOI TAO CHE DO 1 NODE (FIX GAS)..."

# 1. Don dep
docker run --rm -v "$NETWORK_DIR:/network" alpine sh -c "rm -rf /network/data /network/temp_conf"
if [ -d "$DATA_DIR" ]; then sudo rm -rf "$DATA_DIR"; fi
mkdir -p "$DATA_DIR"/validator1 "$TEMP_CONF_DIR"

# 2. Config
cat <<EOF > "$TEMP_CONF_DIR/ibftConfigFile.json"
{
  "genesis": {
    "config": {
      "chainId": 1337,
      "homesteadBlock": 0, "eip150Block": 0, "eip155Block": 0, "eip158Block": 0,
      "byzantiumBlock": 0, "constantinopleBlock": 0, "petersburgBlock": 0,
      "istanbulBlock": 0, "berlinBlock": 0, "londonBlock": 0,
      "parisBlock": 0, "shanghaiBlock": 0,
      "qbft": { "blockperiodseconds": 2, "epochlength": 30000, "requesttimeoutseconds": 4 }
    }
  },
  "blockchain": { "nodes": { "generate": true, "count": 1 } }
}
EOF

# 3. Generate Key
docker run --rm -v "$TEMP_CONF_DIR:/conf" -v "$DATA_DIR:/data" hyperledger/besu:latest operator generate-blockchain-config --config-file=/conf/ibftConfigFile.json --to=/data/networkFiles --private-key-file-name=key
docker run --rm -v "$DATA_DIR:/data" alpine chown -R $CURRENT_UID:$CURRENT_GID /data

# 4. Patch Genesis (Them baseFeePerGas)
docker run --rm -v "$DATA_DIR/networkFiles:/data" python:3.9-slim python3 -c "
import json
path = '/data/genesis.json'
try:
    with open(path, 'r') as f: data = json.load(f)
    
    # --- QUAN TRỌNG: SET BASE FEE VỀ 0 ĐỂ KHÔNG BỊ TREO ---
    data['baseFeePerGas'] = '0x0'
    # ------------------------------------------------------

    if 'difficulty' not in data: data['difficulty'] = '0x1'
    if 'gasLimit' not in data: data['gasLimit'] = '0x1fffffffffffff'
    if 'alloc' not in data: data['alloc'] = {}
    data['alloc']['$TARGET_WALLET'] = { 'balance': '0xffffffffffffffffffffffffffffffffffffffffff' }
    
    if 'cancunTime' in data['config']: del data['config']['cancunTime']

    with open(path, 'w') as f: json.dump(data, f, indent=2)
    print('SUCCESS')
except Exception as e: print(e); exit(1)
"

# 5. Install
KEYS_DIRS=($(ls "$DATA_DIR/networkFiles/keys"))
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[0]}/key" "$DATA_DIR/validator1/key"
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[0]}/key.pub" "$DATA_DIR/validator1/key.pub"
cp "$DATA_DIR/networkFiles/genesis.json" "$CONFIG_DIR/genesis.json"

rm -rf "$TEMP_CONF_DIR" "$DATA_DIR/networkFiles"
echo ">>> XONG."