package storage

import (
	"github.com/gin-gonic/gin"
	"strconv"
)

func getLastModified(ginCtx *gin.Context) (int64, error) {
	str, _ := ginCtx.GetPostForm("lastModified")
	lastModified, err := strconv.ParseInt(str, 10, 64)
	if err != nil {
		return 0, err
	}

	return lastModified, nil
}

//func (this *Handler) create(ctx *gin.Context) {
//	fileHdr, err := ctx.FormFile("file")
//	if err != nil {
//		ctx.Status(http.StatusBadRequest)
//		return
//	}
//
//	// Get a reader for the uploaded data
//	fileReader, err := fileHdr.Open()
//	if err != nil {
//		ctx.Status(http.StatusBadRequest)
//		return
//	}
//	defer func() {
//		err = fileReader.Close()
//	}()
//
//	// set in db
//	lastModified, err := getLastModified(ctx)
//	if err != nil {
//		ctx.Status(http.StatusBadRequest)
//		return
//	}
//
//	// TODO compare fileHdr.Size and returned
//
//	metadata, res, err := this.FileStoreManager.CreateFile(profile.GetProfileId(ctx), &filestore.CreatePayload{
//		CollectionName: profile.GetProfileId(ctx),
//		FileName:       fileHdr.Filename,
//		FileStream:     fileReader,
//		Created:        lastModified,
//		Modified:       lastModified,
//		Accessed:       lastModified,
//	})
//	if err != nil {
//		ctx.Status(http.StatusInternalServerError)
//		return
//	}
//
//	ctx.Status(http.StatusOK)
//}

// TODO filters
//func (this *Handler) read(ctx *gin.Context) {
//	files, err := this.FileStoreManager.
//	(profile.GetProfileId(ctx), nil)
//	if err != nil {
//		ctx.Status(http.StatusInternalServerError)
//		return
//	}
//
//	// Remove filepath
//	for i := 0; i < len(files); i++ {
//		files[i].Filepath = nil
//	}
//
//	ctx.JSON(200, files)
//}

// TODO update

// TODO delete

// TODO share
