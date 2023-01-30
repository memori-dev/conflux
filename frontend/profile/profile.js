const {theme} = require("../theme");
const {lm} = require("lm");

const styles = lm.createStyleSheet({
    profilesContainer: {
        // Flex
        display: "flex",
        flexDirection: "row",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: "4rem",

        // W
        width: "min(80vw, 100rem)",
        "@media all and (orientation: portrait)": {
            width: "min(90vw, 80rem)",
        },
    },

    profile: {
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
        "@media all and (orientation: portrait)": {
            width: "max(5rem, 25vw)",
        },

        "& svg, img": {
            // WxH
            width: "90%",
            aspectRatio: "1",
        },

        "& p": {
            // W
            width: "100%",

            // Font
            color: theme.color.white.light,
            wordWrap: "break-word",
            fontWeight: "bolder",
            fontSize: "calc(1.5rem + 0.1vmin)",
            "@media all and (orientation: portrait)": {
                fontSize: "2.5rem",
            },
        },
    },
})

class ProfileView {
    container

    addProfile(name, img) {
        // Div
        const container = lm.appendNew(this.container, "div", styles.profile)

        // Image
        img.draggable = false
        img.alt = "profile picture for " + name
        lm.append(container, img)

        // Name
        lm.appendNewAttrs(container, "p", {innerText: name}, theme.styles.font)

        return container
    }

    constructor() {
        this.container = lm.new("div", styles.profilesContainer)
    }
}

module.exports = {
    ProfileView,
}