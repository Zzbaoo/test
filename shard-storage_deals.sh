#!/bin/bash

# 数据库连接信息
DB_USER="your_username"
DB_PASS="your_password"
DB_NAME="droplet_f03151456"

# SQL查询
QUERY="SELECT cdp_piece_cid FROM storage_deals"
SHARD_QUERY="SELECT key FROM shard"
INSERT_QUERY="INSERT INTO shard (key, url, state, lazy) VALUES (?, ?, 0, 0)"

# 临时文件
TMP_CDP_CID="/tmp/cdp_piece_cid.txt"
TMP_SHARD_KEYS="/tmp/shard_keys.txt"

# 导出storage_deals表中的cdp_piece_cid到临时文件
mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "$QUERY" -B -N > "$TMP_CDP_CID"

# 导出shard表中的key到临时文件
mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "$SHARD_QUERY" -B -N > "$TMP_SHARD_KEYS"

# 读取cdp_piece_cid的值
while IFS= read -r cdp_piece_cid; do
    # 检查cdp_piece_cid是否已存在于shard表中
    if ! grep -q "^$cdp_piece_cid$" "$TMP_SHARD_KEYS"; then
        # 插入到shard表中
        mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO shard (key, url, state, lazy) VALUES ('$cdp_piece_cid', 'market://$cdp_piece_cid', 0, 0)"
        echo "Inserted $cdp_piece_cid into shard table."
    else
        echo "$cdp_piece_cid already exists in shard table."
    fi
done < "$TMP_CDP_CID"

# 清理临时文件
rm -f "$TMP_CDP_CID" "$TMP_SHARD_KEYS"
