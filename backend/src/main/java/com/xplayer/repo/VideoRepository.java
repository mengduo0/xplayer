package com.xplayer.repo;

import com.xplayer.model.VideoItem;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;
import java.util.Optional;

@Repository
public class VideoRepository {

    private static final RowMapper<VideoItem> ROW_MAPPER = (rs, rowNum) -> {
        VideoItem item = new VideoItem();
        item.setId(rs.getLong("id"));
        item.setTitle(rs.getString("title"));
        item.setFileName(rs.getString("file_name"));
        int duration = rs.getInt("duration_sec");
        if (!rs.wasNull()) {
            item.setDurationSec(duration);
        }
        return item;
    };

    private final JdbcTemplate jdbc;

    public VideoRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<VideoItem> findAllEnabled() {
        return jdbc.query(
                "SELECT id, title, file_name, duration_sec FROM video WHERE enabled = 1 ORDER BY sort_order, id",
                ROW_MAPPER);
    }

    public Optional<VideoItem> findById(long id) {
        List<VideoItem> rows = jdbc.query(
                "SELECT id, title, file_name, duration_sec FROM video WHERE id = ? AND enabled = 1",
                ROW_MAPPER,
                id);
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.get(0));
    }

    public Optional<VideoItem> findByFileName(String fileName) {
        List<VideoItem> rows = jdbc.query(
                "SELECT id, title, file_name, duration_sec FROM video WHERE file_name = ?",
                ROW_MAPPER,
                fileName);
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.get(0));
    }

    public int nextSortOrder() {
        Integer max = jdbc.queryForObject(
                "SELECT COALESCE(MAX(sort_order), 0) FROM video",
                Integer.class);
        return max == null ? 1 : max + 1;
    }

    public long insert(String title, String fileName, int sortOrder) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO video (title, file_name, sort_order, enabled) VALUES (?, ?, ?, 1)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, title);
            ps.setString(2, fileName);
            ps.setInt(3, sortOrder);
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        if (key == null) {
            throw new IllegalStateException("Failed to generate video id");
        }
        return key.longValue();
    }

    public boolean reEnable(long id, String title, int sortOrder) {
        int updated = jdbc.update(
                "UPDATE video SET enabled = 1, title = ?, sort_order = ? WHERE id = ?",
                title,
                sortOrder,
                id);
        return updated > 0;
    }

    public boolean softDelete(long id) {
        int updated = jdbc.update("UPDATE video SET enabled = 0 WHERE id = ? AND enabled = 1", id);
        return updated > 0;
    }
}
