package main

import (
	"conflux/internal/filestoreManager"
	"conflux/internal/handlers/profile"
	"conflux/internal/handlers/storage"
	"context"
	"github.com/gin-gonic/gin"
	"github.com/memori-dev/auth"
	"github.com/memori-dev/mongonerics"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
	"path"
	"time"
)

const (
	mongoURI     = "mongodb://localhost:27017"
	frontendBase = "../../frontend"
)

// TODO generate these on the first run and store in a file
// TODO admin panel to update these
var (
	pubKey  = []byte{229, 235, 163, 232, 20, 90, 189, 195, 1, 99, 48, 98, 240, 87, 49, 202, 137, 48, 71, 81, 179, 188, 50, 55, 50, 253, 233, 48, 66, 95, 230, 57}
	privKey = []byte{54, 196, 29, 171, 196, 144, 16, 227, 240, 0, 62, 252, 163, 22, 250, 107, 67, 38, 161, 77, 225, 141, 60, 94, 187, 222, 236, 251, 97, 239, 127, 198, 229, 235, 163, 232, 20, 90, 189, 195, 1, 99, 48, 98, 240, 87, 49, 202, 137, 48, 71, 81, 179, 188, 50, 55, 50, 253, 233, 48, 66, 95, 230, 57}
	encKey  = [32]byte{22, 143, 172, 237, 59, 48, 237, 7, 71, 145, 138, 246, 194, 30, 162, 83, 72, 234, 141, 83, 78, 177, 20, 237, 126, 85, 176, 211, 214, 62, 99, 94}
)

func mongoCli() (*mongo.Client, func()) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cli, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		panic(err)
	}

	if err = cli.Ping(ctx, readpref.Primary()); err != nil {
		panic(err)
	}

	return cli, func() {
		if err = cli.Disconnect(ctx); err != nil {
			panic(err)
		}
	}
}

func staticFrontendFile(engine *gin.Engine, path string) {
	engine.StaticFile(path, frontendBase+path)
}

func addPage(engine *gin.Engine, htmlPath, frontendPath string) {
	engine.StaticFile(htmlPath, path.Join(frontendBase, frontendPath, "main.html"))
	staticFrontendFile(engine, path.Join(frontendPath, "main.bundle.js"))
}

func main() {
	engine := gin.Default()

	// mongo
	cli, disconnect := mongoCli()
	defer disconnect()

	confluxDB := cli.Database("conflux")

	// TODO debugging
	engine.StaticFile("/live.js", frontendBase+"/live.js")

	// Profile
	authenticator := profile.NewAuthenticator(cli, &auth.Authenticator[profile.Auth]{
		Public:        pubKey,
		Private:       privKey,
		EncryptionKey: &encKey,
	}, engine)
	addPage(engine, "/", "/profile")

	// Storage
	store := &storage.Handler{
		FileStoreManager: &filestoreManager.FilestoreManager{
			Cli: &mongonerics.Client[filestoreManager.Metadata]{
				Collection: confluxDB.Collection("filestore"),
			},
			FilestoreDB: cli.Database("filestore"),
		},
		Auth: authenticator,
	}
	store.AddHandlersTo(engine)
	addPage(engine, "/storage", "/storage")

	// run
	if err := engine.Run(); err != nil {
		panic(err)
	}
}
