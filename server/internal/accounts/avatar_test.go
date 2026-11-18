package accounts

import (
	"bytes"
	"context"
	"encoding/binary"
	"errors"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"testing"
)

// testImage is red in its left third and blue elsewhere: a centre crop of a
// wide picture must come out all blue.
func testImage(w, h int) image.Image {
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			c := color.RGBA{0, 0, 255, 255}
			if x < w/3 {
				c = color.RGBA{255, 0, 0, 255}
			}
			img.Set(x, y, c)
		}
	}
	return img
}

func TestProcessAvatar(t *testing.T) {
	var jp bytes.Buffer
	if err := jpeg.Encode(&jp, testImage(900, 300), nil); err != nil {
		t.Fatal(err)
	}
	out, err := ProcessAvatar(jp.Bytes())
	if err != nil {
		t.Fatal(err)
	}
	img, format, err := image.Decode(bytes.NewReader(out))
	if err != nil || format != "png" {
		t.Fatalf("output %q %v", format, err)
	}
	if b := img.Bounds(); b.Dx() != AvatarSize || b.Dy() != AvatarSize {
		t.Fatalf("size %v", b)
	}
	if r, _, bl, _ := img.At(5, 128).RGBA(); r > 0x3000 || bl < 0xc000 {
		t.Fatalf("crop is not the centre: r=%x b=%x", r, bl)
	}

	var small bytes.Buffer
	_ = png.Encode(&small, testImage(40, 60))
	if out, err := ProcessAvatar(small.Bytes()); err != nil || len(out) == 0 {
		t.Fatalf("small image: %v", err)
	}

	for name, data := range map[string][]byte{
		"svg":   []byte(`<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>`),
		"text":  []byte("hello"),
		"empty": nil,
	} {
		if _, err := ProcessAvatar(data); !errors.Is(err, ErrBadImage) {
			t.Errorf("%s: %v", name, err)
		}
	}
}

func TestProcessAvatarRefusesHugeCanvas(t *testing.T) {
	// A tiny PNG whose header declares 20000 x 20000 pixels is refused before
	// any pixel is decoded (IHDR width and height sit at bytes 16..23).
	var buf bytes.Buffer
	_ = png.Encode(&buf, image.NewGray(image.Rect(0, 0, 1, 1)))
	b := buf.Bytes()
	binary.BigEndian.PutUint32(b[16:], 20000)
	binary.BigEndian.PutUint32(b[20:], 20000)
	if _, err := ProcessAvatar(b); !errors.Is(err, ErrImageLarge) && !errors.Is(err, ErrBadImage) {
		t.Fatalf("huge canvas: %v", err)
	}
}

func TestAvatarStore(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	u, err := s.CreateUser(ctx, NewUser{Username: "sam", Password: "sams password"})
	if err != nil {
		t.Fatal(err)
	}
	if _, _, err := s.Avatar(ctx, u.ID); !errors.Is(err, ErrNotFound) {
		t.Fatalf("no avatar yet: %v", err)
	}
	var buf bytes.Buffer
	_ = png.Encode(&buf, testImage(300, 300))
	ver, err := s.SetAvatar(ctx, u.ID, buf.Bytes())
	if err != nil || len(ver) != 16 {
		t.Fatalf("set: %q %v", ver, err)
	}
	got, gotVer, err := s.Avatar(ctx, u.ID)
	if err != nil || gotVer != ver || len(got) == 0 {
		t.Fatalf("get: %q %v", gotVer, err)
	}
	if again, _ := s.UserByID(ctx, u.ID); again.Avatar != ver {
		t.Fatalf("user.avatar = %q", again.Avatar)
	}
	if err := s.RemoveAvatar(ctx, u.ID); err != nil {
		t.Fatal(err)
	}
	if _, _, err := s.Avatar(ctx, u.ID); !errors.Is(err, ErrNotFound) {
		t.Fatalf("after remove: %v", err)
	}
	if _, err := s.SetAvatar(ctx, "nobody", buf.Bytes()); !errors.Is(err, ErrNotFound) {
		t.Fatalf("unknown user: %v", err)
	}
}
