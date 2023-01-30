package storage

import (
	"conflux/internal/filestoreManager"
	"conflux/internal/handlers/profile"
	"github.com/gin-gonic/gin"
	"net/http"
)

type Handler struct {
	FileStoreManager *filestoreManager.FilestoreManager
	Auth             *profile.Authenticator
}

func (this *Handler) AddHandlersTo(e *gin.Engine) {
	storageGroup := e.Group("storage")

	//fileGroup := storageGroup.Group("file")

	filestoreGroup := storageGroup.Group("filestore")
	filestoreGroup.Handle(http.MethodPost, "create", this.filestoreCreate)
	filestoreGroup.Handle(http.MethodGet, "read", this.filestoreRead)
}
