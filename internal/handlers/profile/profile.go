package profile

import (
	"conflux/internal/handlers/profile/avatar"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/crypto/bcrypt"
)

type passwordType int

const (
	none passwordType = iota // 0
	password
	email
)

// TODO
//  email
//  email password
//  2fa
type profile struct {
	// Private to backend
	Id           primitive.ObjectID `bson:"_id"`
	PasswordHash []byte             `bson:"PasswordHash"`

	// Public, can be shared
	Name string `bson:"Name"`
	// TODO replace with passwordType
	PasswordEnabled bool   `bson:"PasswordEnabled"`
	ImageB64        []byte `bson:"ImageB64"`
}

func (this *profile) validatePassword(password string) bool {
	if !this.PasswordEnabled {
		return true
	}

	return bcrypt.CompareHashAndPassword(this.PasswordHash, []byte(password)) == nil
}

func newProfile(name, password string, passwordEnabled bool) (*profile, error) {
	// Hash password
	var hash []byte = nil
	var err error
	if passwordEnabled {
		hash, err = bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			return nil, err
		}
	}

	// Avatar
	avatarB64, err := avatar.GetAvatar()
	if err != nil {
		return nil, err
	}

	return &profile{
		Id:              primitive.NewObjectID(),
		Name:            name,
		PasswordEnabled: passwordEnabled,
		PasswordHash:    hash,
		ImageB64:        avatarB64,
	}, nil
}
