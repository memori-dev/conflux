const {profileAuthApiGroup, profileQueryApiGroup} = require("../../internal/handlers/profile/profile");
const {theme, applyDefaults} = require("../theme");
const {lm} = require("lm");
const {AuthView} = require("./auth");
const {ProfileView} = require("./profile");
const {Notyf} = require("notyf");

const svgs = {
    createProfile: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
  <line x1="12" y1="5" x2="12" y2="19" />
  <line x1="5" y1="12" x2="19" y2="12" />
</svg>`
}

let styles = lm.createStyleSheet({
    main: {
        width: "100vw",
        minHeight: "100vh",

        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
    },

    welcome: {
        marginTop: "6rem",
        marginBottom: "6rem",
        fontSize: `calc(6rem + 1vmin)`,

        textAlign: "center",
        color: theme.color.white.medium,
        userSelect: "none",
    },

    createProfileSpan: {
        display: "flex",
        alignContent: "center",
        justifyContent: "center",
    },

    createProfileImg: {
        width: "75%",
        aspectRatio: 1,
        color: "#dddddd",
    },

    paddingBottom: {
        height: "8rem",
    }
})

const notyf = new Notyf({
    position: {x: "right", y: "top"},
    ripple: false,
});

// Main
applyDefaults()
const main = lm.appendNew(document.body, "main", styles.main)

// Welcome
lm.appendNewAttrs(main, "h1", {innerText: "Welcome"}, styles.welcome, theme.styles.font)

// Auth
const authView = new AuthView()
lm.append(document.body, authView.container)

// Profiles
const profilesView = new ProfileView()
lm.append(main, profilesView.container);

// Create profile
const createProfileImgSpan = lm.new("div", styles.createProfileSpan)
lm.appendNewSvg(createProfileImgSpan, svgs.createProfile, styles.createProfileImg)
const createProfile = profilesView.addProfile("Create Profile", createProfileImgSpan)
createProfile.addEventListener("click", function () {
    authView.render(true, "")
})

// Padding bottom
lm.appendNew(main, "span", styles.paddingBottom)

async function loginNoPass(Name) {
    // Login
    let res = await profileAuthApiGroup.login({Name})
    if (res.err !== void 0) {
        notyf.error(res.statusText)
        return
    }

    // Validate
    res = await profileAuthApiGroup.validate({Name})
    if (res.err !== void 0) {
        notyf.error(res.statusText)
        return
    }

    window.location.href = "/storage"
}

async function loadProfileData() {
    let res
    for (let i = 0; i < 5; i++) {
        res = await profileQueryApiGroup.profiles({})
        if (res.err === void 0) break

        notyf.error("Failed to load profiles! Retrying...")
        await new Promise(function (r) {
            setTimeout(r, 1000 * (i + 1))
        });
    }

    // Throw if the profiles were not loaded
    if (!res) throw new Error("Failed to load profiles! Please retry later.")

    return await res.json()
}

function addProfile({Name, ImageB64, PasswordEnabled}) {
    const img = lm.newAttrs("img", {src: "data:image/png;base64," + atob(ImageB64)})

    const profile = profilesView.addProfile(Name, img)
    profile.addEventListener("click", async function () {
        // Auto redirect if already logged in
        const validateRes = await profileAuthApiGroup.validate({Name})
        if (validateRes.err === void 0) {
            window.location.href = "/storage"
            return
        }

        // Log in if there is no password
        if (PasswordEnabled === false) {
            await loginNoPass(Name)
            return
        }

        // Render
        authView.render(false, Name)
    })
}

// Load profiles
(async function () {
    try {
        // TODO add each w a delay and fade in? or is this too much animation
        (await loadProfileData()).forEach(addProfile)
    } catch (e) {
        notyf.error(e.message)
    }
})()

function validateInputs() {
    // Validate name
    if (!authView.inputs.name.input.value) {
        throw new Error("Username is not set")
    }

    // Validate password
    //.. signup && passwordEnabled
    //.. Login / !signup
    if (!authView.signupSelected || (authView.signupSelected && authView.passwordEnabled.input.checked)) {
        if (!authView.inputs.password.input.value) throw new Error("Password is not set")
    }

    // Validate confirmPassword
    //.. signup && passwordEnabled
    if (authView.signupSelected && authView.passwordEnabled.input.checked) {
        if (authView.inputs.password.input.value !== authView.inputs.confirmPassword.input.value) {
            throw new Error("Passwords do not match")
        }
    }
}

async function postFormData() {
    const Name = authView.inputs.name.input.value
    const Password = authView.inputs.password.input.value
    const PasswordEnabled = authView.passwordEnabled.input.checked

    // Post data
    const res = authView.signupSelected ?
        await profileAuthApiGroup.signup({Name, Password, PasswordEnabled})
        : await profileAuthApiGroup.login({Name, Password})

    // Validate
    if (res.err !== void 0) throw new Error(res.statusText)
}

async function validateCookie() {
    const res = await profileAuthApiGroup.validate({Name: authView.inputs.name.input.value})
    if (res.err !== void 0) throw new Error("Login was completed, but the cookie was not valid")
}

authView.submit.onclick = async function () {
    // Don't run any code if the button was clicked while the modal was closing
    if (!authView.isRendered) return

    try {
        validateInputs()
        await postFormData()
        await validateCookie()
    } catch (e) {
        notyf.error(e.message)
        return
    }

    // TODO go to user page
    notyf.success("Successfully logged in")
    window.location.href = "/storage"
}
