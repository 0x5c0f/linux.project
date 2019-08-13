#!/bin/bash
# add by 2017-12-19 file_monitor
# yum install inotify-tools 
/usr/bin/inotifywait -d -mr --timefmt '%Y-%m-%d_%H:%M' --format '%T %w%f---[%Xe]' -e modify,delete,create,moved_to,moved_from --outfile /tmp/file_monitory.log --exclude '(log)|(tmp)|(cache)' /tmp