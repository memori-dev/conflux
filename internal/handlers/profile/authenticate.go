package profile

import (
	"errors"
	"github.com/gin-gonic/gin"
	"net/http"
)

var ErrInvalidPassword = errors.New("invalid password")

type loginPayload struct {
	Name     string `json:"Name"`
	Password string `json:"Password"`
}

func (this *Authenticator) login(ctx *gin.Context) {
	payload := new(loginPayload)
	if err := ctx.BindJSON(payload); err != nil {
		ctx.String(http.StatusBadRequest, "Invalid payload")
		return
	}

	if err := this.authenticate(ctx, payload.Name, payload.Password); err != nil {
		ctx.String(http.StatusUnauthorized, err.Error())
	}
}

type signupPayload struct {
	Name            string `json:"Name"`
	Password        string `json:"Password"`
	PasswordEnabled bool   `json:"PasswordEnabled"`
}

func (this *Authenticator) signup(ctx *gin.Context) {
	var err error

	// Unmarshal credentials
	payload := new(signupPayload)
	err = ctx.BindJSON(payload)
	if err != nil {
		ctx.String(http.StatusBadRequest, "Invalid payload")
		return
	}

	// Create profile from credentials
	p, err := newProfile(payload.Name, payload.Password, payload.PasswordEnabled)
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}

	// Create profile in db
	err = this.db.create(p)
	if err != nil {
		if err == errProfileExists {
			ctx.String(http.StatusConflict, "Name is already taken")
		} else {
			ctx.String(http.StatusInternalServerError, err.Error())
		}

		return
	}

	err = this.authenticate(ctx, payload.Name, payload.Password)
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}

	ctx.Status(http.StatusOK)
}

type validatePayload struct {
	Name string
}

func (this *Authenticator) validate(ctx *gin.Context) {
	auth, ok := this.ParseAuthentication(ctx)
	if !ok {
		return
	}

	// Unmarshal credentials
	payload := new(validatePayload)
	if err := ctx.BindJSON(payload); err != nil {
		ctx.Status(http.StatusBadRequest)
		return
	}

	// Read profile from db
	// TODO only expire cookie if profile not exist error
	p, err := this.db.readOne(idLookupFilter(auth.ProfileId))
	if err != nil {
		expireCookie(ctx)
		ctx.Status(http.StatusUnauthorized)
		return
	}

	// Validate name matches
	if p.Name != payload.Name {
		ctx.Status(http.StatusUnauthorized)
		return
	}

	ctx.Status(http.StatusOK)
}
