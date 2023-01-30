const {Group} = require("golue");

const group = new Group("profile")

// Authentication
const profileAuthApiGroup = {
    // Payload: {Name, Password}
    login: group.POST({
        path: "login",
        invalidStatuses: [400, 401],
        buildFetchArgs: Group.buildFetchArgsJSON,
    }),

    // Payload: {Name, Password, PasswordEnabled}
    signup: group.POST({
        path: "signup",
        invalidStatuses: [400, 401, 409, 500],
        buildFetchArgs: Group.buildFetchArgsJSON,
    }),

    // Payload: {Name}
    validate: group.POST({
        path: "validate",
        invalidStatuses: [400, 401],
        buildFetchArgs: Group.buildFetchArgsJSON,
    }),
}

const profileQueryApiGroup = {
    self: group.GET({
        path: "self",
        invalidStatuses: [401, 500],
    }),

    // Payload: mongonerics.FindPayload
    profile: group.GET_BODY({
        path: "profile",
        invalidStatuses: [401, 500],
        buildFetchArgs: Group.buildFetchArgsJSON,
    }),

    // Payload: mongonerics.FindPayload
    profiles: group.GET_BODY({
        path: "profiles",
        invalidStatuses: [401, 500],
        buildFetchArgs: Group.buildFetchArgsJSON,
    }),
}

module.exports = {
    profileAuthApiGroup,
    profileQueryApiGroup,
}
