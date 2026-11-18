package secret

import (
	"bytes"
	"encoding/base64"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestGeneratedThenPersisted(t *testing.T) {
	dir := t.TempDir()
	s1, src, err := Load(dir, "")
	if err != nil || src != FromGenerated {
		t.Fatalf("first load: %v %v", src, err)
	}
	st, err := os.Stat(filepath.Join(dir, FileName))
	if err != nil {
		t.Fatal(err)
	}
	if runtime.GOOS != "windows" && st.Mode().Perm() != 0o600 {
		t.Fatalf("mode = %v", st.Mode().Perm())
	}
	s2, src, err := Load(dir, "")
	if err != nil || src != FromFile {
		t.Fatalf("second load: %v %v", src, err)
	}
	if !bytes.Equal(s1.Key("session"), s2.Key("session")) {
		t.Fatal("secret changed between starts")
	}
}

func TestEnvWins(t *testing.T) {
	dir := t.TempDir()
	env := strings.Repeat("ab", 32)
	s, src, err := Load(dir, env)
	if err != nil || src != FromEnv {
		t.Fatalf("%v %v", src, err)
	}
	if _, err := os.Stat(filepath.Join(dir, FileName)); !os.IsNotExist(err) {
		t.Fatal("env secret must not create a file")
	}
	b64 := base64.StdEncoding.EncodeToString(bytes.Repeat([]byte{0xab}, 32))
	s2, _, err := Load(dir, b64)
	if err != nil || !bytes.Equal(s.Key("x"), s2.Key("x")) {
		t.Fatalf("hex and base64 of the same bytes differ: %v", err)
	}
}

func TestRejectsShortOrGarbage(t *testing.T) {
	for _, v := range []string{"abcd", "not a secret!!", base64.StdEncoding.EncodeToString(make([]byte, 16))} {
		if _, _, err := Load(t.TempDir(), v); err == nil {
			t.Fatalf("accepted %q", v)
		}
	}
	dir := t.TempDir()
	_ = os.WriteFile(filepath.Join(dir, FileName), []byte("short\n"), 0o600)
	if _, _, err := Load(dir, ""); err == nil {
		t.Fatal("accepted a corrupt key file")
	}
}

func TestPurposeKeysDiffer(t *testing.T) {
	s, _, _ := Load(t.TempDir(), "")
	a, b := s.Key("session"), s.Key("invite")
	if len(a) != 32 || bytes.Equal(a, b) {
		t.Fatal("purpose keys must be 32 bytes and distinct")
	}
	if bytes.Equal(a, s.root) {
		t.Fatal("derived key equals root")
	}
}
