FROM rclone/rclone:latest
RUN apk add --no-cache bash
COPY rclone.conf /config/rclone/rclone.conf
COPY main_backup.sh /app/main_backup.sh
RUN chmod +x /app/main_backup.sh
WORKDIR /app
ENTRYPOINT ["/app/main_backup.sh"]
