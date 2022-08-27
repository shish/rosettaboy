const Cart = @import("cart.zig").Cart;

pub const RAM = struct {
    cart: *Cart,

    pub fn new(cart: *Cart) !RAM {
        return RAM{ .cart = cart };
    }
};
