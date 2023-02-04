import {Group, method} from "golue"

const storageGroup = new Group("storage")

const fileGroup = storageGroup.newGroup("file")
export const fileApiGroup = {
    create: fileGroup.endpoint(method.POST, {
        path: "create",
        invalidStatuses: [500],
        buildRequestInit: function (file): RequestInit {
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
    read: fileGroup.endpoint(method.GET_BODY, {
        path: "read",
        invalidStatuses: [500],
        buildRequestInit: Group.buildRequestInitJSON<{}>()
    }),
}

const filestoreGroup = storageGroup.newGroup("filestore")
export const filestoreApiGroup = {
    create: filestoreGroup.endpoint(method.POST, {
        path: "create",
        invalidStatuses: [500],
        buildRequestInit: Group.buildRequestInitJSON<{
            Name: string
        }>()
    }),
    read: filestoreGroup.endpoint(method.GET, {
        path: "read",
        invalidStatuses: [500],
    }),
}
