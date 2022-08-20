pub const Clock = struct {
    profile: u32,
    turbo: bool,

    pub fn new(profile: u32, turbo: bool) !Clock {
        return Clock{
            .profile = profile,
            .turbo = turbo,
            // FIXME
        };
    }

    pub fn tick(self: Clock) !void {
        _ = self;
    }
};
