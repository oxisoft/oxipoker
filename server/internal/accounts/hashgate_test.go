package accounts

import (
	"sync"
	"testing"
)

func TestPasswordHashesRunWithBoundedParallelism(t *testing.T) {
	hash, err := HashPassword("a long enough password")
	if err != nil {
		t.Fatal(err)
	}
	hashPeak.Store(0)
	const n = 40
	var wg sync.WaitGroup
	for range n {
		wg.Go(func() {
			if ok, err := VerifyPassword(hash, "wrong password here"); ok || err != nil {
				t.Errorf("verify: %v %v", ok, err)
			}
		})
	}
	wg.Wait()
	if peak := int(hashPeak.Load()); peak > hashSlots() || peak < 1 {
		t.Fatalf("%d hashes ran at once, bound is %d", peak, hashSlots())
	}
}
