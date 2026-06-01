package com.xplayer.service;

import com.xplayer.config.XPlayerProperties;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class MediaStreamService {

    private final Path mediaRoot;

    public MediaStreamService(XPlayerProperties properties) {
        this.mediaRoot = Paths.get(properties.getMediaRoot()).toAbsolutePath().normalize();
    }

    public Path resolveSafe(String fileName) throws IOException {
        if (!StringUtils.hasText(fileName) || fileName.contains("..")) {
            throw new IOException("Invalid file name");
        }
        Path resolved = mediaRoot.resolve(fileName).normalize();
        if (!resolved.startsWith(mediaRoot)) {
            throw new IOException("Path traversal blocked");
        }
        if (!Files.isRegularFile(resolved)) {
            throw new IOException("File not found: " + fileName);
        }
        return resolved;
    }

    public Resource asResource(Path path) {
        return new FileSystemResource(path.toFile());
    }

    public MediaType contentType(Path path) throws IOException {
        String detected = Files.probeContentType(path);
        if (detected != null) {
            return MediaType.parseMediaType(detected);
        }
        String name = path.getFileName().toString().toLowerCase();
        if (name.endsWith(".mp4")) {
            return MediaType.parseMediaType("video/mp4");
        }
        if (name.endsWith(".webm")) {
            return MediaType.parseMediaType("video/webm");
        }
        if (name.endsWith(".mkv")) {
            return MediaType.parseMediaType("video/x-matroska");
        }
        if (name.endsWith(".ts")) {
            return MediaType.parseMediaType("video/mp2t");
        }
        return MediaType.APPLICATION_OCTET_STREAM;
    }
}
