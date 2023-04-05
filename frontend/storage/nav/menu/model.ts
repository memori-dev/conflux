import {profileQueryApiGroup} from "../../../../internal/handlers/profile/profile"
import {filestoreApiGroup} from "../../../../internal/handlers/storage/storage"

export class MenuModel {
    profileData

    ownDatabases = []
    sharedDatabases = []
    sharedFiles = []

    async databaseCreate() {
        const Name = "untitled"
        const res = await filestoreApiGroup.create({Name})
        const body = await res.json()
        const db = {
            Id: body.InsertedID,
            Name,
            // TODO OwnerId
        }

        this.ownDatabases.push(db)

        return db
    }

    async databaseRead() {
        const res = await filestoreApiGroup.read()
        this.ownDatabases = await res.json()
    }

    async profileRead() {
        const res = await profileQueryApiGroup.self()
        this.profileData = await res.json()
    }
}
