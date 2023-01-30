package avatar

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sync"
)

var mux = &sync.Mutex{}

var b64Prefix = []byte("iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAA")

var _, b, _, _ = runtime.Caller(0)
var basepath = filepath.Join(filepath.Dir(b), "avatars.txt")

func popLine(f *os.File) ([]byte, error) {
	fi, err := f.Stat()
	if err != nil {
		return nil, err
	}
	buf := bytes.NewBuffer(make([]byte, 0, fi.Size()))

	_, err = f.Seek(0, io.SeekStart)
	if err != nil {
		return nil, err
	}
	_, err = io.Copy(buf, f)
	if err != nil {
		return nil, err
	}

	line, err := buf.ReadBytes('\n')
	if err != nil && err != io.EOF {
		return nil, err
	}

	_, err = f.Seek(0, io.SeekStart)
	if err != nil {
		return nil, err
	}
	nw, err := io.Copy(f, buf)
	if err != nil {
		return nil, err
	}
	err = f.Truncate(nw)
	if err != nil {
		return nil, err
	}
	err = f.Sync()
	if err != nil {
		return nil, err
	}

	_, err = f.Seek(0, io.SeekStart)
	if err != nil {
		return nil, err
	}
	return line, nil
}

func GetAvatar() ([]byte, error) {
	mux.Lock()
	defer mux.Unlock()

	f, err := os.OpenFile(basepath, os.O_RDWR, 0644)
	if err != nil {
		return nil, err
	}
	defer func() {
		_ = f.Close()
	}()

	b64, err := popLine(f)
	if err != nil {
		return nil, err
	}

	outb64 := bytes.TrimSpace(bytes.Join([][]byte{b64Prefix, b64}, []byte{}))
	return outb64, nil
}
