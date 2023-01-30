package filestoreManager

//var ErrUnauthorized = errors.New("unauthorized")
//
//func (this *FilestoreManager) CreateFile(profileId, collectionId primitive.ObjectID, payload *filestore.CreatePayload) (*filestore.Metadata, *mongo.InsertOneResult, error) {
//	if err := this.isAuthorizedFileAccess(profileId, collectionId, fileAccessCreate); err != nil {
//		return nil, nil, err
//	}
//
//	// TODO basePath is the metadata id hex
//
//	return this.getFileStore().Create(payload)
//}
//
//func (this *FilestoreManager) ReadFile(profileId, collectionId primitive.ObjectID, filter interface{}) ([]*filestore.Metadata, error) {
//	if err := this.isAuthorizedFileAccess(profileId, collectionId, fileAccessRead); err != nil {
//		return nil, err
//	}
//
//	return this.getFileStore().Read(collectionId.Hex(), filter)
//}
//
//func (this *FilestoreManager) ReadOneFile(profileId, collectionId primitive.ObjectID, filter interface{}) (*filestore.Metadata, error) {
//	if err := this.isAuthorizedFileAccess(profileId, collectionId, fileAccessRead); err != nil {
//		return nil, err
//	}
//
//	return this.getFileStore().ReadOne(collectionId.Hex(), filter)
//
//}

// TODO updateFile(s)

// TODO deleteFile(s)
