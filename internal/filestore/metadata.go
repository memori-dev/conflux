package filestore

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TODO versioning
type Metadata struct {
	Id       primitive.ObjectID `bson:"_id"`
	Name     string             `bson:"name"`
	Path     []string           `bson:"path"`
	MimeType string             `bson:"mimeType"`
	Tags     []string           `bson:"tags"`
	Size     int64              `bson:"size"`
	Hash     []byte             `bson:"hash"`
	Created  int64              `bson:"created"`
	Modified int64              `bson:"modified"`
	Accessed int64              `bson:"accessed"`
}
