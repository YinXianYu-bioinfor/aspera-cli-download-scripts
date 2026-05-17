# Aspera CLI Installation & Usage Guide (Windows Practical Notes)

## Prerequisites

- Windows OS
- Ruby >= 3.1 (recommend RubyInstaller WITH Devkit)

---

## 1. Installation Steps

### 1.1 Install Ruby

1. Visit https://rubyinstaller.org/downloads/ to download the latest **Ruby+Devkit**
2. During installation, check **"Add Ruby executables to your PATH"**
3. After installation, restart your terminal and verify:

   ```bash
   ruby --version
   gem --version
   ```

### 1.2 Install aspera-cli gem

```bash
gem install aspera-cli
```

- This automatically installs aspera-cli and all its dependencies (~25 dependent gems)
- The `ascli` command is available immediately after installation

### 1.3 Verify CLI Tool

```bash
ascli -v
```

### 1.4 Install FASP Transfer Engine (ascp)

```bash
ascli config transferd install
```

- Installs the FASP SDK to `~/.aspera/sdk/`
- Components include: `ascp.exe`, `async.exe`, `transferd.exe`, etc.
- After installation, the `ascp` command is **only available in Git Bash** (PATH is not automatically updated for all terminals)

---

## 2. Terminal Selection & Command Execution

### Recommended: Git Bash

The `~` character resolves correctly to `C:\Users\<username>`, allowing direct execution:

```bash
ascp -QT -l 100M -P 33001 -i ~/.aspera/sdk/aspera_bypass_rsa.pem era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz D:/path/to/destination/
```

### PowerShell Usage

`ascp` is not directly recognized in PowerShell; use the full path instead:

```powershell
& "$env:USERPROFILE\.aspera\sdk\ascp.exe" -QT -l 100M -P 33001 -i "$env:USERPROFILE\.aspera\sdk\aspera_bypass_rsa.pem" era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz D:/path/to/destination/
```

Alternatively, add the SDK directory to your user PATH (requires reopening PowerShell):

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\.aspera\sdk", "User")
```

### `ascli` Command

`ascli` works in both PowerShell and Git Bash (registered during gem installation).

---

## 3. Post-Installation File Locations

| Content | Path |
|---------|------|
| Configuration file | `C:/Users/<username>/.aspera/ascli/config.yaml` |
| FASP SDK (incl. ascp.exe) | `C:/Users/<username>/.aspera/sdk` |
| Default RSA private key | `C:/Users/<username>/.aspera/sdk/aspera_bypass_rsa.pem` |
| Default DSA private key | `C:/Users/<username>/.aspera/sdk/aspera_bypass_dsa.pem` |

---

## 4. Verified Versions

| Component | Version |
|-----------|---------|
| Ruby | 4.0.3 |
| aspera-cli (gem) | 4.25.6 |
| FASP SDK (ascp) | 4.4.7.2245 |
| Source version | 4.26.0.pre |

---

## 5. Testing: Downloading FASTQ Data from EBI

EBI (European Bioinformatics Institute) provides public Aspera data download services.

### Method 1: Direct ascp (Recommended, Simplest)

```bash
ascp -QT -l 100M -P 33001 -i ~/.aspera/sdk/aspera_bypass_rsa.pem era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz D:/path/to/destination/
```

**Parameter Reference:**

| Parameter | Meaning |
|-----------|---------|
| `-Q` | Enable fair-share quota (adaptive bandwidth) |
| `-T` | Disable encryption (improves transfer speed) |
| `-l 100M` | Limit maximum transfer rate to 100 Mbps |
| `-P 33001` | EBI Aspera SSH port |
| `-i <key>` | Specify authentication private key |
| `era-fasp@fasp.sra.ebi.ac.uk` | EBI public data user@server |
| Last args | Remote file path + local destination path |

**Batch download multiple files:**

```bash
# Download paired-end files
ascp -QT -l 100M -P 33001 -i ~/.aspera/sdk/aspera_bypass_rsa.pem \
  era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz \
  /vol1/fastq/SRR180/001/SRR18012601/SRR18012601_2.fastq.gz \
  D:/data/
```

### Method 2: Using ascli server download (More Feature-Rich)

```bash
ascli --sdk-folder="~/.aspera/sdk" --progress-bar=yes server download \
  --url="ssh://fasp.sra.ebi.ac.uk:33001" \
  --username=era-fasp \
  --ssh-keys="~/.aspera/sdk/aspera_bypass_rsa.pem" \
  --to-folder="D:/path/to/destination/" \
  --sources=@ts \
  --ts="@json:{\"paths\":[{\"source\":\"/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz\"}]}"
