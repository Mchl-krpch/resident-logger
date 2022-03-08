# resident-logger

###### the program implements the idea of `replacing interrupts` with their own functions. Thus, the program can run in `resident-mode` and react in a special way to keystrokes.

The essence of the program is to draw a window every [55 milliseconds](http://vitaly_filatov.tripod.com/ng/asm/asm_001.7.html) to show the current value of the registers - this is possible by replacing the `eighth interrupt` with your own.

the `ninth interrupt` is responsible for the program interface. With it, we can press the control key and hide the frame, and with the help of alt we can stop the resident


