package filestore_test

import (
	"conflux/internal/filestore"
	"errors"
	"math"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
)

var dirExponentBase = math.Pow(filestore.BlockLen, filestore.BlockSize)

func testIncrementName(t *testing.T, firstName string, increment func(string) string) {
	// Test increases every time
	var lastName string
	for i := 0; i < int(dirExponentBase); i++ {
		var name string
		if lastName == "" {
			name = firstName
		} else {
			name = increment(lastName)
		}

		// Name should be larger
		if name <= lastName {
			t.Fatalf("larger name: previous %s, received %s", lastName, name)
		}

		lastName = name
	}

	// Test overflow
	name := increment(lastName)
	if name != firstName {
		t.Fatalf("overflow: expected %s, received %s", firstName, name)
	}
}

func TestIncrementFileName(t *testing.T) {
	testIncrementName(t, filestore.FileNameFirst, filestore.IncrementFileName)
}

func TestIncrementDirName(t *testing.T) {
	testIncrementName(t, filestore.DirNameFirst, filestore.IncrementDirName)
}

func removeTestDir(t *testing.T, testingDir string) {
	if err := os.RemoveAll(testingDir); err != nil && !errors.Is(err, os.ErrNotExist) {
		t.Fatal("failed to remove the testing directory", err)
	}
}

func incrementFileNameXTimes(name string, x int) string {
	for i := 0; i < x; i++ {
		name = filestore.IncrementFileName(name)
	}

	return name
}

func mustGetPath(t *testing.T, pathTracker *filestore.Disk) []string {
	path, err := pathTracker.CreatePath()
	if err != nil {
		t.Fatal("failed GetPath", err)
	}

	return path
}

func mustCreateEmptyFile(t *testing.T, path string) {
	file, err := os.Create(path)
	if err != nil {
		t.Fatal("failed Create", err)
	}

	if err := file.Close(); err != nil {
		t.Fatal("failed Close", err)
	}
}

func testPathTrackerIncrement(t *testing.T, basePath string) {
	removeTestDir(t, basePath)
	pathTracker := &filestore.Disk{BasePath: basePath}

	lastPathStr := ""
	for power := float64(0); power < 3; power++ {
		expectedPathLen := filestore.BlockSize * int(power+1)

		// Each block is represented by [dirExponentBase^power, dirExponentBase^(power+1)]
		end := int(math.Pow(dirExponentBase, power+1))
		for i := 0; i < end; i++ {
			// NoFileCheck is used to speed this up
			// This will not cause any issues in this controlled env
			path, err := pathTracker.CreatePathUnsafeNoFileCheck()
			if err != nil {
				t.Fatal("failed GetPathUnsafeNoFileCheck", err)
			}

			pathStr := strings.Join(path[1:], "")

			// length should be blockSize * (power+1)
			if len(pathStr) != expectedPathLen {
				t.Fatalf("path length: expected %d, received %d, iter %d", expectedPathLen, len(pathStr), i)
			}

			// The path string should always be larger
			// Else it should be longer; this happens on a complete rollover, where the directory path is one deeper
			if len(pathStr) < len(lastPathStr) {
				t.Fatalf("shorter path length: expected min %d, received %d", len(lastPathStr), len(pathStr))
			}
			if pathStr <= lastPathStr && len(pathStr) <= len(lastPathStr) {
				t.Fatalf("path was not incremented: previous %s, received %s", lastPathStr, pathStr)
			}

			lastPathStr = pathStr
		}
	}
}

