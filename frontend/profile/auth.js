const {theme} = require("../theme");
const {Blur} = require("../components/blur");
const {lm} = require("lm");

// TODO password enabled better css and transition (likely slide down)
const styles = lm.createStyleSheet({
    container: {
        // Center absolutely
        position: "fixed",
        top: "50%",
        left: "50%",
        transform: "translate(-50%, -50%)",
        zIndex: 101,

        // Flex
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: "0.5rem 0",

        background: "#0a0a0a",

        // Width
        // Border
        width: "min(40vw, 60em)",
        border: 0,
        borderRadius: "min(1vw, 1.5em)",
        "@media all and (orientation: portrait)": {
            width: "90vw",
            borderRadius: "min(4vw, 6em)",
        },

        transition: "visibility 0.33s linear, opacity 0.33s linear",
    },

    containerHide: {
        opacity: 0,
        visibility: "hidden",
    },

    form: {
        width: "80%",
        marginTop: "calc(1rem + 1vh)",

        // These are hidden
        "& label": {
            height: 0,
            width: 0,

            visibility: "hidden",
            display: "block",
        },

        "& input": {
            width: "100%",

            margin: "calc(0.25rem + 1vmin) 0",

            background: "transparent",
            color: theme.color.white.light,

            fontSize: "calc(1.25rem + 1vmin)",
            "@media all and (orientation: portrait)": {
                fontSize: "calc(3rem + 1vmin)",
            },

            // TODO make this transition between light colors
            "&:focus": {
                borderColor: theme.color.light.secondary,
                outline: "none 0",
            },

            // Chrome, Firefox, Opera, Safari 10.1+
            "&::placeholder": {
                color: theme.color.white.dark,
                opacity: 1, // Firefox
            },

            // Internet Explorer 10-11
            "&:-ms-input-placeholder": {
                color: theme.color.white.dark,
            },

            // Microsoft Edge
            "&::-ms-input-placeholder": {
                color: theme.color.white.dark,
            },

            // border
            border: 0,
            borderBottom: `0.15rem solid ${theme.color.white.medium}`,
            transition: "border 0.5s linear",
        },
    },

    passwordEnabledContainer: {
        // Flex
        display: "flex",
        flexDirection: "row",
        alignItems: "center",
        justifyContent: "flex-start",
        gap: "calc(0.75rem + 1vmin)",

        width: "80%",
        marginTop: "calc(0.75rem + 1vmin)",

        "& label": {
            display: "inline",

            cursor: "pointer",

            fontSize: "calc(1.25rem + 0.5vmin)",
            userSelect: "none",
            color: theme.color.white.light,
        },

        "& input": {
            height: "calc(1rem + 0.5vmin)",
            aspectRatio: 1,

            cursor: "pointer",
            userSelect: "none",

            accentColor: theme.color.light.secondary,
        },
    },

    signupButton: {
        width: "min(50%, 8em)",

        fontSize: "calc(1em + 1vmin)",
        padding: "0.25rem 0",
        marginTop: "1rem",
        marginBottom: "1.5rem",
        "@media all and (orientation: portrait)": {
            fontSize: "calc(2rem + 1vmin)",
            padding: "0.5rem 0",
            marginTop: "2rem",
            marginBottom: "3rem",
        },

        '&:hover': {
            boxShadow: `0 0 1rem ${theme.color.light.primary}`,
        },

        color: "#dedede",

        backgroundColor: "transparent",
        border: `0.15em solid ${theme.color.light.primary}`,
        borderRadius: "8px",

        cursor: "pointer",

        transition: "box-shadow 0.5s linear",
    },
})

function toTitleCase(str) {
    return str.replace(/\w\S*/g, function (txt) {
        return txt.charAt(0).toUpperCase() + txt.substring(1).toLowerCase();
    });
}

