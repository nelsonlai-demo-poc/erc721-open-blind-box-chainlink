package main

import (
	"fmt"
	"math/rand"
)

type RevealRecord struct {
	Token    int
	RevealId int
	Loop     int
}

func main() {

	maxSupply := 6666

	revealed := 0

	usedMap := make(map[int]bool)

	maxLoop := 0
	maxToken := 0

	for i := 0; i < maxSupply; i++ {
		revealId := (_random() % (maxSupply - revealed)) + revealed
		var loop int
		for usedMap[revealId] {
			revealId++
			loop++
		}
		usedMap[revealId] = true

		if loop > maxLoop {
			maxLoop = loop
		}

		if revealId > maxToken {
			maxToken = revealId
		}
	}

	fmt.Println("maxLoop:", maxLoop)
	fmt.Println("maxToken:", maxToken)
}

func _random() int {
	return rand.Intn(9999999999999)
}
