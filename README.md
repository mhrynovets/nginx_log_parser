# Nginx Log Parser & Git Sync Bot

A lightweight Dockerized tool that parses Nginx logs into indexed CSV format and automatically syncs them to a Git repository via SSH.

## Features

* **Indexed Mapping:** Automatically maps log fields to `p1` through `p20` (default, but adjustable).
* **Dynamic Filtering:** Filter results by any column using simple string matching.
* **Auto-Sync:** Clones, commits, and pushes results to a specified Git branch.
* **Secure:** Uses SSH keys mounted as read-only volumes for repository access.

---

## Parameters

The parser uses indexed naming (`p1` to `p20`) to remain format-agnostic.
The number of parameters can be adjusted in the `parser.py` file using the `COLS_COUNT` variable.

| Parameter | Description | Example |
| --- | --- | --- |
| `input` | **(Required)** Path to the log file | `/tmp/access.log` |
| `--f-pX` | Filter column `X` by value | `--f-p6 200` (Filter by Status) |
| `--sort pX` | Sort by column `X` | `--sort p7` (Sort by Size) |

---

## Docker Environment

| Type | Description | Example |
| --- | --- | --- |
| **Volume** | **(Required)** Mapping SSH Git key as `/tmp/id_rsa` | `-v ~/.ssh/git_ssh.key:/tmp/id_rsa:ro` |
| **Volume** | **(Required)** Mapping the Nginx log file as the input filename (from parameters above) | `-v /var/log/nginx/access.log:/tmp/access.log:ro` |
| **Variable** | **(Required)** SSH URL to the Git repository | `-e GIT_REMOTE_URL="git@github.com:user/repo.git"` |
| **Variable** | Target Git branch (default: "main") | `-e GIT_BRANCH="devel"` |
| **Variable** | Commit username (default: "Log Parser Bot") | `-e GIT_USER_NAME="LogBot"` |
| **Variable** | Commit email (default: "bot@example.com") | `-e GIT_USER_EMAIL="bot@company.com"` |

---

## Usage Examples

### Minimal Run

Simply parse a log file and push it to the default branch (`main`).

* It takes the SSH key from the host path `~/.ssh/github.key` via the mapped volume `/tmp/keys:ro`.
* It analyzes the log file and pushes the result to the Git repository.

```bash
docker run --rm \
  -v ~/.ssh/git_ssh.key:/tmp/id_rsa:ro \
  -v /var/log/nginx/access.log:/tmp/access.log:ro \
  -e GIT_REMOTE_URL="git@github.com:user/repo.git" \
  nginx-log-parser /tmp/access.log
```

### Maximum Run

Filter by value `200` column `p6` and by value `288` column `p8`, sort by request time (column `p12`), and push to a specific branch `devel`, using custom Git user and email.

```bash
docker run --rm \
  -v ~/.ssh/git_ssh.key:/tmp/id_rsa:ro \
  -v /var/log/nginx/nginx.log:/tmp/nginx.log:ro \
  -e GIT_REMOTE_URL="git@github.com:user/repo.git" \
  -e GIT_BRANCH="devel" \
  -e GIT_USER_NAME="LogBot" \
  -e GIT_USER_EMAIL="bot@company.com" \
  nginx-log-parser /tmp/nginx.log --f-p6 200  --f-p8 288 --sort p12

```

---

## Exit Codes

The script uses specific exit codes to help you identify issues during automated execution:

| Code | Meaning | Troubleshooting |
| --- | --- | --- |
| **1** | `ERR_INVALID_URL` | Check if `GIT_REMOTE_URL` is a valid SSH string (`git@github.com:...`). |
| **2** | `ERR_SSH_KEY_MISSING` | The file specified in `SSH_KEY_NAME` was not found in the mounted volume. |
| **3** | `ERR_PARSER` | Python parser failed. Check if the log format matches the expected columns. |
| **4** | `ERR_GIT_OPS` | Git clone, commit, or push failed (check network or repository permissions). |
| **5** | `ERR_FILE_MISSING` | The input log file was not found at the specified path. |
| **6** | `ERR_FS_PROBLEM` | Cannot create a folder for a repo. |
| **7** | `ERR_GIT_CLONE_PROBLEM` | Git clone command has failed. |

---

## Installation & Build

To build the Docker image locally, navigate to the project root directory and run:

```bash
docker build -t nginx-log-parser .

```

---