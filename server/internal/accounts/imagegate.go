package accounts

import (
	"bytes"
	"image"
	"image/color"
)

// Decoded pictures live in memory as raw pixels: a 40 megapixel upload takes
// 160 MiB as 8-bit RGBA and twice that as 16-bit PNG, from a file of a few
// kilobytes. The canvas check counts bytes, not only pixels, and at most two
// uploads are decoded at the same time, so parallel uploads cannot exhaust
// memory (F7).
const maxDecodedBytes = 160 << 20

var decodeGate = make(chan struct{}, 2)

func bytesPerPixel(m color.Model) int {
	switch m {
	case color.RGBA64Model, color.NRGBA64Model:
		return 8
	case color.Gray16Model, color.Alpha16Model:
		return 2
	case color.GrayModel, color.AlphaModel:
		return 1
	}
	if _, ok := m.(color.Palette); ok {
		return 1
	}
	return 4
}

// checkCanvas refuses a declared canvas that is empty or would decode to more
// than the limits, before any pixel is decoded.
func checkCanvas(cfg image.Config) error {
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxAvatarSide || cfg.Height > maxAvatarSide ||
		cfg.Width*cfg.Height > maxAvatarPixels || cfg.Width*cfg.Height*bytesPerPixel(cfg.ColorModel) > maxDecodedBytes {
		return ErrImageLarge
	}
	return nil
}

func decodeImage(data []byte) (image.Image, error) {
	decodeGate <- struct{}{}
	defer func() { <-decodeGate }()
	src, _, err := image.Decode(bytes.NewReader(data))
	return src, err
}
