# Backup Script Examples

## Quick Start

### 1. Setup (One-Time)

```bash
# Copy and edit config
cp scripts/rclone.conf.example ~/.config/rclone/rclone.conf
nano ~/.config/rclone/rclone.conf
chmod 600 ~/.config/rclone/rclone.conf

# Test connection
rclone lsd minio-backup:
```

### 2. Run Backup

```bash
./scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant
```

## Common Commands

### Test Before Backup (Dry Run)

```bash
./scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant \
  --dry-run \
  --verbose
```

### Verbose Output

```bash
./scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant \
  --verbose
```

## Automation

### Daily Cron Job

Add to crontab (`crontab -e`):

```bash
# Daily at 2 AM
0 2 * * * /Users/ricardo.villanueva/Documents/code/com-ricardovz-work-assistant/scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant
```

### Weekly Cron Job

```bash
# Every Sunday at 3 AM
0 3 * * 0 /Users/ricardo.villanueva/Documents/code/com-ricardovz-work-assistant/scripts/backup-to-minio.sh \
  --source ~/.work-assistant \
  --config ~/.config/rclone/rclone.conf \
  --remote-name minio-backup \
  --bucket com-ricardovz-work-assistant
```

## Verification

```bash
# List files in bucket
rclone ls minio-backup:com-ricardovz-work-assistant

# List directory structure
rclone tree minio-backup:com-ricardovz-work-assistant

# Compare local vs remote
rclone check ~/.work-assistant minio-backup:com-ricardovz-work-assistant/.work-assistant
```

## Troubleshooting

```bash
# Test rclone connection
rclone lsd minio-backup:

# Show config
rclone config show minio-backup

# View logs
tail -f scripts/logs/backup-$(date +%Y%m%d).log
```
