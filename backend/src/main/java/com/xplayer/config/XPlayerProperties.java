package com.xplayer.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "xplayer")
public class XPlayerProperties {

    /** Local directory containing video files, e.g. G:/mv */
    private String mediaRoot = "G:/mv";

    public String getMediaRoot() {
        return mediaRoot;
    }

    public void setMediaRoot(String mediaRoot) {
        this.mediaRoot = mediaRoot;
    }
}
