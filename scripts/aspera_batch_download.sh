#!/bin/bash
# Aspera 批量下载脚本（Windows Git Bash 适用，支持严格并行）
# 用法：
#   ./aspera_batch_download.sh -i <路径列表文件> -o <目标目录> [-p <并行数>]
#
# 示例：
#   ./aspera_batch_download.sh -i remote_paths.txt -o D:/data/fastq
#   ./aspera_batch_download.sh -i remote_paths.txt -o D:/data/fastq -p 2
#   ./aspera_batch_download.sh -i remote_paths.txt -o D:/data/fastq -p 4

# ========== 帮助信息 ==========
show_help() {
  cat << HELP
用法: $(basename "$0") -i <路径列表文件> -o <目标目录> [-p <并行数>]

批量下载 EBI（或兼容 Aspera 服务器）的 FASTQ 文件。

必选参数:
  -i <文件>   路径列表文件，每行一个远程路径（纯路径，无需 "era-fasp@" 前缀）
  -o <目录>   下载文件保存目录

可选参数:
  -p <数字>   并行下载任务数（默认 1=顺序，2=两个同时下载，依此类推）
  -h          显示此帮助信息

路径列表文件格式:
  # 注释行以 # 开头，会被跳过
  /vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz
  /vol1/fastq/SRR180/001/SRR18012601/SRR18012601_2.fastq.gz
  （从 EBI 导出的路径可直接粘贴，无需额外处理）

示例:
  # 顺序下载
  $(basename "$0") -i remote_paths.txt -o D:/data/fastq

  # 2 个任务并行下载（推荐测试用）
  $(basename "$0") -i remote_paths.txt -o D:/data/fastq -p 2

  # 4 个任务并行（带宽充裕时）
  $(basename "$0") -i remote_paths.txt -o D:/data/fastq -p 4

输出结构:
  <目标目录>/
  ├── SRR18012601_1.fastq.gz       # 下载的文件
  ├── batch_download.log           # 汇总日志
  └── .logs/
      └── 1_SRR18012601_1.fastq.gz.log  # 单任务详细日志

注意事项:
  1. 默认连接 EBI 公开服务器（fasp.sra.ebi.ac.uk:33001），用户 era-fasp
  2. 如需连接其他 Aspera 服务器，请修改脚本中 REMOTE_USER/ASCP_PORT 等配置
  3. 启用断点续传（-k 1），中断后重跑不会重复下载已完成文件
  4. 每个任务独立日志，方便排查失败原因
  5. 脚本仅在 Git Bash 中运行，不支持 PowerShell/CMD
HELP
}
# ===========================

# ========== 配置区 ==========
ASCP_BIN="$HOME/.aspera/sdk/ascp.exe"
ASCP_KEY="$HOME/.aspera/sdk/aspera_bypass_rsa.pem"
REMOTE_USER="era-fasp@fasp.sra.ebi.ac.uk"
ASCP_PORT="33001"
ASCP_OPTS="-QT -l 100M -P ${ASCP_PORT} -k 1"
# ===========================

# ========== 参数解析 ==========
INPUT_FILE=""
OUTPUT_DIR=""
MAX_PARALLEL=1

while getopts ":i:o:p:h" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    p) MAX_PARALLEL="$OPTARG" ;;
    h) show_help; exit 0 ;;
    \?) echo "错误：无效选项 -$OPTARG" >&2; echo "使用 -h 查看帮助" >&2; exit 1 ;;
    :)  echo "错误：选项 -$OPTARG 缺少参数" >&2; echo "使用 -h 查看帮助" >&2; exit 1 ;;
  esac
done

if [ -z "$INPUT_FILE" ]; then
  echo "用法: $(basename "$0") -i <路径列表文件> -o <目标目录> [-p <并行数>]"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "错误：路径列表文件 $INPUT_FILE 不存在"
  exit 1
fi

# 默认目标目录为当前目录
[ -z "$OUTPUT_DIR" ] && OUTPUT_DIR="."

mkdir -p "$OUTPUT_DIR"
LOG_DIR="${OUTPUT_DIR}/.logs"
mkdir -p "$LOG_DIR"
SUMMARY_LOG="${OUTPUT_DIR}/batch_download.log"

