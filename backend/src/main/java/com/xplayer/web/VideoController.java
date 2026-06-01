package com.xplayer.web;

import com.xplayer.model.CreateVideoRequest;
import com.xplayer.model.VideoItem;
import com.xplayer.repo.VideoRepository;
import com.xplayer.service.MediaStreamService;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class VideoController {

    private final VideoRepository videoRepository;
    private final MediaStreamService mediaStreamService;

    public VideoController(VideoRepository videoRepository, MediaStreamService mediaStreamService) {
        this.videoRepository = videoRepository;
        this.mediaStreamService = mediaStreamService;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> body = new HashMap<String, Object>();
        body.put("status", "ok");
        body.put("service", "xplayer-backend");
        return body;
    }

    @GetMapping("/videos")
    public List<VideoItem> listVideos() {
        return videoRepository.findAllEnabled().stream()
                .map(this::withStreamUrl)
                .collect(Collectors.toList());
    }

    @PostMapping("/videos")
    public ResponseEntity<VideoItem> createVideo(@RequestBody CreateVideoRequest request) throws IOException {
        if (request == null || !StringUtils.hasText(request.getFileName())) {
            throw new BadRequestException("fileName is required");
        }
        String fileName = request.getFileName().trim();
        if (fileName.contains("..")) {
            throw new BadRequestException("Invalid fileName");
        }
        mediaStreamService.resolveSafe(fileName);

        String title = StringUtils.hasText(request.getTitle())
                ? request.getTitle().trim()
                : stripExtension(fileName);

        VideoItem existing = videoRepository.findByFileName(fileName).orElse(null);
        if (existing != null) {
            if (videoRepository.findById(existing.getId()).isPresent()) {
                throw new ConflictException("Video already in playlist: " + fileName);
            }
            videoRepository.reEnable(existing.getId(), title, videoRepository.nextSortOrder());
            VideoItem item = videoRepository.findById(existing.getId())
                    .orElseThrow(() -> new NotFoundException("Video not found after restore"));
            return ResponseEntity.status(HttpStatus.CREATED).body(withStreamUrl(item));
        }

        long id = videoRepository.insert(title, fileName, videoRepository.nextSortOrder());
        VideoItem created = videoRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Video not found after insert"));
        return ResponseEntity.status(HttpStatus.CREATED).body(withStreamUrl(created));
    }

    @DeleteMapping("/videos/{id}")
    public ResponseEntity<Map<String, Object>> deleteVideo(@PathVariable long id) {
        if (!videoRepository.softDelete(id)) {
            throw new NotFoundException("Video not found: " + id);
        }
        Map<String, Object> body = new HashMap<String, Object>();
        body.put("deleted", true);
        body.put("id", id);
        return ResponseEntity.ok(body);
    }

    @GetMapping("/videos/{id}/stream")
    public ResponseEntity<Resource> stream(@PathVariable long id) throws IOException {
        VideoItem item = videoRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Video not found: " + id));
        try {
            Path path = mediaStreamService.resolveSafe(item.getFileName());
            Resource resource = mediaStreamService.asResource(path);
            MediaType type = mediaStreamService.contentType(path);
            return ResponseEntity.ok()
                    .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                    .contentType(type)
                    .body(resource);
        } catch (IOException ex) {
            throw new NotFoundException(ex.getMessage());
        }
    }

    private VideoItem withStreamUrl(VideoItem item) {
        item.setStreamUrl("/api/videos/" + item.getId() + "/stream");
        return item;
    }

    private static String stripExtension(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return dot > 0 ? fileName.substring(0, dot) : fileName;
    }

    @org.springframework.web.bind.annotation.ExceptionHandler(NotFoundException.class)
    public ResponseEntity<Map<String, String>> notFound(NotFoundException ex) {
        Map<String, String> body = new HashMap<String, String>();
        body.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }

    @org.springframework.web.bind.annotation.ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Map<String, String>> badRequest(BadRequestException ex) {
        Map<String, String> body = new HashMap<String, String>();
        body.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @org.springframework.web.bind.annotation.ExceptionHandler(ConflictException.class)
    public ResponseEntity<Map<String, String>> conflict(ConflictException ex) {
        Map<String, String> body = new HashMap<String, String>();
        body.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body);
    }

    @org.springframework.web.bind.annotation.ExceptionHandler(IOException.class)
    public ResponseEntity<Map<String, String>> ioError(IOException ex) {
        Map<String, String> body = new HashMap<String, String>();
        body.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }

    static class NotFoundException extends RuntimeException {
        NotFoundException(String message) {
            super(message);
        }
    }

    static class BadRequestException extends RuntimeException {
        BadRequestException(String message) {
            super(message);
        }
    }

    static class ConflictException extends RuntimeException {
        ConflictException(String message) {
            super(message);
        }
    }
}
