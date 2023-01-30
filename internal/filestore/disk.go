package filestore

// TODO multiple drive handling

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

const (
	BlockLen  = 8
	BlockSize = 3

	DirFirstChar = 'a'
	DirLastChar  = DirFirstChar + BlockLen - 1

	FileFirstChar = DirFirstChar + BlockLen
	FileLastChar  = FileFirstChar + BlockLen - 1

	createIfNotExist = os.O_WRONLY | os.O_CREATE | os.O_EXCL
)

var (
	DirNameFirst = strings.Repeat(string(DirFirstChar), BlockSize)
	DirNameLast  = strings.Repeat(string(DirLastChar), BlockSize)

	FileNameFirst = strings.Repeat(string(FileFirstChar), BlockSize)
	FileNameLast  = strings.Repeat(string(FileLastChar), BlockSize)
)

func incrementName(minChar, maxChar uint8, name string) string {
	nameBytes := []byte(name)
	nameBytes[len(nameBytes)-1]++

	for i := len(nameBytes) - 1; i >= 0; i-- {
		if nameBytes[i] <= maxChar {
			break
		}

		nameBytes[i] = minChar
		if i-1 >= 0 {
			nameBytes[i-1]++
		}
	}

	return string(nameBytes)
}

func IncrementDirName(name string) string {
	return incrementName(DirFirstChar, DirLastChar, name)
}

func IncrementFileName(name string) string {
	return incrementName(FileFirstChar, FileLastChar, name)
}

func largestDirectoryWithDirectoryKey(files []os.DirEntry, path string) (*string, error) {
	var largestKey *string

	// Key window
	smallestKeyToCheck := DirNameFirst
	largestKeyToCheck := DirNameLast

	for _, file := range files {
		if !file.IsDir() {
			continue
		}

		dirName := file.Name()

		// Check if dirName is in the window
		if dirName < smallestKeyToCheck || dirName > largestKeyToCheck {
			continue
		}

		// Open the directory
		f, err := os.Open(filepath.Join(path, dirName))
		if err != nil {
			return nil, err
		}

		// Load dir files
		dirFiles, err := f.ReadDir(0)
		if err != nil {
			return nil, err
		}

		// Check if the dir has a dir
		foundDir := false
		for _, dirFile := range dirFiles {
			if !dirFile.IsDir() {
				continue
			}

			foundDir = true

			// Update the largest key if:
			// .. unset
			// .. dirName is larger
			if largestKey == nil || dirName > *largestKey {
				largestKey = &dirName
			}

			break
		}

		// Update key window
		if foundDir {
			// Smaller keys will not update the largestKey and do not need to be checked
			smallestKeyToCheck = dirName
		} else {
			// Larger keys will not have a directory and do not need to be checked
			largestKeyToCheck = dirName
		}
	}

	return largestKey, nil
}

func largestKey(files []os.DirEntry, includeFiles, includeDirs bool) string {
	var largestKey string

	for _, file := range files {
		isFile := !file.IsDir()
		// Ignore files if includesFiles is false
		if isFile && !includeFiles {
			continue
		}
		// Ignore dirs if includesDirs is false
		if !isFile && !includeDirs {
			continue
		}

		fileName := file.Name()
		if fileName < largestKey {
			continue
		}

		// Ignore fileNames out of bounds
		if isFile && (fileName < FileNameFirst || fileName > FileNameLast) {
			continue
		}
		// Ignore dirNames out of bounds
		if !isFile && (fileName < DirNameFirst || fileName > DirNameLast) {
			continue
		}

		largestKey = fileName
	}

	return largestKey
}

type Disk struct {
	BasePath string

	// Current path
	dirPath  []string
	fileName string
	mux      sync.Mutex
}

func (this *Disk) path() []string {
	path := make([]string, 1+len(this.dirPath)+1)
	path[0] = this.BasePath
	for i := 0; i < len(this.dirPath); i++ {
		path[i+1] = this.dirPath[i]
	}
	path[len(path)-1] = this.fileName

	return path
}

