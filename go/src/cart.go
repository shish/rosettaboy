package main

type Cart struct {
	data string
}

func NewCart(rom string) Cart {
	return Cart{rom}
}

func (self Cart) Foo() string {
	return self.data
}
