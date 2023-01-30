package filestoreManager

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

func (this *FilestoreManager) FileStoreCreate(owner primitive.ObjectID, name string) (*mongo.InsertOneResult, error) {
	return this.Cli.Create(&Metadata{
		Id:      primitive.NewObjectID(),
		Name:    name,
		OwnerId: owner,
	})
}

func (this *FilestoreManager) FileStoreRead(filter interface{}) ([]*Metadata, error) {
	return this.Cli.Read(filter)
}

func (this *FilestoreManager) ReadOneFileStore(filter interface{}) (*Metadata, error) {
	return this.Cli.ReadOne(filter)
}

// TODO updateFileStore

// TODO deleteFileStore

// TODO shareFileStore
