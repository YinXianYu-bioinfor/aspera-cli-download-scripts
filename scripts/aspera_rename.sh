#!/bin/bash
# Aspera 下载后重命名脚本：将 SRR_ID 批量映射为 SampleID
# 注意：本脚本仅适用于 Windows Git Bash，不支持 PowerShell/CMD/Linux/macOS
# 用法：./aspera_rename.sh -d <数据目录> [-m <映射文件>]

# ========== 帮助信息 ==========
show_help() {
  cat << HELP
用法: $(basename "$0") -d <数据目录> [-m <映射文件>]

【仅适用于 Windows Git Bash，不支持 PowerShell/CMD/Linux/macOS】

将下载的 SRRxxx_1.fastq.gz / SRRxxx_2.fastq.gz 批量重命名为 SampleID_1.fq.gz / SampleID_2.fq.gz。

必选参数:
  -d <目录>   数据文件所在目录（即下载文件存放目录）

可选参数:
  -m <文件>   映射文件路径（默认自动搜索，顺序如下）
  -h          显示此帮助信息

映射文件自动搜索顺序:
  1. <数据目录>/sample.txt
  2. <数据目录>/sample_example.txt
  3. 当前目录下的 sample.txt
  4. 当前目录下的 sample_example.txt

映射文件格式（两列，制表符分隔，可含表头）:
  SampleID\tSRR_ID
  Sample1\tSRR1234567
  Sample2\tSRR1234568

重命名规则:
  SRR1234567_1.fastq.gz  →  Sample1_1.fq.gz
  SRR1234567_2.fastq.gz  →  Sample1_2.fq.gz

示例:
  $(basename "$0") -d ./downloads
  $(basename "$0") -d ./downloads -m my_mapping.txt
HELP
}

# ========== 自动检测映射文件 ==========
find_mapping_file() {
  local data_dir="$1"
  local candidates=(
    "${data_dir}/sample.txt"
    "${data_dir}/sample_example.txt"
    "./sample.txt"
    "./sample_example.txt"
  )
  for f in "${candidates[@]}"; do
    [ -f "$f" ] && { echo "$f"; return 0; }
  done
  return 1
}

# ========== 参数解析 ==========
DATA_DIR=""
MAP_FILE=""

while getopts ":d:m:h" opt; do
  case $opt in
    d) DATA_DIR="$OPTARG" ;;
    m) MAP_FILE="$OPTARG" ;;
    h) show_help; exit 0 ;;
    \?) echo "错误：无效选项 -$OPTARG" >&2; exit 1 ;;
    :)  echo "错误：选项 -$OPTARG 缺少参数" >&2; exit 1 ;;
  esac
done

# ========== 前置检查 ==========
if [ -z "$DATA_DIR" ]; then
  echo "错误：未指定数据目录（-d）" >&2
  show_help >&2; exit 1
fi
if [ ! -d "$DATA_DIR" ]; then
  echo "错误：数据目录 $DATA_DIR 不存在" >&2; exit 1
fi

# 映射文件：用户指定优先，否则自动检测
if [ -n "$MAP_FILE" ]; then
  if [ ! -f "$MAP_FILE" ]; then
    echo "错误：映射文件 $MAP_FILE 不存在" >&2; exit 1
  fi
else
  MAP_FILE=$(find_mapping_file "$DATA_DIR")
  if [ -z "$MAP_FILE" ]; then
    echo "未检测到映射文件（搜索 sample.txt / sample_example.txt），跳过重命名"
    exit 0
  fi
  echo "自动检测到映射文件: ${MAP_FILE}"
fi

# ========== 初始化日志 ==========
LOG_DIR="${DATA_DIR}/.logs"
mkdir -p "$LOG_DIR"
RENAME_LOG="${LOG_DIR}/rename.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ======== Aspera 重命名 ========" | tee "$RENAME_LOG"
echo "数据目录: ${DATA_DIR}" | tee -a "$RENAME_LOG"
echo "映射文件: ${MAP_FILE}" | tee -a "$RENAME_LOG"

# ========== 核心重命名逻辑 ==========
RN_SUCCESS=0
RN_MISSING=0

while IFS=$'\t' read -r sample_id srr_id; do
  # 跳过表头和空行
  [[ "${sample_id}" == "SampleID" || -z "${sample_id}" || -z "${srr_id}" ]] && continue

  sample_id=$(echo "${sample_id}" | tr -d '\r' | xargs)
  srr_id=$(echo "${srr_id}" | tr -d '\r' | xargs)

  for read_num in 1 2; do
    old_file="${DATA_DIR}/${srr_id}_${read_num}.fastq.gz"
    new_file="${DATA_DIR}/${sample_id}_${read_num}.fq.gz"

    if [ ! -f "${old_file}" ]; then
      echo "原文件不存在: ${old_file}" >> "${RENAME_LOG}"
      RN_MISSING=$((RN_MISSING + 1))
      continue
    fi
    if [ -f "${new_file}" ]; then
      echo "新文件已存在,跳过: ${new_file}" >> "${RENAME_LOG}"
      continue
    fi

    mv "${old_file}" "${new_file}" >> "${RENAME_LOG}" 2>&1
    echo "成功: ${old_file} → ${new_file}" >> "${RENAME_LOG}"
    RN_SUCCESS=$((RN_SUCCESS + 1))
  done
done < "${MAP_FILE}"

# ========== 汇总 ==========
echo "----------------------------------------" | tee -a "$RENAME_LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 重命名完成" | tee -a "$RENAME_LOG"
echo "  成功: ${RN_SUCCESS} | 缺失: ${RN_MISSING}" | tee -a "$RENAME_LOG"
echo "  日志: ${RENAME_LOG}"

[ "$RN_MISSING" -eq 0 ] && echo "🎉 全部完成" || echo "⚠️  部分文件缺失（${RN_MISSING} 个），请检查日志"
