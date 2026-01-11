NETWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$NETWORK_DIR/config"
DATA_DIR="$NETWORK_DIR/data"
TEMP_CONF_DIR="$NETWORK_DIR/temp_conf"

# Ví nhận tiền
TARGET_WALLET="e27534CBa9D72450d90e3B4cF747c7DA5DB128e2"
CURRENT_UID=$(id -u); CURRENT_GID=$(id -g)

echo ">>> KHOI TAO MANG 5 NODE (4 Validator + 1 RPC)..."

# 1. Dọn dẹp
docker-compose down -v 2>/dev/null
sudo rm -rf "$DATA_DIR" .env
docker run --rm -v "$NETWORK_DIR:/network" alpine sh -c "rm -rf /network/data /network/temp_conf"

mkdir -p "$DATA_DIR"/{validator1,validator2,validator3,validator4,rpc} "$TEMP_CONF_DIR"

# 2. Tạo Config cho 3 Validator 
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
  "blockchain": { "nodes": { "generate": true, "count": 4 } }
}
EOF

# 3. Generate Keys
echo ">>> Generating Keys..."
docker run --rm -v "$TEMP_CONF_DIR:/conf" -v "$DATA_DIR:/data" hyperledger/besu:latest operator generate-blockchain-config --config-file=/conf/ibftConfigFile.json --to=/data/networkFiles --private-key-file-name=key
docker run --rm -v "$DATA_DIR:/data" alpine chown -R $CURRENT_UID:$CURRENT_GID /data

# 4. Patch Genesis 
echo ">>> Patching Genesis (Zero Gas Fix)..."
docker run --rm -v "$DATA_DIR/networkFiles:/data" python:3.9-slim python3 -c "
import json
path = '/data/genesis.json'
try:
    with open(path, 'r') as f: data = json.load(f)
    data['baseFeePerGas'] = '0x0'
    # ------------------------------------------

    if 'difficulty' not in data: data['difficulty'] = '0x1'
    if 'gasLimit' not in data: data['gasLimit'] = '0x1fffffffffffff'
    if 'alloc' not in data: data['alloc'] = {}
    
    # Cấp tiền cho ví Odoo
    data['alloc']['$TARGET_WALLET'] = { 'balance': '0xffffffffffffffffffffffffffffffffffffffffff' }
    
    # Xóa cancunTime để tránh lỗi fork
    if 'cancunTime' in data['config']: del data['config']['cancunTime']

    with open(path, 'w') as f: json.dump(data, f, indent=2)
    print('SUCCESS: Genesis patched.')
except Exception as e: print(e); exit(1)
"

# 5. Phân phối Key cho Validators
KEYS_DIRS=($(ls "$DATA_DIR/networkFiles/keys"))
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[0]}/key" "$DATA_DIR/validator1/key"
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[0]}/key.pub" "$DATA_DIR/validator1/key.pub"
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[1]}/key" "$DATA_DIR/validator2/key"
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[2]}/key" "$DATA_DIR/validator3/key"
cp "$DATA_DIR/networkFiles/keys/${KEYS_DIRS[3]}/key" "$DATA_DIR/validator4/key"

# 6. Tạo Key riêng cho RPC Node
docker run --rm -v "$DATA_DIR/rpc:/data" python:3.9-slim python3 -c "import secrets; open('/data/key', 'w').write(secrets.token_hex(32))"
docker run --rm -v "$DATA_DIR:/data" alpine chown -R $CURRENT_UID:$CURRENT_GID /data

# 7. Copy Genesis ra thư mục config
cp "$DATA_DIR/networkFiles/genesis.json" "$CONFIG_DIR/genesis.json"

# 8. Tạo file .env chứa Bootnode 
VALIDATOR1_PUBKEY=$(cat "$DATA_DIR/validator1/key.pub" | sed 's/^0x//')
# Lưu ý: IP 172.16.238.10 được quy định trong docker-compose
BOOTNODE_URL="enode://$VALIDATOR1_PUBKEY@172.16.238.10:30303"

echo "BESU_BOOTNODE=$BOOTNODE_URL" > .env
echo ">>> Đã tạo file .env với Bootnode: $BOOTNODE_URL"

rm -rf "$TEMP_CONF_DIR" "$DATA_DIR/networkFiles"
echo ">>> XONG. Hãy chạy: docker-compose up -d"