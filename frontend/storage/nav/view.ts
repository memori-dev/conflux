import {theme} from "../../theme"
import {bar} from "../bar"
import {lm} from "lm"

const svgs = {
    // menu: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    //     <path d="M4 11h12v2H4zm0-5h16v2H4zm0 12h7.235v-2H4z" fill="currentColor"/>
    // </svg>`,
    dbConfig: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path d="m2.344 15.271 2 3.46a1 1 0 0 0 1.366.365l1.396-.806c.58.457 1.221.832 1.895 1.112V21a1 1 0 0 0 1 1h4a1 1 0 0 0 1-1v-1.598a8.094 8.094 0 0 0 1.895-1.112l1.396.806c.477.275 1.091.11 1.366-.365l2-3.46a1.004 1.004 0 0 0-.365-1.366l-1.372-.793a7.683 7.683 0 0 0-.002-2.224l1.372-.793c.476-.275.641-.89.365-1.366l-2-3.46a1 1 0 0 0-1.366-.365l-1.396.806A8.034 8.034 0 0 0 15 4.598V3a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v1.598A8.094 8.094 0 0 0 7.105 5.71L5.71 4.904a.999.999 0 0 0-1.366.365l-2 3.46a1.004 1.004 0 0 0 .365 1.366l1.372.793a7.683 7.683 0 0 0 0 2.224l-1.372.793c-.476.275-.641.89-.365 1.366zM12 8c2.206 0 4 1.794 4 4s-1.794 4-4 4-4-1.794-4-4 1.794-4 4-4z" fill="currentColor"/>
    </svg>`,
}

const styles = lm.createStyleSheet({
    nav: {
        // Position
        position: "fixed",
        top: 0,
        left: 0,

        // WxH
        width: "100%",
        height: bar.sizeLandscape,
        "@media all and (max-width: 640px)": {
            height: bar.sizePortrait,
        },

        // Flex
        display: "flex",
        flexDirection: "row",
        alignItems: "center",

        backgroundColor: theme.color.dark.absolute,

        "& span, button": {
            // WxH
            height: "100%",
            aspectRatio: 1,
            padding: 0,

            // Hide button to show the svg
            backgroundColor: "transparent",
            border: 0,

            cursor: "pointer",

            "& svg": {
                // WxH
                height: "66%",
                aspectRatio: 1,

                color: theme.color.white.medium,
            }
        },

        "& p": {
            // Font
            textAlign: "left",
            color: theme.color.white.medium,
            fontSize: bar.fontSizeLandscape,
            "@media all and (max-width: 640px)": {
                fontSize: bar.fontSizePortrait,
            },

            margin: "0 0 0 1rem",

            // Fill space to push buttons to ends
            flexGrow: 1,
        },
    },
})

export class NavView {
    nav: HTMLElement
    menuNotch: HTMLSpanElement
    databaseName: HTMLParagraphElement
    // TODO databaseConfig
    databaseConfigButton: HTMLButtonElement

    constructor() {
        // Nav
        this.nav = lm.new("nav", styles.nav)

        // This creates a notch for the menu button
        this.menuNotch = lm.appendNew(this.nav, "span")

        // Db Name
        this.databaseName = lm.appendNewAttrs(this.nav, "p", {innerText: "TODO UPDATE"}, theme.styles.font)

        // Db Config
        this.databaseConfigButton = lm.appendNew(this.nav, "button")
        const dbConfigSvg = lm.appendNewSvg(this.databaseConfigButton, svgs.dbConfig)
        dbConfigSvg.style.height = "55%"
    }
}
