# Aspera CLI Download Scripts

A collection of shell scripts and documentation for downloading FASTQ files from EBI (European Bioinformatics Institute) using IBM Aspera CLI, optimized for Windows Git Bash environment.

## Features

- **Batch download**: Download multiple FASTQ files from EBI with sequential or parallel modes
- **Auto-retry & resume**: Supports断点续传 (resume interrupted transfers) via `-k 1`
- **Smart renaming**: Map SRR IDs to human-readable Sample IDs after download
- **Parallel support**: Strict parallelism control (e.g., `-p 2` for 2 concurrent downloads)
- **Detailed logging**: Per-task logs + summary log for easy troubleshooting
- **Path auto-cleaning**: Automatically strips `era-fasp@host:` prefixes from input paths

## Project Structure

```
├── scripts/
│   ├── aspera_batch_download.sh   # Batch download script
│   └── aspera_rename.sh           # SRR-to-SampleID renaming script
├── examples/
│   ├── remote_paths.txt           # Example remote path list
│   └── sample.txt                 # Example SampleID-to-SRR mapping
├── docs/
│   ├── Aspera_CLI_安装与使用指南.md        # Chinese guide
│   └── Aspera_CLI_Installation_and_Usage_Guide.md  # English guide
├── .gitignore
└── README.md
```

## Quick Start

### Prerequisites

- **Windows** with **Git Bash**
- **Aspera CLI** installed (`gem install aspera-cli`)
- **FASP SDK** installed (`ascli config transferd install`)

See the [English guide](docs/Aspera_CLI_Installation_and_Usage_Guide.md) or [Chinese guide](docs/Aspera_CLI_安装与使用指南.md) for detailed installation steps.

### 1. Batch Download

```bash
cd scripts/
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o /path/to/output -p 2
```

### 2. Rename SRR to SampleID

```bash
# Place sample.txt in the output directory first, then:
./aspera_rename.sh -d /path/to/output
```

## Important Notes

- These scripts are designed for **EBI public data** (fasp.sra.ebi.ac.uk:33001, user era-fasp)
- **Platform requirement**: All scripts (`*.sh`) run **only in Windows Git Bash** — not compatible with PowerShell, CMD, Linux, or macOS
- Batch download supports automatic resume — re-running will skip already-downloaded files
- For other Aspera servers, modify `REMOTE_USER` and `ASCP_PORT` in the script

## License

This project is provided as-is for academic and research use.

---

# Aspera CLI 下载脚本

用于从 EBI（欧洲生物信息学研究所）使用 IBM Aspera CLI 批量下载 FASTQ 文件的 Shell 脚本集合，针对 Windows Git Bash 环境优化。

## 功能特性

- **批量下载**：支持顺序和并行模式下载 EBI FASTQ 文件
- **断点续传**：通过 `-k 1` 参数支持中断后自动跳过已完成文件
- **智能重命名**：将 SRR 编号映射为可读的 SampleID
- **并行控制**：严格限制并发数（如 `-p 2` 表示最多 2 个同时下载）
- **详细日志**：每个任务独立日志 + 汇总日志，方便排查
- **路径自动清理**：自动剥离输入路径中的 `era-fasp@host:` 前缀

## 项目结构

```
├── scripts/
│   ├── aspera_batch_download.sh   # 批量下载脚本
│   └── aspera_rename.sh           # SRR 到 SampleID 重命名脚本
├── examples/
│   ├── remote_paths.txt           # 远程路径列表示例
│   └── sample.txt                 # SampleID 到 SRR 映射表示例
├── docs/
│   ├── Aspera_CLI_安装与使用指南.md        # 中文指南
│   └── Aspera_CLI_Installation_and_Usage_Guide.md  # 英文指南
├── .gitignore
└── README.md
```

## 快速开始

### 环境要求

- **Windows** 系统 + **Git Bash**
- 已安装 **Aspera CLI**（`gem install aspera-cli`）
- 已安装 **FASP SDK**（`ascli config transferd install`）

详细安装步骤请参阅[中文指南](docs/Aspera_CLI_安装与使用指南.md)或[英文指南](docs/Aspera_CLI_Installation_and_Usage_Guide.md)。

### 1. 批量下载

```bash
cd scripts/
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o /path/to/output -p 2
```

### 2. 重命名 SRR 为 SampleID

```bash
# 先将 sample.txt 放入输出目录，然后：
./aspera_rename.sh -d /path/to/output
```

## 重要说明

- 这些脚本针对 **EBI 公开数据**设计（fasp.sra.ebi.ac.uk:33001，用户 era-fasp）
- **平台限制**：所有脚本（`.sh`）**仅适用于 Windows Git Bash**，不支持 PowerShell、CMD、Linux 或 macOS
- 批量下载支持断点续传——重新运行会自动跳过已下载的文件
- 如需连接其他 Aspera 服务器，修改脚本中的 `REMOTE_USER` 和 `ASCP_PORT` 即可

## 许可

本项目仅供学术和研究使用，按现状提供。
