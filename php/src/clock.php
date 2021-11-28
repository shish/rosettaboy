<?php

function ticks(): int {
    return (int)(microtime(true) * 1000);
}

class Clock {
    function __construct(Buttons $buttons, int $profile, bool $turbo) {
        $this->cycle = 0;
        $this->frame = 0;
        $this->last_frame_start = ticks();
        $this->start = ticks();
        $this->buttons = $buttons;
        $this->profile = $profile;
        $this->turbo = $turbo;
    }

    function tick(): bool {
        $this->cycle++;

        // Do a whole frame's worth of sleeping at the start of each frame
        if($this->cycle % 17556 == 20) {
            // Sleep if we have time left over
            $time_spent = (ticks() - $this->last_frame_start);
            $sleep_for = (1000 / 60) - $time_spent;
            if($sleep_for > 0 && !$this->turbo && !$this->buttons->turbo) {
                time_nanosleep(0, $sleep_for*1000000);
            }
            $this->last_frame_start = ticks();
    
            // Exit if we've hit the frame limit
            if($this->profile != 0 && $this->frame > $this->profile) {
                $duration = (double)(ticks() - $this->start) / 1000.0;
                printf("Emulated %d frames in %.2fs (%.2ffps)\n", $this->profile, $duration, $this->profile / $duration);
                return false;
            }
    
            $this->frame++;
        }
    
        return true;
    }
}
