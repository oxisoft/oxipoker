package accounts

import (
	"bytes"
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"image"
	"image/draw"
	_ "image/gif" // decoders accepted for upload
	_ "image/jpeg"
	"image/png"

	xdraw "golang.org/x/image/draw"
	_ "golang.org/x/image/webp"
)

// Avatar limits. The upload size cap becomes a server setting in the admin
// console; DefaultMaxUpload applies until then.
const (
	AvatarSize       = 256
	DefaultMaxUpload = 5 << 20
	maxAvatarSide    = 8192
	maxAvatarPixels  = 40_000_000
)

var (
	ErrBadImage   = errors.New("not a PNG, JPEG, GIF or WebP image")
	ErrImageLarge = errors.New("image dimensions too large")
)

// ProcessAvatar decodes an uploaded picture, crops the centre square and
// re-encodes it as a 256 px PNG. Re-encoding drops every metadata block (EXIF,
// GPS, comments) and anything that is not pixels; SVG is never accepted
// because only raster decoders are registered.
func ProcessAvatar(data []byte) ([]byte, error) {
	cfg, format, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return nil, ErrBadImage
	}
	switch format {
	case "png", "jpeg", "gif", "webp":
	default:
		return nil, ErrBadImage
	}
	// Checked before decoding: a tiny file can declare a huge canvas.
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxAvatarSide || cfg.Height > maxAvatarSide ||
		cfg.Width*cfg.Height > maxAvatarPixels {
		return nil, ErrImageLarge
	}
	src, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, ErrBadImage
	}
	b := src.Bounds()
	side := min(b.Dx(), b.Dy())
	x0 := b.Min.X + (b.Dx()-side)/2
	y0 := b.Min.Y + (b.Dy()-side)/2
	crop := image.Rect(x0, y0, x0+side, y0+side)

	dst := image.NewNRGBA(image.Rect(0, 0, AvatarSize, AvatarSize))
	xdraw.CatmullRom.Scale(dst, dst.Bounds(), src, crop, draw.Src, nil)
	var out bytes.Buffer
	enc := png.Encoder{CompressionLevel: png.BestCompression}
	if err := enc.Encode(&out, dst); err != nil {
		return nil, err
	}
	return out.Bytes(), nil
}

// SetAvatar processes data and stores it as the user's picture. It returns the
// new avatar version.
func (s *Service) SetAvatar(ctx context.Context, userID string, data []byte) (string, error) {
	pngData, err := ProcessAvatar(data)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(pngData)
	ver := hex.EncodeToString(sum[:8])
	now := s.now().UnixMilli()
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer tx.Rollback()
	res, err := tx.ExecContext(ctx, `UPDATE users SET avatar = ?, updated_at = ? WHERE id = ?`, ver, now, userID)
	if err != nil {
		return "", err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return "", ErrNotFound
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO avatars (user_id, png, updated_at) VALUES (?, ?, ?)
		ON CONFLICT (user_id) DO UPDATE SET png = excluded.png, updated_at = excluded.updated_at`,
		userID, pngData, now); err != nil {
		return "", err
	}
	return ver, tx.Commit()
}

// RemoveAvatar deletes the user's picture.
func (s *Service) RemoveAvatar(ctx context.Context, userID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	res, err := tx.ExecContext(ctx, `UPDATE users SET avatar = '', updated_at = ? WHERE id = ?`, s.now().UnixMilli(), userID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM avatars WHERE user_id = ?`, userID); err != nil {
		return err
	}
	return tx.Commit()
}

// Avatar returns the PNG and version of an enabled user's picture, or ErrNotFound.
func (s *Service) Avatar(ctx context.Context, userID string) ([]byte, string, error) {
	var data []byte
	var ver string
	err := s.db.QueryRowContext(ctx, `SELECT a.png, u.avatar FROM avatars a JOIN users u ON u.id = a.user_id
		WHERE a.user_id = ? AND u.disabled_at IS NULL`, userID).Scan(&data, &ver)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, "", ErrNotFound
	}
	return data, ver, err
}
