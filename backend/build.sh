#!/bin/bash
# Continuous build script
# XXX handle interrupts gracefully
NAME=flavr
if [ -f config ]
then
    . config
fi
while true
do
    reset
    pkill -f $NAME.exe
    (
        urweb $URWEB_FLAGS $NAME && \
        ./$NAME.exe
        #(./$NAME.exe &) && \
        #sleep 1 && \
        #(curl "http://localhost:8080/main" &> /dev/null)
    ) &
    PID=$!
    inotifywait -e modify *.ur *.urs 2> /dev/null
    #inotifywait -e modify $(git ls-files '*.ur' '*.urp' '*.urs' '*.c' '*.h') 2> /dev/null
    kill $PID
done
