import cart

type
    RAM* = object
        cart: cart.Cart

proc create*(cart: Cart): RAM =
    return RAM(
      cart: cart
    )
