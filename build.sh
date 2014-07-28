#!/bin/bash
#filename:
jekyll build
rsync -avz -e ssh _site/ root@localhost:/usr/share/nginx/html/
exit


