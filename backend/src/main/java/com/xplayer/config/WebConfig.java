package com.xplayer.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableConfigurationProperties(XPlayerProperties.class)
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:4173")
                .allowedMethods("GET", "HEAD", "OPTIONS")
                .allowedHeaders("*")
                .exposedHeaders("Content-Range", "Accept-Ranges", "Content-Length", "Content-Type");
    }
}
