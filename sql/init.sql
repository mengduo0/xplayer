CREATE DATABASE IF NOT EXISTS xplayer

  DEFAULT CHARACTER SET utf8mb4

  COLLATE utf8mb4_unicode_ci;



USE xplayer;



CREATE TABLE IF NOT EXISTS video (

  id           BIGINT AUTO_INCREMENT PRIMARY KEY,

  title        VARCHAR(255) NOT NULL,

  file_name    VARCHAR(512) NOT NULL COMMENT 'relative to media-root (G:/mv)',

  duration_sec INT NULL,

  sort_order   INT NOT NULL DEFAULT 0,

  enabled      TINYINT(1) NOT NULL DEFAULT 1,

  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uk_file_name (file_name)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- 固定素材：G:/mv 下的 default.mp4



INSERT INTO video (title, file_name, sort_order) VALUES

  ('default', 'default.mp4', 1)

ON DUPLICATE KEY UPDATE title = VALUES(title), sort_order = VALUES(sort_order);

