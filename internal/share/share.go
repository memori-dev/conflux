package share

import "go.mongodb.org/mongo-driver/bson/primitive"

type key uint16

const (
	// file
	fileAccessCreate key = 1 << iota
	fileAccessRead
	fileAccessUpdate
	fileAccessDelete
	fileAccessShare

	// filestore
	fileStoreAccessRead
	fileStoreAccessUpdate
	fileStoreAccessDelete
	fileStoreAccessShare
)

type Share struct {
	SharerId   primitive.ObjectID `bson:"sharerId"`
	ReceiverId primitive.ObjectID `bson:"receiverId"`
	Key        key                `bson:"key"`
}

func (this *Metadata) idHasAccess(id primitive.ObjectID, accessType accessKey) bool {
	for _, shared := range this.Access {
		// Check that ids match
		if shared.ReceiverId != id {
			continue
		}

		// Bitwise check that the access type matches
		if shared.AccessKey&accessType == 0 {
			continue
		}

		return true
	}

	return false
}