```

**Notes:**
- `--to-folder` must use `=` to bind the value (not a space)
- `--sources=@ts` indicates that transfer sources are specified by the `--ts` parameter
- `@json:` prefix means the following value is JSON-formatted data
- Using `@ts` mode prevents Git Bash from interpreting `/vol1/...` as a Windows local path

### ascli Option Value Prefixes

| Prefix | Meaning | Example |
|--------|---------|---------|
| `@json:` | Inline JSON value | `--ts="@json:{"paths":[...]}"` |
| `@file:` | Read value from file | `--ts="@file:spec.json"` |
| `@ts` | Transfer source specified by another option | `--sources=@ts --ts=...` |

---

## 6. ascli Architecture & Common Commands

### Architecture Overview

ascli uses a plugin architecture where top-level subcommands correspond to different plugins:

| Plugin | Purpose |
|--------|---------|
| `server` | HSTS/SSH FASP transfers (e.g., EBI public data) |
| `node` | Aspera Node API |
| `aoc` | IBM Aspera on Cloud |
| `faspex` | IBM Aspera Faspex |
| `shares` | IBM Aspera Shares |
| `config` | Configuration management, SDK installation |

### Server Plugin Usage

```bash
# Browse remote directory
ascli server files browse /remote/path --url=... --username=... --ssh-keys=...

# Upload files
ascli server upload --url=... --username=... --ssh-keys=... --to-folder=... --sources=...

# Download files
ascli server download --url=... --username=... --ssh-keys=... --to-folder=... --sources=...

# Health check (transfer test)
ascli server health transfer --url=... --username=... --ssh-keys=...
```

### Global Options

| Option | Purpose |
|--------|---------|
| `--log-level=<level>` | Log level: debug, info, warn, error |
| `--log-format=<format>` | Log format: normal, json, detail |
| `--progress-bar=yes` | Show transfer progress bar |
| `--sdk-folder=<path>` | Specify SDK path (ascp directory) |

---

## 7. Troubleshooting

### 7.1 `ascp: command not found` (or PowerShell cannot find it)

- **Cause**: FASP SDK path not added to system PATH
- **Solution**: Use full path `~/.aspera/sdk/ascp.exe`, or configure PATH

### 7.2 `/vol1/...` path interpreted as a Windows local path

- **Issue**: Error `Server aborted session: No such file or directory`
- **Cause**: Git Bash resolves `/vol1/fastq/...` to `D:/software/Git/vol1/fastq/...`
- **Solution**:
  - Use `ascp` directly (paths after `era-fasp@host:` are not intercepted by Bash)
  - Or use `ascli server download --sources=@ts --ts="@json:..."` mode

### 7.3 `--to-folder` reports `missing argument`

- **Cause**: Using a space instead of `=` to separate the option and its value
- **Solution**: Use `--to-folder="D:/path/"` instead of `--to-folder "D:/path/"`

### 7.4 EBI authentication failure

- **Cause**: Wrong private key file (e.g., DSA instead of RSA)
- **Solution**: EBI uses RSA keys — specify `-i ~/.aspera/sdk/aspera_bypass_rsa.pem`

### 7.5 Proxy Environment

If using an HTTP proxy, configure it on the command line:

```bash
ascli --http-proxy=http://proxy:port ...
```

---

## 8. EBI Public Aspera Server Reference

| Parameter | Value |
|-----------|-------|
| Server | fasp.sra.ebi.ac.uk |
| Port | 33001 |
| Username | era-fasp |
| Authentication | RSA key (aspera_bypass_rsa.pem) |
| Encryption | Recommend disabling (`-T`) for speed |
| Typical use | Downloading public FASTQ sequencing data |

Path format: `/vol1/fastq/<SRR_prefix>/<3-digit>/<SRR_ID>/<SRR_ID>_<read_number>.fastq.gz`

Example: `/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz`

---

## 9. Batch Download

### Use Case

When downloading large numbers of FASTQ files from EBI, the batch script eliminates the need for manual command entry.

### Prepare the Path List File (`remote_paths.txt`)

One remote path per line. Paths pasted from EBI exports (including `era-fasp@` prefix) are auto-cleaned by the script:

```
# Comment lines are automatically skipped
/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz
/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_2.fastq.gz