function buildFormInputs(form) {
    function buildFormInput({id, type, autocomplete}) {
        const formInput = lm.newInput(type, id)
        formInput.label.innerText = toTitleCase(id)
        formInput.input.placeholder = toTitleCase(id)
        formInput.input.autocomplete = autocomplete

        return formInput
    }

    const inputs = {
        name: buildFormInput({id: "name", type: "text", autocomplete: "username"}),
        password: buildFormInput({id: "password", type: "password", autocomplete: "new-password"}),
        confirmPassword: buildFormInput({id: "confirm password", type: "password", autocomplete: "new-password"}),
    };
    Object.keys(inputs).forEach(function (key) {
        form.appendChild(inputs[key].label)
        form.appendChild(inputs[key].input)
    })

    // TODO password show fnality
    //  https://www.w3schools.com/howto/howto_js_toggle_password.asp

    return inputs
}

const passwordEnabledId = "password enabled"

function passwordEnabled() {
    const container = lm.new("div", styles.passwordEnabledContainer)
    const {input, label} = lm.appendNewInput(container, "checkbox", passwordEnabledId)

    label.classList.add(theme.styles.font)
    label.innerText = toTitleCase(passwordEnabledId)

    input.autocomplete = "off"

    return {
        container,
        input,
        label,
    }
}

class AuthView {
    blur

    isRendered = false
    signupSelected = void 0

    container
    form
    inputs
    passwordEnabled
    submit

    render(signupSelected, name) {
        this.signupSelected = signupSelected
        this.isRendered = true

        // Hide/Render inputs based on value
        if (signupSelected) {
            // Render all input & PasswordEnabled
            for (const key of Object.keys(this.inputs)) {
                this.inputs[key].input.style.display = "unset"
            }

            this.passwordEnabled.container.style.display = "flex"
            this.passwordEnabled.render()
        } else {
            // Render password
            // Hide name, confirmPassword, passwordEnabled
            this.inputs.name.input.style.display = "none"
            this.inputs.password.input.style.display = "unset"
            this.inputs.confirmPassword.input.style.display = "none"

            this.passwordEnabled.container.style.display = "none"
        }

        // Set name
        this.inputs.name.input.value = name

        // Render
        this.container.classList.remove(styles.containerHide)
        this.blur.render()
    }

    hide() {
        this.isRendered = false

        // Clear inputs
        for (const key of Object.keys(this.inputs)) {
            this.inputs[key].input.value = ""
        }

        this.container.classList.add(styles.containerHide)
        this.blur.hide()
    }

    constructor() {
        // Blur
        this.blur = new Blur(document.body, styles.blur)
        this.blur.fullScreen(100)
        this.blur.elem.addEventListener("click", function () {
            this.blur.toggleVisibility()
            this.hide()
        }.bind(this))

        // Modal
        this.container = lm.new("div", styles.container, styles.containerHide)
        this.form = lm.appendNew(this.container, "form", styles.form)
        this.inputs = buildFormInputs(this.form)
        this.passwordEnabled = passwordEnabled()
        lm.append(this.container, this.passwordEnabled.container)
        this.passwordEnabled.render = function () {
            const display = this.passwordEnabled.input.checked ? "block" : "none"
            this.inputs.password.input.style.display = display
            this.inputs.confirmPassword.input.style.display = display
        }.bind(this)
        this.passwordEnabled.render()
        this.passwordEnabled.input.addEventListener("click", this.passwordEnabled.render)

        this.submit = lm.appendNewAttrs(this.container, "button", {innerText: "Submit"}, styles.signupButton)

        // Modal keydown listener
        addEventListener('keydown', function (event) {
            // ESC => Exit out of modal
            if (this.isRendered && event.keyCode === 27) {
                this.hide()
                return false;
            }

            // ENTER => Submit
            if (this.isRendered && event.keyCode === 13) {
                this.submit.click()
                return false;
            }
        }.bind(this));
    }
}

module.exports = {
    AuthView,
}
