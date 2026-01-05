# Besu Private Network với Tessera

Mạng Hyperledger Besu private với:
- **3 Validator nodes** (QBFT consensus)
- **1 RPC node** (non-validator)
- **1 Tessera** (privacy manager)

## 📁 Cấu trúc thư mục

```
besu-network/
├── config/
│   ├── genesis.json          # Genesis file với QBFT config
│   ├── besu-config.toml      # Besu configuration
│   └── tessera-config.json   # Tessera configuration
├── data/
│   ├── validator1/           # Data cho validator 1
│   ├── validator2/           # Data cho validator 2
│   ├── validator3/           # Data cho validator 3
│   ├── rpc/                  # Data cho RPC node
│   └── tessera/              # Data cho Tessera
├── docker-compose.yml        # Docker Compose configuration
├── init-network.sh           # Script khởi tạo mạng
├── manage.sh                 # Script quản lý mạng
└── README.md                 # File này
```

## 🚀 Hướng dẫn sử dụng

### Bước 1: Khởi tạo mạng

```bash
chmod +x init-network.sh manage.sh
./init-network.sh
```

Script này sẽ:
- Tạo node keys cho tất cả các nodes
- Generate Tessera keys
- Cập nhật genesis.json với validator addresses
- Cập nhật docker-compose.yml với bootnode info

### Bước 2: Khởi động mạng

```bash
./manage.sh start
```

Hoặc:

```bash
docker-compose up -d
```

### Bước 3: Kiểm tra trạng thái

```bash
./manage.sh status
```

## 🔌 Endpoints

### Besu RPC Endpoints

| Node       | HTTP RPC            | WebSocket           | P2P Port | Metrics  |
|------------|---------------------|---------------------|----------|----------|
| Validator1 | http://localhost:8545 | ws://localhost:8546 | 30303    | 9545     |
| Validator2 | http://localhost:8555 | ws://localhost:8556 | 30304    | 9546     |
| Validator3 | http://localhost:8565 | ws://localhost:8566 | 30305    | 9547     |
| RPC Node   | http://localhost:8575 | ws://localhost:8576 | 30306    | 9548     |

### Tessera Endpoints

| Service    | Port  | Description                    |
|------------|-------|--------------------------------|
| P2P        | 9001  | Node-to-node communication     |
| ThirdParty | 9081  | External API                   |
| Q2T        | 9101  | Quorum-to-Tessera (internal)   |

## 📋 Quản lý mạng

```bash
# Khởi động
./manage.sh start

# Dừng
./manage.sh stop

# Khởi động lại
./manage.sh restart

# Xem logs
./manage.sh logs              # Tất cả
./manage.sh logs validator1   # Chỉ validator1

# Xem trạng thái
./manage.sh status

# Xem peers
./manage.sh peers

# Xem validators
./manage.sh validators

# Xóa data (giữ keys)
./manage.sh clean

# Reset hoàn toàn
./manage.sh reset
```

## 🔧 API Examples

### Kiểm tra block number

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    -H "Content-Type: application/json" \
    http://localhost:8545
```

### Xem validators hiện tại

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
    -H "Content-Type: application/json" \
    http://localhost:8545
```

### Gửi transaction

```bash
curl -X POST --data '{
    "jsonrpc":"2.0",
    "method":"eth_sendTransaction",
    "params":[{
        "from": "0xfe3b557e8fb62b89f4916b721be55ceb828dbd73",
        "to": "0x627306090abaB3A6e1400e9345bC60c78a8BEf57",
        "value": "0x1",
        "gas": "0x5208"
    }],
    "id":1
}' \
    -H "Content-Type: application/json" \
    http://localhost:8545
```

### Xem peers

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
    -H "Content-Type: application/json" \
    http://localhost:8545
```

## 🔒 Privacy với Tessera

### Gửi private transaction

```bash
curl -X POST --data '{
    "jsonrpc":"2.0",
    "method":"eea_sendTransaction",
    "params":[{
        "from": "0xfe3b557e8fb62b89f4916b721be55ceb828dbd73",
        "to": "0x627306090abaB3A6e1400e9345bC60c78a8BEf57",
        "value": "0x0",
        "data": "0x608060405234801561001057600080fd5b50...",
        "privateFrom": "<TESSERA_PUBLIC_KEY>",
        "privateFor": ["<RECIPIENT_PUBLIC_KEY>"],
        "restriction": "restricted"
    }],
    "id":1
}' \
    -H "Content-Type: application/json" \
    http://localhost:8545
```

## ⚙️ Cấu hình

### Genesis (QBFT)

- **Block Period**: 5 giây
- **Epoch Length**: 30000 blocks
- **Request Timeout**: 10 giây
- **Chain ID**: 1337

### Besu Node

- **Min Gas Price**: 0
- **RPC APIs**: ETH, NET, QBFT, WEB3, DEBUG, ADMIN, TXPOOL, TRACE
- **Metrics**: Enabled (Prometheus format)

## 🐛 Troubleshooting

### Nodes không kết nối được với nhau

1. Kiểm tra bootnode enode URL trong docker-compose.yml
2. Đảm bảo validator1 đã start trước các node khác
3. Kiểm tra network config: `docker network inspect besu-network_besu-network`

### Tessera không khởi động

1. Kiểm tra logs: `docker-compose logs tessera`
2. Đảm bảo keys đã được generate trong `data/tessera/`
3. Kiểm tra file permissions

### Block không được tạo

1. Đảm bảo có đủ 2/3 validators online (2 trong 3)
2. Kiểm tra genesis extraData đã được cập nhật đúng
3. Xem logs: `./manage.sh logs validator1`

## 📚 Tài liệu tham khảo

- [Hyperledger Besu Documentation](https://besu.hyperledger.org/)
- [Tessera Documentation](https://docs.tessera.consensys.net/)
- [QBFT Consensus](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft)
