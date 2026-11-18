package accounts

import (
	"bytes"
	"context"
	"database/sql"
	"errors"
	"image"
	"image/draw"
	"image/png"
	"strings"
	"unicode/utf8"

	xdraw "golang.org/x/image/draw"
)

// Themes a user can pick. Classic is the default.
const (
	ThemeClassic   = "classic"
	ThemeCyberpunk = "cyberpunk"
)

// Card back sizes and the setting that holds the server default.
const (
	CardBackWidth          = 500
	CardBackHeight         = 700
	SettingCardBackDefault = "card_back_default"
	uploadedPrefix         = "u-"
	maxCardBackName        = 40
	maxCardBacks           = 50
)

// CardBack is a design for the back of the cards. Built-in backs are drawn
// by the apps from their id; uploaded backs are served as PNG by the server.
type CardBack struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Theme   string `json:"theme,omitempty"` // the theme a built-in back was made for
	BuiltIn bool   `json:"built_in"`
}

// BuiltInCardBacks are the designs every server has, two per theme.
var BuiltInCardBacks = []CardBack{
	{ID: "classic-red", Name: "Classic red", Theme: ThemeClassic, BuiltIn: true},
	{ID: "classic-blue", Name: "Classic blue", Theme: ThemeClassic, BuiltIn: true},
	{ID: "cyber-grid", Name: "Neon grid", Theme: ThemeCyberpunk, BuiltIn: true},
	{ID: "cyber-circuit", Name: "Circuit", Theme: ThemeCyberpunk, BuiltIn: true},
}

// DefaultCardBack is used until an admin picks another one.
const DefaultCardBack = "classic-red"

// Appearance errors.
var (
	ErrBadTheme        = errors.New("unknown theme")
	ErrBadCardBack     = errors.New("unknown card back")
	ErrBadCardBackName = errors.New("card back name must be 1 to 40 characters")
	ErrCardBackDefault = errors.New("the server default card back cannot be deleted")
	ErrCardBackBuiltIn = errors.New("built-in card backs cannot be deleted")
	ErrTooManyBacks    = errors.New("too many uploaded card backs")
)

// ProcessCardBack decodes an uploaded picture, crops the centre 5:7 area and
// re-encodes it as a 500 x 700 PNG, dropping all metadata. GIF is not
// accepted here: card backs are PNG, JPEG or WebP.
func ProcessCardBack(data []byte) ([]byte, error) {
	cfg, format, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return nil, ErrBadImage
	}
	switch format {
	case "png", "jpeg", "webp":
	default:
		return nil, ErrBadImage
	}
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxAvatarSide || cfg.Height > maxAvatarSide ||
		cfg.Width*cfg.Height > maxAvatarPixels {
		return nil, ErrImageLarge
	}
	src, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, ErrBadImage
	}
	b := src.Bounds()
	w, h := b.Dx(), b.Dy()
	// Largest 5:7 rectangle that fits, centred.
	if w*7 > h*5 {
		w = h * 5 / 7
	} else {
		h = w * 7 / 5
	}
	w, h = max(w, 1), max(h, 1)
	x0 := b.Min.X + (b.Dx()-w)/2
	y0 := b.Min.Y + (b.Dy()-h)/2
	dst := image.NewNRGBA(image.Rect(0, 0, CardBackWidth, CardBackHeight))
	xdraw.CatmullRom.Scale(dst, dst.Bounds(), src, image.Rect(x0, y0, x0+w, y0+h), draw.Src, nil)
	var out bytes.Buffer
	enc := png.Encoder{CompressionLevel: png.BestCompression}
	if err := enc.Encode(&out, dst); err != nil {
		return nil, err
	}
	return out.Bytes(), nil
}

func builtInBack(id string) bool {
	for _, b := range BuiltInCardBacks {
		if b.ID == id {
			return true
		}
	}
	return false
}

