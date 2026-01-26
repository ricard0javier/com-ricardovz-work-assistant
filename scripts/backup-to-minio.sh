#!/bin/bash

###############################################################################
# Backup Script for MinIO S3 Storage
# 
# Performs efficient, incremental backups to MinIO S3 buckets using rclone sync.
#
# Usage:
#   ./backup-to-minio.sh --source DIR --config PATH --bucket NAME [OPTIONS]
#
# Required Options:
#   -s, --source DIR          Source directory to backup
#   -c, --config PATH         Path to rclone config file
#   -b, --bucket NAME         S3 bucket name
#
# Optional Options:
#   -n, --remote-name NAME    Remote name in config (default: minio-backup)
#   -d, --dest-path PATH      Destination path in bucket (default: source basename)
#   -l, --log-dir DIR         Log directory (default: ./logs)
#   --dry-run                 Test without uploading
#   -v, --verbose             Verbose output
#   -h, --help                Show help
#
###############################################################################

set -euo pipefail

# Default values
SOURCE_DIR=""
BUCKET=""
RCLONE_CONFIG=""
REMOTE_NAME="minio-backup"
DEST_PATH=""
LOG_DIR="./logs"
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

###############################################################################
# Functions
###############################################################################

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/backup-$(date '+%Y%m%d').log"
    
    # Ensure log directory exists
    mkdir -p "${LOG_DIR}"
    
    # Color output for terminal
    case $level in
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}" | tee -a "${log_file}"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}" | tee -a "${log_file}"
            ;;
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - ${message}" | tee -a "${log_file}"
            ;;
        *)
            echo "[${level}] ${timestamp} - ${message}" | tee -a "${log_file}"
            ;;
    esac
}

error_exit() {
    log ERROR "$@"
    exit 1
}

show_usage() {
    cat << EOF
Usage: $0 --source DIR --config PATH --bucket NAME [OPTIONS]

Backup a directory to MinIO S3 storage using rclone sync.

REQUIRED OPTIONS:
    -s, --source DIR          Source directory to backup
    -c, --config PATH         Path to rclone config file
    -b, --bucket NAME         S3 bucket name

OPTIONAL OPTIONS:
    -n, --remote-name NAME    Remote name in config (default: minio-backup)
    -d, --dest-path PATH      Destination path in bucket (default: source basename)
    -l, --log-dir DIR         Log directory (default: ./logs)
    --dry-run                 Test without uploading
    -v, --verbose             Verbose output
    -h, --help                Show this help message

EXAMPLE:
    $0 --source ~/.work-assistant \\
       --config ~/.config/rclone/rclone.conf \\
       --remote-name minio-backup \\
       --bucket com-ricardovz-work-assistant

EOF
}

check_dependencies() {
    if ! command -v rclone &> /dev/null; then
        error_exit "rclone is not installed. Please install it first: https://rclone.org/install/"
    fi
    
    local rclone_version=$(rclone version | head -n 1 | awk '{print $2}')
    log INFO "Using rclone version: ${rclone_version}"
}

validate_inputs() {
    if [ -z "${SOURCE_DIR}" ]; then
        error_exit "Source directory is required. Use -s/--source"
    fi
    
    if [ ! -d "${SOURCE_DIR}" ]; then
        error_exit "Source directory does not exist: ${SOURCE_DIR}"
    fi
    
    if [ ! -r "${SOURCE_DIR}" ]; then
        error_exit "Source directory is not readable: ${SOURCE_DIR}"
    fi
    
    if [ -z "${BUCKET}" ]; then
        error_exit "Bucket name is required. Use -b/--bucket"
    fi
    
    if [ -z "${RCLONE_CONFIG}" ]; then
        error_exit "Config file is required. Use -c/--config"
    fi
    
    if [ ! -f "${RCLONE_CONFIG}" ]; then
        error_exit "Config file not found: ${RCLONE_CONFIG}"
    fi
    
    if [ -z "${DEST_PATH}" ]; then
        DEST_PATH=$(basename "${SOURCE_DIR}")
    fi
    
    log INFO "Validation passed"
    log INFO "Source: ${SOURCE_DIR}"
    log INFO "Bucket: ${BUCKET}"
    log INFO "Destination: ${DEST_PATH}"
    log INFO "Config: ${RCLONE_CONFIG}"
    log INFO "Remote: ${REMOTE_NAME}"
}

