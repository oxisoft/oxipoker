package accounts

import (
	"bytes"
	"encoding/binary"
	"errors"
	"hash/crc32"
	"image"
	"image/color"
	"testing"
)

// pngHeader returns a PNG that only declares its canvas: enough for
// DecodeConfig, which is all the size check may read.
func pngHeader(w, h int, depth, colorType byte) []byte {
	var b bytes.Buffer
	b.WriteString("\x89PNG\r\n\x1a\n")
	ihdr := make([]byte, 13)
	binary.BigEndian.PutUint32(ihdr[0:], uint32(w))
	binary.BigEndian.PutUint32(ihdr[4:], uint32(h))
	ihdr[8], ihdr[9] = depth, colorType
	_ = binary.Write(&b, binary.BigEndian, uint32(len(ihdr)))
	chunk := append([]byte("IHDR"), ihdr...)
	b.Write(chunk)
	_ = binary.Write(&b, binary.BigEndian, crc32.ChecksumIEEE(chunk))
	return b.Bytes()
}

func TestUploadsAreRefusedByDecodedSize(t *testing.T) {
	// 30 megapixels: fine as 8-bit RGBA (120 MiB), too much as 16-bit (240 MiB).
	if err := checkCanvas(image.Config{ColorModel: color.NRGBAModel, Width: 6000, Height: 5000}); err != nil {
		t.Fatalf("8-bit 30 MP refused: %v", err)
	}
	for name, process := range map[string]func([]byte) ([]byte, error){"avatar": ProcessAvatar, "card back": ProcessCardBack} {
		if _, err := process(pngHeader(6000, 5000, 16, 6)); !errors.Is(err, ErrImageLarge) {
			t.Errorf("%s: 16-bit 30 MP canvas: %v", name, err)
		}
	}
	if err := checkCanvas(image.Config{ColorModel: color.Gray16Model, Width: 6000, Height: 5000}); err != nil {
		t.Fatalf("16-bit gray 30 MP refused: %v", err)
	}
}
