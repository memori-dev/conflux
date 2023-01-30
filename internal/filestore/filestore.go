package filestore

import (
	"bufio"
	"crypto/sha256"
	"github.com/memori-dev/mongonerics"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"io"
	"net/http"
)

// TODO FileStore: defrag removed files
// TODO FileStore: ghost files (files on disk, but not in mongo)
// TODO FileStore.create: file perms
// TODO FileStore.create: restrict length
// TODO FileStore.create: encryption (client side?)
// TODO FileStore.read: decryption

// TODO make the database functionality passed in

type Filestore struct {
	Cli  *mongonerics.Client[Metadata]
	Disk *Disk
}

type CreatePayload struct {
	Name       string
	Tags       []string
	FileStream io.Reader
	Created    int64
	Modified   int64
	Accessed   int64
}

func (this *Filestore) Create(payload *CreatePayload) (*Metadata, *mongo.InsertOneResult, error) {
	// Get file and path
	path, file, err := this.Disk.CreateFile()
	if err != nil {
		return nil, nil, err
	}

	// Tee for disk & hash
	sha := sha256.New()
	tee := io.TeeReader(payload.FileStream, sha)

	// Write to disk
	// TODO test buffer and unbuffered
	wr := bufio.NewWriter(file)
	written, err := io.Copy(wr, tee)
	if err != nil {
		return nil, nil, err
	}
	if err := wr.Flush(); err != nil {
		return nil, nil, err
	}

	// Close file
	if err := file.Close(); err != nil {
		return nil, nil, err
	}

	// Get mimeType
	// TODO will this work
	buffer := make([]byte, 512)
	if _, err := file.Read(buffer); err != nil {
		return nil, nil, err
	}
	contentType := http.DetectContentType(buffer)

	meta := &Metadata{
		Id:       primitive.NewObjectID(),
		Name:     payload.Name,
		Path:     path,
		MimeType: contentType,
		Tags:     payload.Tags,
		Size:     written,
		Hash:     sha.Sum(nil),
		Created:  payload.Created,
		Modified: payload.Modified,
		Accessed: payload.Accessed,
	}

	res, err := this.Cli.Create(meta)
	if err != nil {
		// TODO delete from disk on failure
		return nil, nil, err
	}

	return meta, res, nil
}

func (this *Filestore) Read(filter interface{}) ([]*Metadata, error) {
	return this.Cli.Read(filter)
}

func (this *Filestore) ReadOne(filter interface{}) (*Metadata, error) {
	return this.Cli.ReadOne(filter)
}

// TODO
func (this *Filestore) Update(fileId primitive.ObjectID, meta *Metadata) error {
	//ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	//defer cancel()
	//
	//res := this.getCollectionCli(basePath).FindOneAndUpdate(ctx, bson.M{"_id": primitiveId}, meta)
	//if res.Err() != nil {
	//	return res.Err()
	//}

	return nil
}

// TODO delete
//func (this *FileStore) Delete() error {
//
//}
