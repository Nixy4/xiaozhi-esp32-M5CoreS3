windir=/mnt/d/TOOLS/flash_download_tool/temp
# 检查该目录, 如果不存在则创建, 如果存在则清空文件夹中的内容
if [ -d "$windir" ]; then
    rm -rf "$windir"/*
else
    mkdir -p "$windir"
fi
echo "目标目录: $windir"
echo ""

top_cmakelist=./CMakeLists.txt

# 从CMakeLists.txt中提取项目名称
project_name=$(grep -E "^\s*project\s*\(" "$top_cmakelist" | sed -E 's/^\s*project\s*\(\s*([^)]+)\s*\).*/\1/' | tr -d ' ')

flash_args=./build/flash_args

# 从flash_args文件第一行读取flash速率和容量
first_line=$(head -n 1 "$flash_args")

# 提取flash频率 (例如: 80m)
flash_freq=$(echo "$first_line" | grep -o -- '--flash_freq [^ ]*' | awk '{print $2}')

# 提取flash容量 (例如: 16MB)
flash_size=$(echo "$first_line" | grep -o -- '--flash_size [^ ]*' | awk '{print $2}')

printf "%-18s: %s\n" "Project Name" "$project_name"
printf "%-18s: %s\n" "Flash Frequency" "$flash_freq"
printf "%-18s: %s\n" "Flash Size" "$flash_size"

echo ""
echo "Flash Files:"
echo "----------------------------------------"

# 从第二行开始读取各文件的写入地址和文件名称
tail -n +2 "$flash_args" | while IFS=' ' read -r address filename; do
    if [ -n "$address" ] && [ -n "$filename" ]; then
        # 构建源文件路径
        source_file="./build/$filename"
        
        # 提取文件名（不包含后缀）
        basename_no_ext=$(basename "$filename" .bin)
        
        # 判断文件名是否与项目名称相同，如果相同则修改为main.bin
        if [ "$basename_no_ext" = "$project_name" ]; then
            target_filename="main.bin"
        else
            target_filename=$(basename "$filename")
        fi
        
        # 检查源文件是否存在
        if [ -f "$source_file" ]; then
            # 复制文件到目标目录，使用新的文件名（不保留文件夹结构）
            cp "$source_file" "$windir/$target_filename"
            printf "%-12s: %-40s [已复制] -> %s\n" "$address" "$filename" "$target_filename"
        else
            printf "%-12s: %-40s [文件不存在]\n" "$address" "$filename"
        fi
    fi
done


