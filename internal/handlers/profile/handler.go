package profile

import (
	"github.com/gin-gonic/gin"
	"github.com/memori-dev/auth"
	"github.com/memori-dev/golue"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
)

const (
	cookieKey = "auth"
	// two weeks
	cookieMaxAge = 60 * 60 * 24 * 14
)

func expireCookie(ctx *gin.Context) {
	ctx.SetCookie(cookieKey, "", -1, "/", "", true, false)
}

func GetProfileId(ctx *gin.Context) string {
	return ctx.GetString(cookieKey)
}

type Authenticator struct {
	db   *database
	auth *auth.Authenticator
}

func (this *Authenticator) authenticate(ctx *gin.Context, name, password string) error {
	// Read profile from db
	p, err := this.db.readOne(nameLookupFilter(name))
	if err != nil {
		return err
	}

	// Validate pass
	if !p.validatePassword(password) {
		return ErrInvalidPassword
	}

	// Authenticate profile
	token, err := this.auth.Generate(&Auth{ProfileId: p.Id})
	if err != nil {
		return err
	}

	// http-only is set to false so that it can be checked in the js
	// TODO needed for chrome
	//ctx.SetCookie(cookieKey, token, cookieMaxAge, "/", "", true, false)
	ctx.SetCookie(cookieKey, token, cookieMaxAge, "/", "", false, false)

	return nil
}

type Auth struct {
	ProfileId primitive.ObjectID `json:"id"`
}

func (this *Authenticator) ParseAuthentication(ctx *gin.Context) (*Auth, bool) {
	// Pull cookie
	hdr, err := ctx.Cookie(cookieKey)
	if err != nil {
		ctx.Status(http.StatusUnauthorized)
		return nil, false
	}

	// Parse id from cookie
	a := new(Auth)
	if err := this.auth.Parse([]byte(hdr), a, cookieMaxAge); err != nil {
		expireCookie(ctx)
		ctx.String(http.StatusUnauthorized, "invalid cookie")
		return nil, false
	}

	return a, true
}

func NewAuthenticator(cli *mongo.Client, auth *auth.Authenticator, e *gin.Engine) *Authenticator {
	a := &Authenticator{
		db: &database{
			coll: cli.Database("conflux").Collection("profile"),
		},
		auth: auth,
	}

	group := e.Group("profile")

	// Auth
	group.Handle(http.MethodPost, "login", a.login)
	group.Handle(http.MethodPost, "signup", a.signup)
	group.Handle(http.MethodPost, "validate", a.validate)

	// Query
	group.Handle(http.MethodGet, "self", a.self)
	group.Handle(api.GetBody, "profile", a.profile)
	group.Handle(api.GetBody, "profiles", a.profiles)

	return a
}
