import {style} from '@vanilla-extract/css';
import {lm} from "@memori-dev/lm"
import {theme} from "../theme"

const profilesContainerStyle = style({
    // Flex
    display: "flex",
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "center",
    gap: "4rem",

    // W
    width: "min(80vw, 100rem)",
    "@media": {
        "all and (orientation: portrait)": {
            width: "min(90vw, 80rem)",
        }
    },
})

const profileStyle = style({
    // Cursor
    userSelect: "none",
    cursor: "pointer",

    // Flex
    display: "flex",
    flexDirection: "column",
    justifyContent: "flex-start",
    alignItems: "center",

    textAlign: "center",

    // W
    width: "min(10rem, 18vmin)",
    "@media": {
        "all and (orientation: portrait)": {
            width: "max(5rem, 25vw)",
        }
    },

    selectors: {
        "& > svg, img": {
            // WxH
            width: "90%",
            aspectRatio: "1",
        },
        "& > p": {
            // W
            width: "100%",

            // Font
            color: theme.color.white.light,
            wordWrap: "break-word",
            fontWeight: "bolder",
            fontSize: "calc(1.5rem + 0.1vmin)",
            "@media": {
                "all and (orientation: portrait)": {
                    fontSize: "2.5rem",
                },
            }
        }
    },
})

export class ProfileView {
    container: HTMLDivElement

    addProfile(name: string, img: HTMLElement) {
        // Div
        const container = lm.appendNew(this.container, "div", profileStyle)

        // Image
        img.draggable = false
        // TODO SVG & containers
        if (img instanceof HTMLImageElement) {
            img.alt = "profile picture for " + name
        }
        lm.append(container, img)

        // Name
        lm.appendNewAttrs(container, "p", {innerText: name}, theme.font.fontFamily)

        return container
    }

    constructor() {
        this.container = new lm("div", profilesContainerStyle)
    }
}
