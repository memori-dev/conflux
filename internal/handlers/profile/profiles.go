package profile

import (
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"net/http"
)

type profileResponse struct {
	ImageB64        []byte
	Name            string
	PasswordEnabled bool
}

func (this *Authenticator) self(ctx *gin.Context) {
	// The filter is the cookie's profileId
	auth, ok := this.ParseAuthentication(ctx)
	if !ok {
		return
	}

	profile, err := this.db.readOne(bson.M{"_id": auth.ProfileId})
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}

	ctx.JSON(200, &profileResponse{
		ImageB64:        profile.ImageB64,
		Name:            profile.Name,
		PasswordEnabled: profile.PasswordEnabled,
	})
}

func (this *Authenticator) profile(ctx *gin.Context) {
	payload := new(interface{})
	if err := ctx.BindJSON(&payload); err != nil {
		ctx.Status(http.StatusBadRequest)
		return
	}

	profile, err := this.db.readOne(payload)
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}

	ctx.JSON(200, &profileResponse{
		ImageB64:        profile.ImageB64,
		Name:            profile.Name,
		PasswordEnabled: profile.PasswordEnabled,
	})
}

// TODO add password protection to the users page, 400 on unauth'd
func (this *Authenticator) profiles(ctx *gin.Context) {
	payload := new(interface{})
	if err := ctx.BindJSON(&payload); err != nil {
		ctx.Status(http.StatusBadRequest)
		return
	}

	profiles, err := this.db.read(-1, payload)
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}

	response := make([]*profileResponse, len(profiles))
	for i := 0; i < len(profiles); i++ {
		response[i] = &profileResponse{
			ImageB64:        profiles[i].ImageB64,
			Name:            profiles[i].Name,
			PasswordEnabled: profiles[i].PasswordEnabled,
		}
	}

	ctx.JSON(200, response)
}
