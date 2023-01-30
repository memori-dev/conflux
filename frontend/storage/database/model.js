const {Storage} = require("../../../internal/handlers/storage/storage");

class DbModel {
    dbName

    // cache (query => values) probably store in browser db

    // TODO create

    // TODO cache / store
    async read(query) {
        const res = await Storage.read.fetch()
        return await res.json()
    }

    // TODO update
    // async update(data) {
    //     const res = await Storage.
    // }

    // TODO delete

    constructor(dbName) {
        this.dbName = dbName
    }
}

module.exports = {
    DbModel,
}
