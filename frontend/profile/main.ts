import {style} from '@vanilla-extract/css';
import {Notyf} from "notyf"
import {lm} from "@memori-dev/lm"
import {profileAuthApiGroup, profileQueryApiGroup} from "../../internal/handlers/profile/profile"
import {AuthView} from "./auth"
import {ProfileView} from "./profile"
import {theme} from "../theme"

const svgs = {
    createProfile: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
  <line x1="12" y1="5" x2="12" y2="19" />
  <line x1="5" y1="12" x2="19" y2="12" />
</svg>`
}

const styles = {
    main: style({
        width: "100vw",
        minHeight: "100vh",

        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
    }),
    welcome: style({
        marginTop: "6rem",
        marginBottom: "6rem",
        fontSize: `calc(6rem + 1vmin)`,

        textAlign: "center",
        color: theme.color.white.medium,
        userSelect: "none",
    }),

    createProfileSpan: style({
        display: "flex",
        alignContent: "center",
        justifyContent: "center",
    }),

    createProfileImg: style({
        width: "75%",
        aspectRatio: 1,
        color: "#dddddd",
    }),

    paddingBottom: style({
        height: "8rem",
    })
}

const notyf = new Notyf({
    position: {x: "right", y: "top"},
    ripple: false,
});

// Main
const main = lm.appendNew(document.body, "main", styles.main)

// Welcome
lm.appendNewAttrs(main, "h1", {innerText: "Welcome"}, styles.welcome, theme.font.fontFamily)

// Auth
const authView = new AuthView()
lm.append(document.body, authView.container)

// Profiles
const profilesView = new ProfileView()
lm.append(main, profilesView.container);

// Create profile
// TODO
const createProfileContainer = new lm("div", styles.createProfileSpan)
// const createProfileSvg = lm.appendNewSvg(createProfileContainer, svgs.createProfile, styles.createProfileImg)
lm.appendNewSvg(createProfileContainer, svgs.createProfile, styles.createProfileImg)
const createProfile = profilesView.addProfile("Create Profile", createProfileContainer)
createProfile.addEventListener("click", function () {
    authView.render(true, "")
})

// Padding bottom
lm.appendNew(main, "span", styles.paddingBottom)

async function loginNoPass(name: string) {
    // Login
    let res = await profileAuthApiGroup.login({Name: name})
    if (res.error) {
        notyf.error(res.response?.statusText ?? "login failed")
        return
    }

    // Validate
    res = await profileAuthApiGroup.validate({Name: name})
    if (res.error) {
        notyf.error(res.response?.statusText ?? "validation failed")
        return
    }

    window.location.href = "/storage"
}

async function loadProfileData() {
    let res
    for (let i = 0; i < 5; i++) {
        res = await profileQueryApiGroup.profiles({})
        if (!res.error) break

        notyf.error("Failed to load profiles! Retrying...")
        await new Promise(function (r) {
            setTimeout(r, 1000 * (i + 1))
        });
    }

    // Throw if the profiles were not loaded
    if (!res) throw new Error("Failed to load profiles! Please retry later.")

    return await res.response?.json()
}

interface Profile {
    name: string
    imageb64: string
    passwordEnabled: boolean
}

function addProfile(profile: Profile) {
    const img = lm.newAttrs("img", {src: "data:image/png;base64," + atob(profile.imageb64)})

    const profileDiv = profilesView.addProfile(profile.name, img)
    profileDiv.addEventListener("click", async function () {
        // Auto redirect if already logged in
        const validateRes = await profileAuthApiGroup.validate(profile.name)
        if (!validateRes.error) {
            window.location.href = "/storage"
            return
        }

        // Log in if there is no password
        if (!profile.passwordEnabled) {
            await loginNoPass(profile.name)
            return
        }

        // Render
        authView.render(false, profile.name)
    })
}

// Load profiles
(async function () {
    try {
        // TODO add each w a delay and fade in? or is this too much animation
        (await loadProfileData()).forEach(addProfile)
    } catch (e: any) {
        notyf.error(e.message)
    }
})()

function validateInputs() {
    // Validate name
    if (!authView.nameInput.input.value) {
        throw new Error("Username is not set")
    }

    // Validate password
    //.. signup && passwordEnabled
    //.. Login / !signup
    if (!authView.signupSelected || (authView.signupSelected && authView.passwordEnabled.isChecked())) {
        if (!authView.passwordInput.input.value) throw new Error("Password is not set")
    }

    // Validate confirmPassword
    //.. signup && passwordEnabled
    if (authView.signupSelected && authView.passwordEnabled.isChecked()) {
        if (authView.passwordInput.input.value !== authView.confirmPasswordInput.input.value) {
            throw new Error("Passwords do not match")
        }
    }
}

async function postFormData() {
    const Name = authView.nameInput.input.value
    const Password = authView.passwordInput.input.value
    const PasswordEnabled = authView.passwordEnabled.isChecked()

    // Post data
    const res = authView.signupSelected ?
        await profileAuthApiGroup.signup({Name, Password, PasswordEnabled})
        : await profileAuthApiGroup.login({Name, Password})

    // Validate
    if (res.error) throw new Error(res.response?.statusText ?? `failed ${authView.signupSelected ? "signup" : "login"}`)
}

async function validateCookie() {
    const res = await profileAuthApiGroup.validate({Name: authView.nameInput.input.value})
    if (res.error) throw new Error("Login was completed, but the cookie was not valid")
}

authView.submit.onclick = async function () {
    // Don't run any code if the button was clicked while the modal was closing
    if (!authView.isRendered) return

    try {
        validateInputs()
        await postFormData()
        await validateCookie()
    } catch (e: any) {
        notyf.error(e.message)
        return
    }

    // TODO go to user page
    notyf.success("Successfully logged in")
    window.location.href = "/storage"
}