func (this *Disk) loadLastPath() error {
	this.dirPath = []string{}
	this.fileName = ""

	for {
		fullPath := filepath.Join(append([]string{this.BasePath}, this.dirPath...)...)

		// Mkdir if it does not exist
		if _, err := os.Stat(fullPath); os.IsNotExist(err) {
			if err := os.MkdirAll(fullPath, os.ModePerm); err != nil {
				return err
			}
		}

		// Open the directory
		f, err := os.Open(fullPath)
		if err != nil {
			return err
		}

		// Check that the file is a directory
		fi, err := f.Stat()
		if err != nil {
			return err
		}
		if !fi.IsDir() {
			return errors.New("path was not a directory: " + fullPath)
		}

		// Load all of the dir contents
		files, err := f.ReadDir(0)
		if err != nil {
			return err
		}

		// Check for the largest directory with a directory
		// Update the path and retry if a key is found
		if key, err := largestDirectoryWithDirectoryKey(files, fullPath); err != nil {
			return err
		} else if key != nil {
			this.dirPath = append(this.dirPath, *key)
			continue
		}

		// Get the largest directory key
		// Update the path and retry if a key is found
		if key := largestKey(files, false, true); key != "" {
			this.dirPath = append(this.dirPath, key)
			continue
		}

		// Set the largest file key
		this.fileName = largestKey(files, true, false)

		return nil
	}
}

func (this *Disk) loadNextPath() {
	willOverflow := this.fileName == FileNameLast

	// Increment the file name
	if this.fileName == "" {
		this.fileName = FileNameFirst
	} else {
		this.fileName = IncrementFileName(this.fileName)
	}

	// Exit if there is no overflow to handle
	if !willOverflow {
		return
	}

	// This always increments the the last directory
	// Handle directory overflow
	isCompleteRollover := true
	for i := len(this.dirPath) - 1; i >= 0; i-- {
		willOverflow = this.dirPath[i] == DirNameLast
		this.dirPath[i] = IncrementDirName(this.dirPath[i])

		// No more overflows can occur if the current path did not overflow
		if !willOverflow {
			isCompleteRollover = false
			break
		}
	}

	if isCompleteRollover {
		for i := 0; i < len(this.dirPath); i++ {
			this.dirPath[i] = DirNameFirst
		}

		this.dirPath = append(this.dirPath, DirNameFirst)
	}
}

func (this *Disk) CreateFile() ([]string, *os.File, error) {
	this.mux.Lock()
	defer this.mux.Unlock()

	// Load the latest path if it is not set
	if this.dirPath == nil && this.fileName == "" {
		if err := this.loadLastPath(); err != nil {
			return nil, nil, err
		}
	}

	for {
		this.loadNextPath()
		path := this.path()

		// TODO fix perms
		file, err := os.OpenFile(filepath.Join(path...), createIfNotExist, 0666)
		// Check if the file exists
		if os.IsExist(err) {
			if err := this.loadLastPath(); err != nil {
				return nil, nil, err
			}

			continue
		}

		return path, file, nil
	}
}

func (this *Disk) CreatePath() ([]string, error) {
	this.mux.Lock()
	defer this.mux.Unlock()

	// Load the latest path if it is not set
	if this.dirPath == nil && this.fileName == "" {
		if err := this.loadLastPath(); err != nil {
			return nil, err
		}
	}

	for {
		this.loadNextPath()

		path := this.path()

		// Check if the file exists
		if _, err := os.Stat(filepath.Join(path...)); !os.IsNotExist(err) {
			if err := this.loadLastPath(); err != nil {
				return nil, err
			}

			continue
		}

		return this.path(), nil
	}
}

func (this *Disk) CreatePathUnsafeNoFileCheck() ([]string, error) {
	this.mux.Lock()
	defer this.mux.Unlock()

	// Load the latest path if it is not set
	if this.dirPath == nil && this.fileName == "" {
		if err := this.loadLastPath(); err != nil {
			return nil, err
		}
	}

	this.loadNextPath()
	return this.path(), nil
}

// TODO read

// TODO update

// TODO delete
