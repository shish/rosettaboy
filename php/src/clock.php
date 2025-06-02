<?php

declare(strict_types=1);

function ticks(): int
{
    return (int)(microtime(true) * 1000);
}

class Clock
{
    private int $cycle;
    private int $frame;
    private bool $turbo;
    private int $frames;
    private int $profile;
    private Buttons $buttons;
    private int $start;
    private int $last_frame_start;

    public function __construct(Buttons $buttons, int $frames, int $profile, bool $turbo)
    {
        $this->cycle = 0;
        $this->frame = 0;
        $this->last_frame_start = ticks();
        $this->start = ticks();
        $this->buttons = $buttons;
        $this->frames = $frames;
        $this->profile = $profile;
        $this->turbo = $turbo;
    }

    public function tick(): void
    {
        $this->cycle++;

        // Do a whole frame's worth of sleeping at the start of each frame
        if ($this->cycle % 17556 == 20) {
            // Sleep if we have time left over
            $time_spent = (ticks() - $this->last_frame_start);
            $sleep_for = (1000 / 60) - $time_spent;
            if ($sleep_for > 0 && !$this->turbo && !$this->buttons->turbo) {
                time_nanosleep(0, (int)($sleep_for * 1000000));
            }
            $this->last_frame_start = ticks();

            // Exit if we've hit the frame or time limit
            $duration = (float)($this->last_frame_start - $this->start) / 1000.0;
            if (($this->frames != 0 && $this->frame >= $this->frames) || ($this->profile != 0 && $duration >= $this->profile)) {
                throw new Timeout($this->frame, $duration);
            }

            $this->frame++;
        }
    }
}
