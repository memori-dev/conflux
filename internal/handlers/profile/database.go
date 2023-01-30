package profile

import (
	"context"
	"errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"time"
)

var errProfileExists = errors.New("profile already exists")

type database struct {
	coll *mongo.Collection
}

func (this *database) create(p *profile) error {
	// Check if profile already exists
	if profile, _ := this.readOne(nameLookupFilter(p.Name)); profile != nil {
		return errProfileExists
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := this.coll.InsertOne(ctx, p)
	return err
}

func nameLookupFilter(name string) primitive.M {
	return bson.M{"Name": name}
}

func idLookupFilter(id primitive.ObjectID) primitive.M {
	return bson.M{"_id": id}
}

func (this *database) readOne(filter interface{}) (*profile, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Find profile
	res := this.coll.FindOne(ctx, filter)
	if res.Err() != nil {
		return nil, res.Err()
	}

	// Decode profile
	u := new(profile)
	if err := res.Decode(u); err != nil {
		return nil, err
	}

	return u, nil
}

// Count: <= 0 will read all documents, > 0 will limit it to the count
func (this *database) read(count int, filter interface{}) ([]*profile, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cur, err := this.coll.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	var profiles []*profile
	for i := 0; cur.Next(ctx) && (count <= 0 || i < count); i++ {
		p := new(profile)
		if err := cur.Decode(p); err != nil {
			return nil, err
		}

		profiles = append(profiles, p)
	}

	_ = cur.Close(ctx)

	return profiles, nil
}

// TODO update

// TODO delete
