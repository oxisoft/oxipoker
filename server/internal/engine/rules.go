package engine

// Rules is everything that differs between poker variants played with the
// same hand flow (blinds, four betting rounds, five board cards, showdown).
// No-Limit Hold'em is the only variant in v1; Pot-Limit Omaha plugs in by
// dealing four hole cards, using exactly two of them and capping bets at the
// pot.
type Rules interface {
	// Name is the short variant name stored in the hand history.
	Name() string
	// HoleCards is the number of private cards each player gets.
	HoleCards() int
	// MaxBetTo is the largest street total the player may bet or raise to,
	// before the stack limit (the hand applies min(MaxBetTo, all-in)).
	MaxBetTo(h *Hand, p *Player) int64
	// Best is the value of the best hand the player can make.
	Best(hole, board []Card) Value
}

// NoLimitHoldem is No-Limit Texas Hold'em.
type NoLimitHoldem struct{}

func (NoLimitHoldem) Name() string   { return "nlhe" }
func (NoLimitHoldem) HoleCards() int { return 2 }

// MaxBetTo: no limit, the whole stack.
func (NoLimitHoldem) MaxBetTo(_ *Hand, p *Player) int64 { return p.Bet + p.Stack }

func (NoLimitHoldem) Best(hole, board []Card) Value {
	var all [7]Card
	n := copy(all[:], hole)
	n += copy(all[n:], board)
	return Evaluate(all[:n])
}
