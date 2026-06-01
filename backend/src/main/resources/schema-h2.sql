CREATE TABLE IF NOT EXISTS video (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  title        VARCHAR(255) NOT NULL,
  file_name    VARCHAR(512) NOT NULL,
  duration_sec INT NULL,
  sort_order   INT NOT NULL DEFAULT 0,
  enabled      TINYINT NOT NULL DEFAULT 1,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_file_name UNIQUE (file_name)
);
