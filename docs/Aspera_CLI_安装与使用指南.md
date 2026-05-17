# Aspera CLI 安装与使用指南（Windows 实操总结）

## 环境要求
- Windows 系统
- Ruby ≥ 3.1（推荐 RubyInstaller WITH Devkit）

---

## 一、安装步骤

### 1. 安装 Ruby
1. 访问 https://rubyinstaller.org/downloads/ 下载 **Ruby+Devkit** 最新版本
2. 安装时勾选 **"Add Ruby executables to your PATH"**
3. 安装完成后重启终端，验证安装：
   ```bash
   ruby --version
   gem --version
   ```

### 2. 安装 aspera-cli gem
```bash
gem install aspera-cli
```
- 该命令会自动安装 aspera-cli 及其所有依赖（约 25 个依赖 gem）
- 安装完成后 ascli 命令即可使用

### 3. 验证 CLI 工具
```bash
ascli -v
```

### 4. 安装 FASP 传输引擎（ascp）
```bash
ascli config transferd install
```
- 该命令会将 FASP SDK 安装到 `~/.aspera/sdk/` 目录
- 包含：`ascp.exe`, `async.exe`, `transferd.exe` 等组件
- 安装后 `ascp` 命令仅在 **Git Bash** 中可用（因 PATH 未自动添加）

---

## 二、终端选择与命令执行

### 推荐使用 Git Bash
命令中的 `~` 自动解析为 `C:\Users\<用户名>`，可直接运行：

```bash
ascp -QT -l 100M -P 33001 -i ~/.aspera/sdk/aspera_bypass_rsa.pem era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz D:/path/to/destination/
```

### PowerShell 中使用
`ascp` 在 PowerShell 中不能直接识别，需使用完整路径：

```powershell
& "$env:USERPROFILE\.aspera\sdk\ascp.exe" -QT -l 100M -P 33001 -i "$env:USERPROFILE\.aspera\sdk\aspera_bypass_rsa.pem" era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz D:/path/to/destination/
```

或将 SDK 目录添加到用户 PATH（需重新打开 PowerShell）：
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\.aspera\sdk", "User")
```

### `ascli` 命令通用
`ascli` 在 PowerShell 和 Git Bash 中均可直接使用（gem 安装时已注册）。

---

## 三、安装后文件位置

| 内容 | 路径 |
|------|------|
| 配置文件 | `C:/Users/<用户名>/.aspera/ascli/config.yaml` |
| FASP SDK（含 ascp.exe） | `C:/Users/<用户名>/.aspera/sdk` |
| 默认 RSA 私钥 | `C:/Users/<用户名>/.aspera/sdk/aspera_bypass_rsa.pem` |
| 默认 DSA 私钥 | `C:/Users/<用户名>/.aspera/sdk/aspera_bypass_dsa.pem` |

---

## 四、实操验证版本

| 组件 | 版本 |
|------|------|
| Ruby | 4.0.3 |
| aspera-cli (gem) | 4.25.6 |
| FASP SDK (ascp) | 4.4.7.2245 |
| 源码版本 | 4.26.0.pre |

---

## 五、测试安装：下载 FASTQ 数据（以 EBI 为例）

EBI（欧洲生物信息学研究所）提供公开的 Aspera 数据下载服务。

### 方法一：直接使用 ascp（推荐，最简单）

```bash
ascp -QT -l 100M -P 33001 -i ~/.aspera/sdk/aspera_bypass_rsa.pem era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz D:/path/to/destination/
```

**参数说明：**

| 参数 | 含义 |
|------|------|
| `-Q` | 启用公平共享配额（自适应带宽） |
| `-T` | 关闭加密（提升传输速度） |
| `-l 100M` | 限制最大传输速率 100 Mbps |
| `-P 33001` | EBI 的 Aspera SSH 端口 |
| `-i <key>` | 指定认证私钥文件 |
| `era-fasp@fasp.sra.ebi.ac.uk` | EBI 公开数据专用用户@服务器 |
| 最后参数 | 远程文件路径 + 本地目标路径 |

**批量下载多个文件：**

```bash
# 下载配对双端文件
ascp -QT -l 100M -P 33001 -i ~/.aspera/sdk/aspera_bypass_rsa.pem \
  era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz \
  /vol1/fastq/SRR180/001/SRR18012601/SRR18012601_2.fastq.gz \
  D:/data/
```

### 方法二：使用 ascli server download（功能更全）

```bash
ascli --sdk-folder="~/.aspera/sdk" --progress-bar=yes server download \
  --url="ssh://fasp.sra.ebi.ac.uk:33001" \
  --username=era-fasp \
  --ssh-keys="~/.aspera/sdk/aspera_bypass_rsa.pem" \
  --to-folder="D:/path/to/destination/" \
  --sources=@ts \
  --ts="@json:{\"paths\":[{\"source\":\"/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz\"}]}"
