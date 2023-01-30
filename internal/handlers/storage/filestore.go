package storage

import (
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"net/http"
)

type filestoreCreatePayload struct {
	Name string `json:"name"`
}

func (this *Handler) filestoreCreate(ctx *gin.Context) {
	auth, ok := this.Auth.ParseAuthentication(ctx)
	if !ok {
		return
	}

	payload := new(filestoreCreatePayload)
	if err := ctx.Bind(payload); err != nil {
		ctx.Status(http.StatusBadRequest)
		return
	}

	res, err := this.FileStoreManager.FileStoreCreate(auth.ProfileId, payload.Name)
	if err != nil {
		ctx.Status(http.StatusInternalServerError)
		return
	}

	ctx.JSON(http.StatusOK, res)
}

func (this *Handler) filestoreRead(ctx *gin.Context) {
	auth, ok := this.Auth.ParseAuthentication(ctx)
	if !ok {
		return
	}

	// TODO share

	filestoreMetas, err := this.FileStoreManager.FileStoreRead(bson.M{"owner": auth.ProfileId})
	if err != nil {
		ctx.Status(http.StatusInternalServerError)
		return
	}

	ctx.JSON(http.StatusOK, filestoreMetas)
}

// TODO update

// TODO delete

// TODO share
