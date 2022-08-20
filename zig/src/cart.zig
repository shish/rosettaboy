pub const Cart = struct {
    name: []const u8,

    pub fn new(cart: []const u8) !Cart {
        return Cart{
            // FIXME
            .name = cart,
        };
    }
};
