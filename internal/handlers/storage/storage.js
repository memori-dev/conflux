const {Group} = require("golue");

const storageGroup = new Group("storage")

const fileGroup = storageGroup.newGroup("file")
const fileApiGroup = {
    create: fileGroup.POST({
        path: "create",
        validStatuses: [200],
        invalidStatuses: [500],
        buildFetchArgs: function (file) {
            debugger
            let formData = new FormData();
            formData.append("file", file);
            formData.append("lastModified", file.lastModified);

            // timeout
            // TODO user cancellable (make this passed in)
            const ctrl = new AbortController()
            setTimeout(() => ctrl.abort(), 5000);

            return {
                body: formData,
                signal: ctrl.signal,
            }
        },
    }),

    // TODO filtering
    read: fileGroup.GET_BODY({
        path: "read",
        invalidStatuses: [500],
        buildFetchArgs: Group.buildFetchArgsJSON
    }),
}

const filestoreGroup = storageGroup.newGroup("filestore")
const filestoreApiGroup = {
    // Payload: {Name}
    create: filestoreGroup.POST({
        path: "create",
        invalidStatuses: [500],
        buildFetchArgs: Group.buildFetchArgsJSON
    }),
    read: filestoreGroup.GET({
        path: "read",
        invalidStatuses: [500],
    }),
}

module.exports = {
    fileApiGroup,
    filestoreApiGroup,
}
