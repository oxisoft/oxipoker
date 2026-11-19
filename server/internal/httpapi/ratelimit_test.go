package httpapi

import (
	"fmt"
	"net/http"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

// Parallel wrong sign-ins from one address: before F6 every request passed the
// check while the hashes ran, so far more than the limit were tried.
func TestParallelSigninsRespectTheAddressLimit(t *testing.T) {
	ts := newTestServer(t, "")
	const n = 3 * ipFailLimit
	var tried, limited atomic.Int32
	var wg sync.WaitGroup
	start := make(chan struct{})
	for i := range n {
		wg.Go(func() {
			<-start
			res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
				body: map[string]string{"username": fmt.Sprintf("nobody%d", i), "password": "wrong password here"}})
			switch res.StatusCode {
			case http.StatusUnauthorized:
				tried.Add(1)
			case http.StatusTooManyRequests:
				limited.Add(1)
			default:
				t.Errorf("status %d", res.StatusCode)
			}
		})
	}
	close(start)
	wg.Wait()
	if int(tried.Load()) != ipFailLimit || int(limited.Load()) != n-ipFailLimit {
		t.Fatalf("tried %d, limited %d; limit is %d", tried.Load(), limited.Load(), ipFailLimit)
	}
}

func TestTakeCountsAtOnceAndUndoGivesBack(t *testing.T) {
	l := newFailLimiter(2, time.Minute)
	if l.take("k") != 0 || l.take("k") != 0 {
		t.Fatal("first two attempts refused")
	}
	if l.take("k") == 0 {
		t.Fatal("third attempt allowed while two are counted")
	}
	l.undo("k")
	if l.take("k") != 0 {
		t.Fatal("undo did not give the attempt back")
	}
}

// A successful sign-in does not use up the address's attempts.
func TestSuccessfulSigninsDoNotCountAgainstTheAddress(t *testing.T) {
	ts := newTestServer(t, "")
	for range ipFailLimit + 2 {
		res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
			body: map[string]string{"username": "alex", "password": "long enough pw", "client": "app"}})
		if res.StatusCode != http.StatusOK {
			t.Fatalf("status %d", res.StatusCode)
		}
	}
}