# ========== 读取路径列表（过滤空行和注释） ==========
mapfile -t ALL_PATHS < <(grep -vE '^\s*$|^\s*#' "$INPUT_FILE")
TOTAL=${#ALL_PATHS[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo "错误：路径列表文件中没有有效的下载路径"
  exit 1
fi

# ========== 自动清理路径前缀 ==========
# 用户可能粘贴了含 "era-fasp@host:port:" 前缀的路径，自动剥离
CLEANED=0
for i in "${!ALL_PATHS[@]}"; do
  if [[ "${ALL_PATHS[$i]}" =~ ^[^:]+:(.*) ]]; then
    ALL_PATHS[$i]="${BASH_REMATCH[1]}"
    CLEANED=$((CLEANED + 1))
  fi
done
[ "$CLEANED" -gt 0 ] && echo "检测到 ${CLEANED} 条路径含 host: 前缀，已自动清理"

# ========== 单个文件下载函数 ==========
# 参数：$1=序号 $2=远程路径
# 返回值：0=成功，非0=失败
download_one() {
  local idx="$1"
  local remote_path="$2"
  local file_name
  file_name=$(basename "$remote_path")
  local file_log="${LOG_DIR}/${idx}_${file_name}.log"

  # 写入文件级日志
  {
    echo "========================================"
    echo "任务: [$idx/$TOTAL]"
    echo "文件: ${remote_path}"
    echo "开始: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "命令: ${ASCP_BIN} ${ASCP_OPTS} -i ${ASCP_KEY} ${REMOTE_USER}:${remote_path} ${OUTPUT_DIR}"
    echo "========================================"
  } > "$file_log"

  # 执行下载（输出同时写入文件日志和终端）
  if "$ASCP_BIN" $ASCP_OPTS -i "$ASCP_KEY" "${REMOTE_USER}:${remote_path}" "$OUTPUT_DIR" >> "$file_log" 2>&1; then
    echo "[$(date '+%H:%M:%S')] [成功] [$idx/$TOTAL] ${file_name}" | tee -a "$SUMMARY_LOG"
    return 0
  else
    echo "[$(date '+%H:%M:%S')] [失败] [$idx/$TOTAL] ${file_name} (日志: ${file_log})" | tee -a "$SUMMARY_LOG"
    return 1
  fi
}

# ========== 主流程 ==========
echo "" > "$SUMMARY_LOG"
echo "$(date '+%Y-%m-%d %H:%M:%S') ======== Aspera 批量下载 ========" | tee -a "$SUMMARY_LOG"
echo "路径列表: ${INPUT_FILE}" | tee -a "$SUMMARY_LOG"
echo "目标目录: ${OUTPUT_DIR}" | tee -a "$SUMMARY_LOG"
echo "文件总数: ${TOTAL}" | tee -a "$SUMMARY_LOG"

SUCCESS=0
FAIL=0

if [ "$MAX_PARALLEL" -le 1 ]; then
  # ===== 顺序模式 =====
  echo "下载模式: 顺序" | tee -a "$SUMMARY_LOG"
  echo "----------------------------------------" | tee -a "$SUMMARY_LOG"

  for i in "${!ALL_PATHS[@]}"; do
    idx=$((i + 1))
    if download_one "$idx" "${ALL_PATHS[$i]}"; then
      SUCCESS=$((SUCCESS + 1))
    else
      FAIL=$((FAIL + 1))
    fi
  done
else
  # ===== 并行模式 =====
  echo "下载模式: 并行 (并发数: ${MAX_PARALLEL})" | tee -a "$SUMMARY_LOG"
  echo "----------------------------------------" | tee -a "$SUMMARY_LOG"

  # 用临时目录追踪每个任务的完成状态
  STATUS_DIR="${OUTPUT_DIR}/.task_status"
  rm -rf "$STATUS_DIR" 2>/dev/null
  mkdir -p "$STATUS_DIR"

  running=0
  for i in "${!ALL_PATHS[@]}"; do
    idx=$((i + 1))

    # 启动后台下载任务
    (
      if download_one "$idx" "${ALL_PATHS[$i]}"; then
        echo "success" > "${STATUS_DIR}/${idx}"
      else
        echo "failed" > "${STATUS_DIR}/${idx}"
      fi
    ) &

    running=$((running + 1))

    # 达到最大并行数时，等待任意一个任务完成
    if [ "$running" -ge "$MAX_PARALLEL" ]; then
      wait -n
      running=$((running - 1))
    fi
  done

  # 等待所有剩余任务完成
  wait

  # 汇总并行模式的结果
  for i in $(seq 1 $TOTAL); do
    if [ -f "${STATUS_DIR}/${i}" ]; then
      if [ "$(cat "${STATUS_DIR}/${i}")" = "success" ]; then
        SUCCESS=$((SUCCESS + 1))
      else
        FAIL=$((FAIL + 1))
      fi
    fi
  done

  rm -rf "$STATUS_DIR"
fi

# ========== 最终汇总 ==========
echo "----------------------------------------" | tee -a "$SUMMARY_LOG"
echo "$(date '+%Y-%m-%d %H:%M:%S') 下载完成：" | tee -a "$SUMMARY_LOG"
echo "  总计: ${TOTAL} | 成功: ${SUCCESS} | 失败: ${FAIL}" | tee -a "$SUMMARY_LOG"
echo "  详细日志: ${SUMMARY_LOG}" | tee -a "$SUMMARY_LOG"
echo "  任务日志: ${LOG_DIR}/" | tee -a "$SUMMARY_LOG"

# 如有失败，返回非零退出码
[ "$FAIL" -eq 0 ]
