package accounts

import (
	"runtime"
	"sync/atomic"

	"golang.org/x/crypto/argon2"
)

// Every argon2id run takes about 19 MiB. Without a bound, a burst of parallel
// sign-in requests (each one passes the limits until its hash is done) could
// allocate memory without end and stop the server (F5). Runs above the bound
// wait for a free slot; they are CPU bound, so more parallel runs would not
// finish sooner anyway.
var (
	hashGate   = make(chan struct{}, hashSlots())
	hashActive atomic.Int32
	hashPeak   atomic.Int32
)

func hashSlots() int {
	return min(max(runtime.GOMAXPROCS(0), 2), 8)
}

func idKey(pw, salt []byte, t, m uint32, p uint8, n uint32) []byte {
	hashGate <- struct{}{}
	defer func() { <-hashGate }()
	now := hashActive.Add(1)
	defer hashActive.Add(-1)
	for {
		peak := hashPeak.Load()
		if now <= peak || hashPeak.CompareAndSwap(peak, now) {
			break
		}
	}
	return argon2.IDKey(pw, salt, t, m, p, n)
}
