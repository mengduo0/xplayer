package com.xplayer.repo;

import com.xplayer.model.VideoItem;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

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
}
