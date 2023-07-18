import {style} from '@vanilla-extract/css';
import {LabeledInput, lm} from "@memori-dev/lm"
import {theme} from "../theme"
import {Blur} from "../components/blur"

// TODO password enabled better css and transition (likely slide down)

const containerStyle = style({
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
    "@media": {
        "all and (orientation: portrait)": {
            width: "90vw",
            borderRadius: "min(4vw, 6em)",
        }
    },
    transition: "visibility 0.33s linear, opacity 0.33s linear",
})
const containerHideStyle = style({
    opacity: 0,
    visibility: "hidden",
})
const formStyle = style({
    width: "80%",
    marginTop: "calc(1rem + 1vh)",

    // These are hidden
    selectors: {
        "& > label": {
            height: 0,
            width: 0,

            visibility: "hidden",
            display: "block",
        },
        "& > input": {
            width: "100%",

            margin: "calc(0.25rem + 1vmin) 0",

            background: "transparent",
            color: theme.color.white.light,

            fontSize: "calc(1.25rem + 1vmin)",
            "@media": {
                "all and (orientation: portrait)": {
                    fontSize: "calc(3rem + 1vmin)",
                }
            },

            // border
            border: 0,
            borderBottom: `0.15rem solid ${theme.color.white.medium}`,
            transition: "border 0.5s linear",
        },

        // TODO make this transition between light colors
        "& > input:focus": {
            borderColor: theme.color.light.secondary,
            outline: "none 0",
        },

        // Chrome, Firefox, Opera, Safari 10.1+
        "& > input:placeholder": {
            color: theme.color.white.dark,
            opacity: 1, // Firefox
        },

        // Internet Explorer 10-11
        "& > input:-ms-input-placeholder": {
            color: theme.color.white.dark,
        },

        // Microsoft Edge
        "& > input::-ms-input-placeholder": {
            color: theme.color.white.dark,
        },
    },
})
const passwordEnabledContainerStyle = style({
    // Flex
    display: "flex",
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "flex-start",
    gap: "calc(0.75rem + 1vmin)",

    width: "80%",
    marginTop: "calc(0.75rem + 1vmin)",

    selectors: {
        "& > label": {
            display: "inline",

            cursor: "pointer",

            fontSize: "calc(1.25rem + 0.5vmin)",
            userSelect: "none",
            color: theme.color.white.light,
        },

        "& > input": {
            height: "calc(1rem + 0.5vmin)",
            aspectRatio: 1,

            cursor: "pointer",
            userSelect: "none",

            accentColor: theme.color.light.secondary,
        }
    },
})
const signupButtonStyle = style({
    width: "min(50%, 8em)",

    fontSize: "calc(1em + 1vmin)",
    padding: "0.25rem 0",
    marginTop: "1rem",
    marginBottom: "1.5rem",

    "@media": {
        "all and (orientation: portrait)": {
            fontSize: "calc(2rem + 1vmin)",
            padding: "0.5rem 0",
            marginTop: "2rem",
            marginBottom: "3rem",
        }
    },

    selectors: {
        "&:hover": {
            boxShadow: `0 0 1rem ${theme.color.light.primary}`,
        }
    },

    color: "#dedede",

    backgroundColor: "transparent",
    border: `0.15em solid ${theme.color.light.primary}`,
    borderRadius: "8px",

    cursor: "pointer",

    transition: "box-shadow 0.5s linear",
})

function toTitleCase(str: string) {
    return str.replace(/\w\S*/g, function (txt) {
        return txt.charAt(0).toUpperCase() + txt.substring(1).toLowerCase();
    });
}

function buildInput(id: string, type: string, autocomplete: string): LabeledInput {
    const labeledInput = lm.newInput(type, id)
    labeledInput.label.innerText = toTitleCase(id)
    labeledInput.input.placeholder = toTitleCase(id)
    labeledInput.input.autocomplete = autocomplete
    return labeledInput
}

class PasswordEnabled {
    static id = "password enabled"

    container: HTMLDivElement
    labeledInput: LabeledInput

    isChecked() {
        return this.labeledInput.input.checked
    }

    constructor() {
        this.container = new lm("div", passwordEnabledContainerStyle)
        this.labeledInput = lm.appendNewInput(this.container, "checkbox", PasswordEnabled.id)

        this.labeledInput.label.classList.add(theme.font.fontFamily)
        this.labeledInput.label.innerText = toTitleCase(PasswordEnabled.id)

        this.labeledInput.input.autocomplete = "off"
    }
}

export class AuthView {
    blur: Blur = new Blur(document.body)

    isRendered: boolean = false
    signupSelected: boolean = false

    container
    form
    // TODO password show fnality
    //  https://www.w3schools.com/howto/howto_js_toggle_password.asp
    nameInput = buildInput("name", "text", "username")
    passwordInput = buildInput("password", "password", "new-password")
    confirmPasswordInput = buildInput("confirm password", "password", "new-password")
    inputs = [this.nameInput, this.passwordInput, this.confirmPasswordInput]

    passwordEnabled: PasswordEnabled = new PasswordEnabled()
    submit

    renderPasswordInputs() {
        const display = this.passwordEnabled.isChecked() ? "block" : "none"
        this.passwordInput.input.style.display = display
        this.confirmPasswordInput.input.style.display = display
    }

    render(signupSelected: boolean, name: string) {
        this.signupSelected = signupSelected
        this.isRendered = true

        // Hide/Render inputs based on value
        if (signupSelected) {
            // Render all input & PasswordEnabled
            this.inputs.forEach(function (input) {
                input.input.style.display = "unset"
            })

            this.passwordEnabled.container.style.display = "flex"
            this.renderPasswordInputs()
        } else {
            // Render password
            // Hide name, confirmPassword, passwordEnabled
            this.nameInput.input.style.display = "none"
            this.passwordInput.input.style.display = "unset"
            this.confirmPasswordInput.input.style.display = "none"

            this.passwordEnabled.container.style.display = "none"
        }

        // Set name
        this.nameInput.input.value = name

        // Render
        this.container.classList.remove(containerHideStyle)
        this.blur.render()
    }

    hide() {
        this.isRendered = false

        // Clear inputs
        this.inputs.forEach(function (input) {
            input.input.value = ""
        })

        this.container.classList.add(containerHideStyle)
        this.blur.hide()
    }

    constructor() {
        // Blur
        this.blur.fullScreen(100)
        this.blur.elem.addEventListener("click", function (this: AuthView) {
            this.blur.toggleVisibility()
            this.hide()
        }.bind(this))

        // Modal
        this.container = new lm("div", containerStyle, containerHideStyle)
        this.form = lm.appendNew(this.container, "form", formStyle)
        this.inputs.forEach(function (this: AuthView, input) {
            this.form.appendChild(input.label)
            this.form.appendChild(input.input)
        })
        lm.append(this.container, this.passwordEnabled.container)

        this.renderPasswordInputs()
        this.passwordEnabled.labeledInput.input.addEventListener("click", this.renderPasswordInputs.bind(this))

        this.submit = lm.appendNewAttrs(this.container, "button", {innerText: "Submit"}, signupButtonStyle)

        // Modal keydown listener
        addEventListener('keydown', function (this: AuthView, event: KeyboardEvent) {
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
