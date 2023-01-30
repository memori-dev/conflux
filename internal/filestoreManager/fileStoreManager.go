package filestoreManager

import (
	"conflux/internal/filestore"
	"github.com/memori-dev/mongonerics"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"sync"
)

// TODO admin: database size limit
type Metadata struct {
	Id      primitive.ObjectID `bson:"_id"`
	Name    string             `bson:"name"`
	OwnerId primitive.ObjectID `bson:"owner"`
}

// TODO layer: keep track of entire collection size - ops(create, update, delete)
// TODO layer: set(tags) - ops(create, update, delete)

type FilestoreManager struct {
	Cli         *mongonerics.Client[Metadata]
	FilestoreDB *mongo.Database

	fileStores map[string]*filestore.Filestore
	mux        sync.Mutex
}

func (this *FilestoreManager) getFileStore(basePath string) *filestore.Filestore {
	this.mux.Lock()
	defer this.mux.Unlock()

	fs, ok := this.fileStores[basePath]
	if !ok {
		fs = &filestore.Filestore{
			Cli: &mongonerics.Client[filestore.Metadata]{
				Collection: this.FilestoreDB.Collection(basePath),
			},
			Disk: &filestore.Disk{
				BasePath: basePath,
			},
		}
	}

	return fs
}