```

**说明：**
- `--to-folder` 必须用 `=` 连接值，不能空格
- `--sources=@ts` 表示传输源由 `--ts` 参数指定
- `@json:` 前缀表示后面是 JSON 格式数据
- 使用 `@ts` 模式可避免 Git Bash 将 `/vol1/...` 解析为 Windows 本地路径的问题

### ascli 选项值前缀约定

| 前缀 | 含义 | 示例 |
|------|------|------|
| `@json:` | 直接提供 JSON 值 | `--ts="@json:{"paths":[...]}"` |
| `@file:` | 从文件读取值 | `--ts="@file:spec.json"` |
| `@ts` | 传输源由另一选项指定 | `--sources=@ts --ts=...` |

---

## 六、ascli 架构与常用命令

### 架构概览
ascli 采用插件架构，顶级子命令对应不同插件：

| 插件 | 用途 |
|------|------|
| `server` | HSTS/SSH FASP 传输（如 EBI 公开数据） |
| `node` | Aspera Node API |
| `aoc` | IBM Aspera on Cloud |
| `faspex` | IBM Aspera Faspex |
| `shares` | IBM Aspera Shares |
| `config` | 配置管理，SDK 安装 |

### Server 插件用法
```bash
# 浏览远程目录
ascli server files browse /remote/path --url=... --username=... --ssh-keys=...

# 上传文件
ascli server upload --url=... --username=... --ssh-keys=... --to-folder=... --sources=...

# 下载文件
ascli server download --url=... --username=... --ssh-keys=... --to-folder=... --sources=...

# 健康检查（传输测试）
ascli server health transfer --url=... --username=... --ssh-keys=...
```

### 全局选项
| 选项 | 作用 |
|------|------|
| `--log-level=<level>` | 日志级别：debug, info, warn, error |
| `--log-format=<format>` | 日志格式：normal, json, detail |
| `--progress-bar=yes` | 显示传输进度条 |
| `--sdk-folder=<path>` | 指定 SDK 路径（ascp 所在目录） |

---

## 七、常见问题与解决方案

### 1. `ascp: command not found`（或 PowerShell 无法识别）
- **原因**：FASP SDK 路径未添加到系统 PATH
- **解决**：使用完整路径 `~/.aspera/sdk/ascp.exe`，或配置 PATH

### 2. `/vol1/...` 路径被解析为 Windows 本地路径
- **现象**：错误 `Server aborted session: No such file or directory`
- **原因**：Git Bash 将 `/vol1/fastq/...` 解释为 `D:/software/Git/vol1/fastq/...`
- **解决**：
  - 使用 `ascp` 直接命令（路径在 `era-fasp@host:` 之后，不会被 Bash 拦截）
  - 或使用 `ascli server download --sources=@ts --ts="@json:..."` 模式

### 3. `--to-folder` 报错 `missing argument`
- **原因**：使用空格而非 `=` 分隔选项值
- **解决**：使用 `--to-folder="D:/path/"` 而非 `--to-folder "D:/path/"`

### 4. EBI 认证失败
- **原因**：使用了错误的私钥文件（如 DSA 而非 RSA）
- **解决**：EBI 使用 RSA 密钥，指定 `-i ~/.aspera/sdk/aspera_bypass_rsa.pem`

### 5. 代理环境
如使用 HTTP 代理，可在配置文件中设置：
```bash
ascli --http-proxy=http://proxy:port ...
```

---

## 八、EBI 公开 Aspera 服务器说明

| 参数 | 值 |
|------|-----|
| 服务器 | fasp.sra.ebi.ac.uk |
| 端口 | 33001 |
| 用户名 | era-fasp |
| 认证方式 | RSA 密钥（aspera_bypass_rsa.pem） |
| 加密 | 建议关闭（`-T`）以提升速度 |
| 典型用途 | 下载公开 FASTQ 测序数据 |

路径格式：`/vol1/fastq/<SRR前缀>/<3位数字>/<SRR编号>/<SRR编号>_<端号>.fastq.gz`

示例：`/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz`

---

## 九、批量下载

### 适用场景
需从 EBI 下载大量 FASTQ 文件时，使用批量脚本可避免手动逐条输入命令。

### 准备路径列表文件（remote_paths.txt）
每行一个远程路径。可直接粘贴从 EBI 导出的路径（含 `era-fasp@` 前缀的也会被自动清理）：
```
# 注释行会被自动跳过
/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz
/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_2.fastq.gz

# 以下格式也会被脚本自动识别并剥离前缀（无需手动修改）：
# era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz
```

### 批量下载脚本（scripts/aspera_batch_download.sh）
位于 `scripts/aspera_batch_download.sh`，支持顺序和并行两种模式。

**基本用法：**
```bash
cd scripts/

# 顺序下载（默认）
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq

# 并行下载（2个并发任务，测试推荐）
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq -p 2

