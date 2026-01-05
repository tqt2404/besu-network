#!/bin/bash

# ==============================================
# Besu Network Management Script
# ==============================================

NETWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
    start)
        echo "Starting Besu network..."
        cd "$NETWORK_DIR"
        docker-compose up -d
        echo "Network started!"
        echo ""
        docker-compose ps
        ;;
    
    stop)
        echo "Stopping Besu network..."
        cd "$NETWORK_DIR"
        docker-compose down
        echo "Network stopped!"
        ;;
    
    restart)
        echo "Restarting Besu network..."
        cd "$NETWORK_DIR"
        docker-compose restart
        echo "Network restarted!"
        ;;
    
    status)
        echo "Network status:"
        cd "$NETWORK_DIR"
        docker-compose ps
        echo ""
        echo "Checking node sync status..."
        for port in 8545 8555 8565 8575; do
            echo ""
            echo "Node on port $port:"
            curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                -H "Content-Type: application/json" \
                http://localhost:$port 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "  Not responding"
        done
        ;;
    
    logs)
        cd "$NETWORK_DIR"
        if [ -z "$2" ]; then
            docker-compose logs -f
        else
            docker-compose logs -f "$2"
        fi
        ;;
    
    clean)
        echo "WARNING: This will delete all blockchain data!"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            cd "$NETWORK_DIR"
            docker-compose down -v
            rm -rf "$NETWORK_DIR"/data/*/database
            rm -rf "$NETWORK_DIR"/data/*/caches
            rm -rf "$NETWORK_DIR"/data/*/DATABASE_METADATA.json
            echo "Data cleaned!"
        else
            echo "Cancelled."
        fi
        ;;
    
    reset)
        echo "WARNING: This will delete ALL data including keys!"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            cd "$NETWORK_DIR"
            docker-compose down -v
            rm -rf "$NETWORK_DIR"/data/*
            echo "Complete reset done! Run ./init-network.sh to reinitialize."
        else
            echo "Cancelled."
        fi
        ;;
    
    peers)
        echo "Checking peer connections..."
        for port in 8545 8555 8565 8575; do
            echo ""
            echo "Node on port $port:"
            curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
                -H "Content-Type: application/json" \
                http://localhost:$port 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    peers = data.get('result', [])
    print(f'  Connected peers: {len(peers)}')
    for p in peers:
        print(f'    - {p.get(\"name\", \"unknown\")}')
except:
    print('  Not responding')
" 2>/dev/null || echo "  Not responding"
        done
        ;;
    
    validators)
        echo "Checking QBFT validators..."
        curl -s -X POST --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
            -H "Content-Type: application/json" \
            http://localhost:8545 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Not responding"
        ;;
    
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|clean|reset|peers|validators}"
        echo ""
        echo "Commands:"
        echo "  start      - Start all containers"
        echo "  stop       - Stop all containers"
        echo "  restart    - Restart all containers"
        echo "  status     - Show container status and block numbers"
        echo "  logs [svc] - Show logs (optionally for specific service)"
        echo "  clean      - Remove blockchain data (keep keys)"
        echo "  reset      - Remove ALL data including keys"
        echo "  peers      - Show peer connections"
        echo "  validators - Show current validators"
        exit 1
        ;;
esac