// CardBackExists reports whether id is a built-in or uploaded back.
func (s *Service) CardBackExists(ctx context.Context, id string) (bool, error) {
	if builtInBack(id) {
		return true, nil
	}
	if !strings.HasPrefix(id, uploadedPrefix) {
		return false, nil
	}
	var n int
	err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM card_backs WHERE id = ?`, id).Scan(&n)
	return n > 0, err
}

// DefaultCardBackID returns the server default, falling back to the
// built-in default when the stored id no longer exists.
func (s *Service) DefaultCardBackID(ctx context.Context) (string, error) {
	id, err := s.st.Setting(ctx, SettingCardBackDefault, DefaultCardBack)
	if err != nil {
		return DefaultCardBack, err
	}
	ok, err := s.CardBackExists(ctx, id)
	if err != nil || !ok {
		return DefaultCardBack, err
	}
	return id, nil
}

// SetDefaultCardBack makes id the server default.
func (s *Service) SetDefaultCardBack(ctx context.Context, id string) error {
	ok, err := s.CardBackExists(ctx, id)
	if err != nil {
		return err
	}
	if !ok {
		return ErrBadCardBack
	}
	return s.st.SetSetting(ctx, SettingCardBackDefault, id)
}

// CardBacks lists built-in backs first, then uploads in upload order.
func (s *Service) CardBacks(ctx context.Context) ([]CardBack, error) {
	out := append([]CardBack(nil), BuiltInCardBacks...)
	rows, err := s.db.QueryContext(ctx, `SELECT id, name FROM card_backs ORDER BY created_at, id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var b CardBack
		if err := rows.Scan(&b.ID, &b.Name); err != nil {
			return nil, err
		}
		out = append(out, b)
	}
	return out, rows.Err()
}

// AddCardBack processes and stores an uploaded back.
func (s *Service) AddCardBack(ctx context.Context, name string, data []byte) (CardBack, error) {
	name = strings.TrimSpace(name)
	if n := utf8.RuneCountInString(name); n < 1 || n > maxCardBackName {
		return CardBack{}, ErrBadCardBackName
	}
	var count int
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM card_backs`).Scan(&count); err != nil {
		return CardBack{}, err
	}
	if count >= maxCardBacks {
		return CardBack{}, ErrTooManyBacks
	}
	pngData, err := ProcessCardBack(data)
	if err != nil {
		return CardBack{}, err
	}
	b := CardBack{ID: uploadedPrefix + strings.ToLower(NewID()), Name: name}
	if _, err := s.db.ExecContext(ctx, `INSERT INTO card_backs (id, name, png, created_at) VALUES (?, ?, ?, ?)`,
		b.ID, b.Name, pngData, s.now().UnixMilli()); err != nil {
		return CardBack{}, err
	}
	return b, nil
}

// DeleteCardBack removes an uploaded back that is not the server default;
// users who had picked it go back to the default.
func (s *Service) DeleteCardBack(ctx context.Context, id string) error {
	if builtInBack(id) {
		return ErrCardBackBuiltIn
	}
	def, err := s.DefaultCardBackID(ctx)
	if err != nil {
		return err
	}
	if id == def {
		return ErrCardBackDefault
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	res, err := tx.ExecContext(ctx, `DELETE FROM card_backs WHERE id = ?`, id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	if _, err := tx.ExecContext(ctx, `UPDATE users SET card_back = '' WHERE card_back = ?`, id); err != nil {
		return err
	}
	return tx.Commit()
}

// CardBackImage returns an uploaded back's PNG.
func (s *Service) CardBackImage(ctx context.Context, id string) ([]byte, error) {
	var data []byte
	err := s.db.QueryRowContext(ctx, `SELECT png FROM card_backs WHERE id = ?`, id).Scan(&data)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	return data, err
}

// Appearance holds the optional parts of a PATCH /me.
type Appearance struct {
	Theme    *string
	CardBack *string // "" = follow the server default
}

// SetAppearance stores a user's theme and card back choices.
func (s *Service) SetAppearance(ctx context.Context, userID string, a Appearance) error {
	if a.Theme != nil && *a.Theme != ThemeClassic && *a.Theme != ThemeCyberpunk {
		return ErrBadTheme
	}
	if a.CardBack != nil && *a.CardBack != "" {
		ok, err := s.CardBackExists(ctx, *a.CardBack)
		if err != nil {
			return err
		}
		if !ok {
			return ErrBadCardBack
		}
	}
	now := s.now().UnixMilli()
	if a.Theme != nil {
		if _, err := s.db.ExecContext(ctx, `UPDATE users SET theme = ?, updated_at = ? WHERE id = ?`, *a.Theme, now, userID); err != nil {
			return err
		}
	}
	if a.CardBack != nil {
		if _, err := s.db.ExecContext(ctx, `UPDATE users SET card_back = ?, updated_at = ? WHERE id = ?`, *a.CardBack, now, userID); err != nil {
			return err
		}
	}
	return nil
}