# 更多并发（适合带宽充裕的环境）
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq -p 4
```

**参数说明：**

| 参数 | 含义 |
|------|------|
| `-i <文件>` | 路径列表文件（每行一个 EBI 远程路径） |
| `-o <目录>` | 下载保存目录 |
| `-p <数字>` | 并行下载数（默认 1=顺序，≥2 为严格并行） |

**输出结构：**
```
D:/data/fastq/
├── SRR18012601_1.fastq.gz    # 下载的文件
├── SRR18012601_2.fastq.gz
├── batch_download.log         # 汇总日志（任务进度与结果）
└── .logs/
    ├── 1_SRR18012601_1.fastq.gz.log   # 单个任务的详细日志
    ├── 2_SRR18012601_2.fastq.gz.log
    └── ...
```

**并行机制说明：**
- `-p 2` 保证任何时候最多有 2 个 `ascp` 进程同时运行
- 每个任务的日志独立记录，互不干扰
- 所有任务完成后自动汇总成功/失败统计
- 启用 `-k 1`（断点续传），中断后重跑自动跳过已完成的文件

### 路径列表获取技巧
从 EBI 的 CSV/文本导出中提取路径后，可用以下方式快速生成列表文件：

```bash
# 从 CSV 中提取路径列，直接存入列表文件
cut -d',' -f1 sra_paths.csv > remote_paths.txt

# 或者在 Excel 中整理后，导出为纯文本
```

---

## 十、下载后重命名

### 适用场景
批量下载得到的文件名为 `SRRxxxxxx_{1,2}.fastq.gz`，需映射为可读的样本名（SampleID）以便后续分析。

### 映射文件格式
两列、制表符分隔（可含表头），推荐文件名 `sample.txt` 或 `sample_example.txt`：
```
SampleID	Run
A5.10	SRR20814200
C51.14	SRR20814100
```
- 第一列为新文件名（SampleID），第二列为原 SRR 编号
- 表头可为 `SampleID` / `Run` 或任意名称，脚本会自动跳过首行
- 最终重命名结果：`SRR20814200_1.fastq.gz` → `A5.10_1.fq.gz`

### 重命名脚本（scripts/aspera_rename.sh）
位于 `scripts/aspera_rename.sh`，自动检测映射文件，无需手动指定路径。

**基本用法：**
```bash
cd scripts/

# 自动检测映射文件（搜索顺序见下方）
./aspera_rename.sh -d D:/data/fastq

# 手动指定映射文件
./aspera_rename.sh -d D:/data/fastq -m my_mapping.txt
```

**参数说明：**

| 参数 | 含义 |
|------|------|
| `-d <目录>` | 数据文件所在目录（即下载文件存放目录） |
| `-m <文件>` | 映射文件路径（可选，默认自动搜索） |
| `-h` | 显示帮助信息 |

**映射文件自动搜索顺序：**
1. `<数据目录>/sample.txt`
2. `<数据目录>/sample_example.txt`
3. 当前目录下的 `sample.txt`
4. 当前目录下的 `sample_example.txt`

**重命名规则：**
```
SRR20814200_1.fastq.gz  →  A5.10_1.fq.gz
SRR20814200_2.fastq.gz  →  A5.10_2.fq.gz
```
- 原后缀 `.fastq.gz` → 新后缀 `.fq.gz`（更简洁）
- 自动清理 Windows 换行符（`\r`）和多余空格，避免匹配失败
- 若新文件名已存在则跳过，防止覆盖

**输出结构：**
```
D:/data/fastq/
└── .logs/
    └── rename.log          # 重命名日志（成功/缺失统计）
```

---

## 十一、完整工作流程示例

将下载与重命名串联使用，一条命令完成数据获取与整理：

```bash
# 1. 准备路径列表
#    remote_paths.txt 包含 EBI 导出的远程路径

# 2. 批量下载（2 个并发任务）
cd scripts/
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq -p 2

# 3. 准备映射文件
#    将 sample.txt 放入 D:/data/fastq/（或当前目录）

# 4. 自动重命名
./aspera_rename.sh -d D:/data/fastq

# 5. 最终目录结构
# D:/data/fastq/
# ├── A5.10_1.fq.gz          # 重命名后
# ├── A5.10_2.fq.gz
# ├── C51.14_1.fq.gz
# ├── C51.14_2.fq.gz
# ├── batch_download.log
# └── .logs/
#     ├── 1_SRR20814200_1.fastq.gz.log
#     ├── 2_SRR20814200_2.fastq.gz.log
#     └── rename.log
```

---

## 十二、参考资料

- ascli 官方文档：https://ibm.biz/ascli-doc
- RubyGems：https://rubygems.org/gems/aspera-cli
- GitHub 源码：https://github.com/IBM/aspera-cli
- RubyDoc：https://www.rubydoc.info/gems/aspera-cli
