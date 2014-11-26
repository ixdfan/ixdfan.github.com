---
layout: post
title: Realplay cannot open the audio device
categories:
- TOOL
---

Realplay cannot open the audio device, Another application may be using it

    
    yum install alsa-oss application
    
    vim /usr/share/applications/realplay.desktop
    
    change 
    "Exec=realplay" to "Exec=aoss realplay"
