Repository này triển khai **mạng Blockchain riêng tư** sử dụng **Hyperledger Besu** với cơ chế đồng thuận **QBFT (Quorum Byzantine Fault Tolerance)**.  
Hệ thống được thiết kế theo **kiến trúc cluster tiêu chuẩn**, tách biệt rõ ràng giữa lớp đồng thuận (Validator) và lớp truy cập bên ngoài (RPC), phù hợp cho môi trường phát triển, thử nghiệm và các mạng consortium nội bộ.

Toàn bộ hệ thống được container hóa bằng Docker nhằm đảm bảo khả năng triển khai nhanh, nhất quán và dễ quản lý.

---

## Kiến trúc hệ thống

Mạng bao gồm **4 node Besu** chạy trong một Docker network riêng biệt:

- **3 Validator Nodes**
  - Tham gia cơ chế đồng thuận QBFT.
  - Chỉ giao tiếp P2P nội bộ qua cổng `30303`.
  - Không mở RPC ra bên ngoài để đảm bảo an toàn.

- **1 RPC Node**
  - Kết nối tới các Validator trong mạng nội bộ.
  - Mở JSON-RPC endpoint duy nhất (`8545`) ra host.
  - Là điểm truy cập duy nhất cho Metamask, backend, script Web3.

Ngoài ra có **Block Explorer** kết nối trực tiếp tới RPC node để hiển thị dữ liệu blockchain.

---

## Tính năng chính

- **QBFT Consensus**
  - Đảm bảo tính toàn vẹn và chống lỗi Byzantine.
  - Finality tức thì, không xảy ra chain reorg.
  - Thời gian tạo block: 2 giây.

- **Zero Gas Fees**
  - `baseFeePerGas = 0`.
  - Giao dịch không tốn phí, phù hợp môi trường private.

- **Thiết kế ưu tiên bảo mật**
  - Validator không expose RPC.
  - Toàn bộ truy cập bên ngoài đi qua RPC node duy nhất.

- **Công cụ vận hành**
  - Script khởi tạo mạng một lần.
  - Script quản lý vòng đời node (start, stop, logs, reset).

---

## Cấu trúc thư mục

```text
besu-network/
├── config/                 # Genesis và cấu hình node
├── data/                   # Dữ liệu blockchain (tạo khi chạy)
├── init-network.sh         # Script khởi tạo mạng (chạy 1 lần)
├── manage.sh               # Script quản lý hệ thống
├── docker-compose.yml      # Cấu hình cluster
└── README.md
````

---

## Yêu cầu

* Docker & Docker Compose
* Python 3 (phục vụ xử lý file JSON khi khởi tạo)

---

## Hướng dẫn sử dụng

### 1. Khởi tạo mạng

Chạy **một lần duy nhất** để sinh key, genesis và cấu hình bootnode:

```bash
chmod +x init-network.sh manage.sh
./init-network.sh
```

Script sẽ tự động cấp tiền cho các tài khoản mặc định trong genesis.

---

### 2. Khởi động hệ thống

```bash
./manage.sh start
```

---

### 3. Kiểm tra trạng thái

Sau khoảng 10–20 giây:

```bash
./manage.sh status
```

---

## Thông tin kết nối

| Dịch vụ        | Địa chỉ                                        | Chain ID | Mô tả                                |
| -------------- | ---------------------------------------------- | -------- | ------------------------------------ |
| JSON-RPC       | [http://localhost:8545](http://localhost:8545) | 1337     | Metamask, Web3, Hardhat              |
| Block Explorer | [http://localhost:3001](http://localhost:3001) | —        | Giao diện theo dõi block & giao dịch |

**Lưu ý:**
Các Validator node không mở RPC. Mọi tương tác với blockchain phải đi qua RPC node.

---

## Lệnh quản lý

```bash
./manage.sh logs            # Xem logs toàn hệ thống
./manage.sh logs rpc        # Xem logs riêng RPC node
./manage.sh stop            # Dừng mạng
./manage.sh restart         # Khởi động lại
./manage.sh peers           # Danh sách peer
./manage.sh clean           # Reset dữ liệu blockchain (giữ key)
./manage.sh reset           # Xóa toàn bộ dữ liệu và key
```

---

## Xử lý sự cố

### Lỗi quyền với thư mục `data/`

```bash
sudo chown -R $USER:$USER data/
```