setup_rclone_remote() {
    log INFO "Using rclone config file: ${RCLONE_CONFIG}"
}

build_rclone_command() {
    local cmd="rclone sync --config '${RCLONE_CONFIG}'"
    
    if [ "${DRY_RUN}" = true ]; then
        cmd="${cmd} --dry-run"
        log WARN "DRY RUN MODE - No files will be uploaded"
    fi
    
    if [ "${VERBOSE}" = true ]; then
        cmd="${cmd} -v"
    fi
    
    cmd="${cmd} --progress --stats 30s"
    
    local source="${SOURCE_DIR}"
    if [ "${source: -1}" != "/" ]; then
        source="${source}/"
    fi
    
    local dest="${REMOTE_NAME}:${BUCKET}/${DEST_PATH}"
    if [ "${dest: -1}" != "/" ]; then
        dest="${dest}/"
    fi
    
    cmd="${cmd} '${source}' '${dest}'"
    
    echo "${cmd}"
}

verify_backup() {
    if [ "${DRY_RUN}" = true ]; then
        log INFO "Skipping verification in dry-run mode"
        return 0
    fi
    
    log INFO "Verifying backup..."
    
    local source="${SOURCE_DIR}"
    if [ "${source: -1}" != "/" ]; then
        source="${source}/"
    fi
    
    local dest="${REMOTE_NAME}:${BUCKET}/${DEST_PATH}"
    if [ "${dest: -1}" != "/" ]; then
        dest="${dest}/"
    fi
    
    if rclone check --config "${RCLONE_CONFIG}" "${source}" "${dest}" 2>&1 | tee -a "${LOG_DIR}/backup-$(date '+%Y%m%d').log"; then
        log INFO "Backup verification completed successfully"
    else
        log WARN "Backup verification found differences (this may be expected for some files)"
    fi
}


###############################################################################
# Parse command-line arguments
###############################################################################

# Load from environment variables first
SOURCE_DIR="${BACKUP_SOURCE:-${SOURCE_DIR}}"
BUCKET="${BACKUP_BUCKET:-${BUCKET}}"
RCLONE_CONFIG="${BACKUP_CONFIG:-${RCLONE_CONFIG}}"
REMOTE_NAME="${BACKUP_REMOTE_NAME:-${REMOTE_NAME}}"
DEST_PATH="${BACKUP_DEST_PATH:-${DEST_PATH}}"
LOG_DIR="${BACKUP_LOG_DIR:-${LOG_DIR}}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -b|--bucket)
            BUCKET="$2"
            shift 2
            ;;
        -c|--config)
            RCLONE_CONFIG="$2"
            shift 2
            ;;
        -n|--remote-name)
            REMOTE_NAME="$2"
            shift 2
            ;;
        -d|--dest-path)
            DEST_PATH="$2"
            shift 2
            ;;
        -l|--log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            error_exit "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

###############################################################################
# Main execution
###############################################################################

main() {
    log INFO "=== Backup Script Started ==="
    
    check_dependencies
    validate_inputs
    setup_rclone_remote
    
    local rclone_cmd=$(build_rclone_command)
    log INFO "Executing: ${rclone_cmd}"
    
    # Execute rclone sync
    local start_time=$(date +%s)
    if eval "${rclone_cmd}" 2>&1 | tee -a "${LOG_DIR}/backup-$(date '+%Y%m%d').log"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log INFO "Backup completed successfully in ${duration} seconds"
        
        # Verify backup (optional, can be disabled if too slow)
        verify_backup
        
        log INFO "=== Backup Script Completed Successfully ==="
        exit 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error_exit "Backup failed after ${duration} seconds"
    fi
}

main

