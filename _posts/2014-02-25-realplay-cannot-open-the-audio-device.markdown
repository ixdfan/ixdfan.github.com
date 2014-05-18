---
author: UCSHELL
comments: true
date: 2014-02-25 15:33:54+00:00
layout: post
slug: realplay-cannot-open-the-audio-device
title: Realplay cannot open the audio device
wordpress_id: 1325
categories:
- THE TOOL
---

Realplay cannot open the audio device, Another application may be using it

    
    yum install alsa-oss application
    
    vim /usr/share/applications/realplay.desktop
    
    change 
    "Exec=realplay" to "Exec=aoss realplay"
