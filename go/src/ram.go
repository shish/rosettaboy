package main

type RAM struct {
	debug bool
	cart  Cart
	data  []byte
}

func NewRAM(cart Cart, debug bool) RAM {
	return RAM{
		debug,
		cart,
		make([]byte, 16*1024),
	}
}

func (self RAM) Foo() []byte {
	return self.data
}