func testLoadLastPath(t *testing.T, basePath string) {
	type filePathToSet struct {
		dir      string
		fileName string
	}

	tests := []struct {
		filePathsToSet []filePathToSet
		nextPath       string
	}{
		// /empty
		// The first path should just be FileNameFirst
		{
			nextPath: filestore.FileNameFirst,
		},
		// /File(s)
		{
			filePathsToSet: []filePathToSet{
				{fileName: filestore.FileNameFirst},
			},
			nextPath: filestore.IncrementFileName(filestore.FileNameFirst),
		},
		{
			filePathsToSet: []filePathToSet{
				{fileName: filestore.FileNameFirst},
				{fileName: incrementFileNameXTimes(filestore.FileNameFirst, filestore.BlockLen)},
			},
			nextPath: incrementFileNameXTimes(filestore.FileNameFirst, filestore.BlockLen+1),
		},
		// /File name out of bounds
		{
			filePathsToSet: []filePathToSet{
				{fileName: strings.Repeat(string(filestore.FileLastChar+1), filestore.BlockSize)},
				{fileName: strings.Repeat(string(filestore.FileLastChar*2), filestore.BlockSize)},
			},
			nextPath: filestore.FileNameFirst,
		},
		// /Dir/empty
		{
			filePathsToSet: []filePathToSet{
				{dir: filestore.DirNameFirst},
			},
			nextPath: filepath.Join(filestore.DirNameFirst, filestore.FileNameFirst),
		},
		{
			filePathsToSet: []filePathToSet{
				{dir: filestore.DirNameLast},
			},
			nextPath: filepath.Join(filestore.DirNameLast, filestore.FileNameFirst),
		},
		// /Dir/file
		{
			filePathsToSet: []filePathToSet{
				{
					dir:      filestore.DirNameFirst,
					fileName: filestore.FileNameFirst,
				},
			},
			nextPath: filepath.Join(filestore.DirNameFirst, filestore.IncrementFileName(filestore.FileNameFirst)),
		},
		// Dir/Dir/empty
		{
			filePathsToSet: []filePathToSet{
				{
					dir: filepath.Join(filestore.DirNameFirst, filestore.DirNameFirst),
				},
			},
			nextPath: filepath.Join(filestore.DirNameFirst, filestore.DirNameFirst, filestore.FileNameFirst),
		},
		// Dir/Dir/File
		{
			filePathsToSet: []filePathToSet{
				{
					dir:      filepath.Join(filestore.DirNameFirst, filestore.DirNameFirst),
					fileName: filestore.FileNameFirst,
				},
			},
			nextPath: filepath.Join(filestore.DirNameFirst, filestore.DirNameFirst, filestore.IncrementFileName(filestore.FileNameFirst)),
		},
	}

	for i, test := range tests {
		removeTestDir(t, basePath)

		// Set files
		for _, path := range test.filePathsToSet {
			// mkdir
			var fullPath string
			if path.dir != "" {
				fullPath = filepath.Join(basePath, path.dir)
			} else {
				fullPath = basePath
			}
			err := os.MkdirAll(fullPath, os.ModePerm)
			if err != nil {
				t.Fatal("failed MkdirAll", err)
			}

			// create file
			if path.fileName != "" {
				if path.dir != "" {
					mustCreateEmptyFile(t, filepath.Join(basePath, path.dir, path.fileName))
				} else {
					mustCreateEmptyFile(t, filepath.Join(basePath, path.fileName))
				}
			}
		}

		// Build PathTracker
		pathTracker := &filestore.Disk{BasePath: basePath}
		path := mustGetPath(t, pathTracker)

		// Test GetPath
		if filepath.Join(path[1:]...) != test.nextPath {
			t.Fatalf("next path: expected %s, received %s, index %d", test.nextPath, strings.Join(path[1:], ""), i)
		}
	}
}

func testConcurrency(t *testing.T, basePath string) {
	removeTestDir(t, basePath)
	pathTracker := &filestore.Disk{BasePath: basePath}

	wg := &sync.WaitGroup{}

	foundPaths := make(map[string]struct{})
	var errs []error
	mux := sync.Mutex{}

	checkForDuplicatePath := func(pathStr string) error {
		mux.Lock()
		defer mux.Unlock()

		_, ok := foundPaths[pathStr]
		if ok {
			return errors.New("found duplicate: " + pathStr)
		}

		foundPaths[pathStr] = struct{}{}

		return nil
	}

	getPath := func() error {
		defer wg.Done()

		path, err := pathTracker.CreatePath()
		if err != nil {
			return err
		}

		if err := checkForDuplicatePath(strings.Join(path[1:], "")); err != nil {
			return err
		}

		return nil
	}

	for i := 0; i < int(dirExponentBase); i++ {
		wg.Add(1)

		go func() {
			err := getPath()
			if err != nil {
				mux.Lock()
				errs = append(errs, err)
				mux.Unlock()
			}
		}()
	}

	wg.Wait()

	for _, err := range errs {
		t.Fatal(err)
	}
}

func testExternalCreatedFile(t *testing.T, basePath string) {
	for _, count := range []int{0, 1, 5, 10, 25} {
		removeTestDir(t, basePath)
		pathTracker := &filestore.Disk{BasePath: basePath}

		path := mustGetPath(t, pathTracker)
		fileName := path[1]

		// fileName must be the FileNameFirst
		if fileName != filestore.FileNameFirst {
			t.Fatalf("first file: expected %s, received %s", filestore.FileNameFirst, fileName)
		}

		// Create count number of files
		for i := 0; i < count; i++ {
			mustCreateEmptyFile(t, filepath.Join(basePath, incrementFileNameXTimes(fileName, i+1)))
		}

		path = mustGetPath(t, pathTracker)
		fileName = path[1]

		// fileName should be count + 1 (+1 for the second GetPath)
		if fileName != incrementFileNameXTimes(filestore.FileNameFirst, count+1) {
			t.Fatalf("next file: expected %s, received %s", incrementFileNameXTimes(filestore.FileNameFirst, 2), fileName)
		}
	}
}

// TODO finalize tests
// TODO test NewFile
func TestPathTracker_GetPath(t *testing.T) {
	_, filename, _, ok := runtime.Caller(1)
	if !ok {
		t.Fatal("failed to get the filename")
	}

	currentPath := filepath.SplitList(filename)
	currentPath[len(currentPath)-1] = "testing"
	testingDir := filepath.Join(currentPath...)

	testPathTrackerIncrement(t, testingDir)
	testLoadLastPath(t, testingDir)
	testConcurrency(t, testingDir)
	testExternalCreatedFile(t, testingDir)

	removeTestDir(t, testingDir)
}
