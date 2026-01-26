# MinIO S3 Backup Script

Simple bash script for incremental backups to MinIO S3 storage using rclone.

## Prerequisites

### Install rclone

**macOS:**

```bash
brew install rclone
```

**Linux:**

```bash
sudo apt-get install rclone  # Debian/Ubuntu
# or
curl https://rclone.org/install.sh | sudo bash
```

### Configure rclone

1. Copy example config:

```bash
cp scripts/rclone.conf.example ~/.config/rclone/rclone.conf
```

2. Edit with your credentials:

```bash
nano ~/.config/rclone/rclone.conf
```

3. Set secure permissions:

```bash
chmod 600 ~/.config/rclone/rclone.conf
```

4. Test connection:

```bash
rclone lsd minio-backup:
```

## Usage

### Basic Backup

```bash
./scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant
```

### Test First (Dry Run)

```bash
./scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant \
  --dry-run
```

### Automation (Cron)

Add to crontab (`crontab -e`):

```bash
# Daily backup at 2 AM
0 2 * * * /Users/ricardo.villanueva/Documents/code/com-ricardovz-work-assistant/scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant
```

## Options

- `--source DIR` - Source directory to backup (required)
- `--config PATH` - Path to rclone config file (required)
- `--remote-name NAME` - Remote name in config (default: minio-backup)
- `--bucket NAME` - S3 bucket name (required)
- `--dest-path PATH` - Destination path in bucket (optional, default: source basename)
- `--log-dir DIR` - Log directory (default: ./logs)
- `--dry-run` - Test without uploading
- `--verbose` - Verbose output

## Verification

```bash
# List backups
rclone ls minio-backup:com-ricardovz-work-assistant

# Compare local vs remote
rclone check ~/.work-assistant minio-backup:com-ricardovz-work-assistant/.work-assistant
```

## Troubleshooting

**"SignatureDoesNotMatch" Error:**
Ensure your rclone config includes:

- `region = other-v2-signature`
- `force_path_style = true`
- `sign_accept_encoding = false`

**Check logs:**

```bash
tail -f scripts/logs/backup-$(date +%Y%m%d).log
```

## How It Works

- Uses `rclone sync` for incremental backups
- Only uploads new or modified files
- Maintains directory structure
- Logs to `./logs/backup-YYYYMMDD.log`