# The following format is also auto-detected and cleaned (no manual editing needed):
# era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/SRR180/001/SRR18012601/SRR18012601_1.fastq.gz
```

### Batch Download Script (`scripts/aspera_batch_download.sh`)

Supports sequential and parallel download modes.

**Basic Usage:**

```bash
cd scripts/

# Sequential (default)
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq

# Parallel (2 concurrent tasks, recommended for testing)
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq -p 2

# Higher concurrency (for ample bandwidth)
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq -p 4
```

**Parameters:**

| Parameter | Meaning |
|-----------|---------|
| `-i <file>` | Path list file (one EBI remote path per line) |
| `-o <dir>` | Download destination directory |
| `-p <num>` | Parallel tasks (default 1=sequential, >=2 for strict parallel) |

**Output Structure:**

```
D:/data/fastq/
├── SRR18012601_1.fastq.gz    # Downloaded files
├── SRR18012601_2.fastq.gz
├── batch_download.log         # Summary log (progress and results)
└── .logs/
    ├── 1_SRR18012601_1.fastq.gz.log   # Detailed per-task logs
    ├── 2_SRR18012601_2.fastq.gz.log
    └── ...
```

**Parallel Mechanism:**
- `-p 2` guarantees at most 2 `ascp` processes running simultaneously
- Per-task logs are isolated and independent
- Automatic success/failure summary after all tasks complete
- Resume support via `-k 1` — re-running skips already-downloaded files

### Extracting Remote Paths

After exporting paths from EBI's CSV/text export, quickly generate a list file:

```bash
# Extract path column from CSV
cut -d',' -f1 sra_paths.csv > remote_paths.txt

# Or organize in Excel and export as plain text
```

---

## 10. Post-Download Renaming

### Use Case

Downloaded files are named `SRRxxxxxx_{1,2}.fastq.gz`. Rename them to readable Sample IDs for downstream analysis.

### Mapping File Format

Two columns, tab-separated (may include a header). Recommended filenames: `sample.txt` or `sample_example.txt`:

```
SampleID	Run
A5.10	SRR20814200
C51.14	SRR20814100
```

- First column = new filename (SampleID), second column = original SRR ID
- The header (any name) is automatically skipped
- Result: `SRR20814200_1.fastq.gz` → `A5.10_1.fq.gz`

### Rename Script (`scripts/aspera_rename.sh`)

Auto-detects the mapping file, no need to specify the path manually.

**Basic Usage:**

```bash
cd scripts/

# Auto-detect mapping file
./aspera_rename.sh -d D:/data/fastq

# Manually specify mapping file
./aspera_rename.sh -d D:/data/fastq -m my_mapping.txt
```

**Parameters:**

| Parameter | Meaning |
|-----------|---------|
| `-d <dir>` | Data directory (where downloaded files are stored) |
| `-m <file>` | Mapping file path (optional, auto-detected by default) |
| `-h` | Show help |

**Mapping File Auto-Detection Order:**
1. `<data_dir>/sample.txt`
2. `<data_dir>/sample_example.txt`
3. `./sample.txt` (current directory)
4. `./sample_example.txt` (current directory)

**Renaming Rules:**

```
SRR20814200_1.fastq.gz  →  A5.10_1.fq.gz
SRR20814200_2.fastq.gz  →  A5.10_2.fq.gz
```

- Original suffix `.fastq.gz` → new suffix `.fq.gz` (more concise)
- Auto-strips Windows line endings (`\r`) and extra whitespace to prevent mismatches
- Skips if the new filename already exists, preventing accidental overwrites

**Output Structure:**

```
D:/data/fastq/
└── .logs/
    └── rename.log          # Rename log (success/missing statistics)
```

---

## 11. Complete Workflow Example

Chain download and renaming into a seamless pipeline:

```bash
# 1. Prepare path list
#    remote_paths.txt contains EBI-exported remote paths

# 2. Batch download (2 concurrent tasks)
cd scripts/
./aspera_batch_download.sh -i ../examples/remote_paths.txt -o D:/data/fastq -p 2

# 3. Prepare mapping file
#    Place sample.txt in D:/data/fastq/ (or the current directory)

# 4. Auto-rename
./aspera_rename.sh -d D:/data/fastq

# 5. Final directory structure
# D:/data/fastq/
# ├── A5.10_1.fq.gz          # Renamed
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

## 12. References

- ascli official documentation: https://ibm.biz/ascli-doc
- RubyGems: https://rubygems.org/gems/aspera-cli
- GitHub source: https://github.com/IBM/aspera-cli
- RubyDoc: https://www.rubydoc.info/gems/aspera-cli
