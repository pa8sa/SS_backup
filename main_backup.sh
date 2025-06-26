#!/bin/bash

# Rclone Bucket Copy Script (Files at Bucket Root)
# Copies all buckets except excluded ones, with specific file copying from excluded buckets

set -o allexport
source .env
set +o allexport

# Configuration
SOURCE_REMOTE="source"      # Your source remote name
DEST_REMOTE="destination"   # Your destination remote name
THREADS=4                   # Transfer threads
LOG_FILE="rclone_copy.log"  # Log file

# Buckets to exclude from full copy
# Specific files to copy from excluded buckets (must be at bucket root)
IFS=' ' read -r -a EXCLUDE_BUCKETS <<< "$EXCLUDE_BUCKETS_ENV"
IFS=$'\n' read -d '' -r -a FILES_TO_COPY <<< "$FILES_TO_COPY_ENV"

echo "Starting copy process..."
echo "Excluded buckets: ${EXCLUDE_BUCKETS[*]}"
echo "Files to copy from excluded buckets:"
printf "  - %s\n" "${FILES_TO_COPY[@]}"
echo "----------------------------------------"

# Copy specific files from excluded buckets
for file_entry in "${FILES_TO_COPY[@]}"; do
    IFS=':' read -r bucket filename <<< "$file_entry"
    
    echo "Copying ${filename} from ${bucket}"
    
    rclone copyto "${SOURCE_REMOTE}:${bucket}/${filename}" \
                 "${DEST_REMOTE}:${bucket}/${filename}" \
        --progress \
        --log-file="${LOG_FILE}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully copied ${filename}"
    else
        echo "✗ Failed to copy ${filename}"
    fi
    echo "----------------------------------------"
done

# Copy all other buckets completely
for BUCKET in $(rclone lsd "${SOURCE_REMOTE}:" | awk '{print $NF}'); do
    if [[ " ${EXCLUDE_BUCKETS[*]} " =~ " ${BUCKET} " ]]; then
        continue  # Skip excluded buckets
    fi
    
    echo "Copying entire bucket: ${BUCKET}"
    rclone copy "${SOURCE_REMOTE}:${BUCKET}" "${DEST_REMOTE}:${BUCKET}" \
        --progress \
        --transfers=${THREADS} \
        --log-file="${LOG_FILE}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully copied ${BUCKET}"
    else
        echo "✗ Failed to copy ${BUCKET}"
    fi
    echo "----------------------------------------"
done

echo "All operations completed"
