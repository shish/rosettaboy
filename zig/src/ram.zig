const Cart = @import("cart.zig").Cart;

pub const RAM = struct {
    cart: *Cart,
    data: [0xFFFF + 1]u8,

    pub fn new(cart: *Cart) !RAM {
        return RAM{
            .cart = cart,
            .data = undefined,
        };
    }

    pub fn get(self: *RAM, addr: u16) u8 {
        return self.data[addr];
    }
    pub fn set(self: *RAM, addr: u16, val: u8) void {
        self.data[addr] = val;
    }
};
