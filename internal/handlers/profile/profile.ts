import {Group, method} from "golue"

const group = new Group("profile")

// Authentication
export const profileAuthApiGroup = {
    login: group.endpoint(method.POST, {
        path: "login",
        invalidStatuses: [400, 401],
        buildRequestInit: Group.buildRequestInitJSON<{
            Name: string
            Password: string
        }>(),
    }),

    signup: group.endpoint(method.POST, {
        path: "signup",
        invalidStatuses: [400, 401, 409, 500],
        buildRequestInit: Group.buildRequestInitJSON<{
            Name: string
            Password: string
            PasswordEnabled: boolean
        }>(),
    }),

    validate: group.endpoint(method.POST, {
        path: "validate",
        invalidStatuses: [400, 401],
        buildRequestInit: Group.buildRequestInitJSON<{
            Name: string
        }>(),
    }),
}

export const profileQueryApiGroup = {
    self: group.endpoint(method.GET, {
        path: "self",
        invalidStatuses: [401, 500],
    }),

    // Payload: mongonerics.FindPayload
    profile: group.endpoint(method.GET_BODY, {
        path: "profile",
        invalidStatuses: [401, 500],
        buildRequestInit: Group.buildRequestInitJSON<{}>(),
    }),

    // Payload: mongonerics.FindPayload
    profiles: group.endpoint(method.GET_BODY, {
        path: "profiles",
        invalidStatuses: [401, 500],
        buildRequestInit: Group.buildRequestInitJSON<{}>(),
    }),
}
