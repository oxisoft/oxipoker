package httpapi

import (
	"sync"
	"time"
)

// failLimiter counts failures per key in a fixed window. A key with max
// failures inside the window is blocked until the window ends.
type failLimiter struct {
	mu     sync.Mutex
	max    int
	window time.Duration
	now    func() time.Time
	seen   map[string]*failEntry
	sweep  time.Time
}

type failEntry struct {
	count int
	reset time.Time
}

func newFailLimiter(max int, window time.Duration) *failLimiter {
	return &failLimiter{max: max, window: window, now: time.Now, seen: map[string]*failEntry{}}
}

// blocked returns how long the key must wait, 0 when it may try.
func (l *failLimiter) blocked(key string) time.Duration {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	e := l.seen[key]
	if e == nil || !now.Before(e.reset) {
		return 0
	}
	if e.count >= l.max {
		return e.reset.Sub(now)
	}
	return 0
}

func (l *failLimiter) fail(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.failLocked(key)
}

// take checks and counts one attempt in a single step: when the key may try,
// the attempt is counted as a failure at once and take returns 0. Callers
// give it back with undo when the attempt turns out not to be a failure.
// Checking with blocked and counting with fail after the slow password hash
// let many parallel attempts pass the check before the first was counted.
func (l *failLimiter) take(key string) time.Duration {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	if e := l.seen[key]; e != nil && now.Before(e.reset) && e.count >= l.max {
		return e.reset.Sub(now)
	}
	l.failLocked(key)
	return 0
}

// undo gives back one attempt counted by take.
func (l *failLimiter) undo(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if e := l.seen[key]; e != nil && e.count > 0 {
		e.count--
	}
}

func (l *failLimiter) failLocked(key string) {
	now := l.now()
	if now.After(l.sweep) {
		for k, e := range l.seen {
			if !now.Before(e.reset) {
				delete(l.seen, k)
			}
		}
		l.sweep = now.Add(l.window)
	}
	e := l.seen[key]
	if e == nil || !now.Before(e.reset) {
		e = &failEntry{reset: now.Add(l.window)}
		l.seen[key] = e
	}
	e.count++
}

func (l *failLimiter) clear(key string) {
	l.mu.Lock()
	delete(l.seen, key)
	l.mu.Unlock()
}
