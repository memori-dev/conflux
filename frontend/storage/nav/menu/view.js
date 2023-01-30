const {theme} = require("../../../theme");
const {bar} = require("../../bar");
const {lm} = require("lm");

const svgs = {
    arrow: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
    <path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="48" d="M184 112l144 144-144 144"/>
</svg>`,

    hamburger: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path d="M4 11h12v2H4zm0-5h16v2H4zm0 12h7.235v-2H4z" fill="currentColor"/>
</svg>`,

    tempProfilePicture: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
  <line x1="12" y1="6" x2="12" y2="3" />
  <line x1="16.25" y1="7.75" x2="18.4" y2="5.6" />
  <line x1="18" y1="12" x2="21" y2="12" />
  <line x1="16.25" y1="16.25" x2="18.4" y2="18.4" />
  <line x1="12" y1="18" x2="12" y2="21" />
  <line x1="7.75" y1="16.25" x2="5.6" y2="18.4" />
  <line x1="6" y1="12" x2="3" y2="12" />
  <line x1="7.75" y1="7.75" x2="5.6" y2="5.6" />
</svg>`,
}

const styles = lm.createStyleSheet({
    menu: {
        position: "absolute",
        zIndex: 1000,
        backgroundColor: theme.color.dark.absolute,

        // WxH
        height: "100%",
        width: "min(33%, 16rem)",

        // flex
        display: "flex",
        alignItems: "flex-start",
        flexDirection: "column",
        gap: "0.25rem",

        transition: "transform 0.3s ease-in-out",
    },

    menuHide: {
        transform: "translateX(-100%)",
    },

    menuHeader: {
        // Bar size is added to overflow for the menu span>svg
        width: `calc(100% + ${bar.sizeLandscape})`,
        height: bar.sizeLandscape,
        "@media all and (max-width: 640px)": {
            width: `calc(100% + ${bar.sizePortrait})`,
            height: bar.sizePortrait,
        },

        // flex
        display: "flex",
        flexDirection: "row",
        justifyContent: "flex-start",
        alignItems: "center",

        "& span": {
            // WxH
            height: "100%",
            aspectRatio: 1,
            padding: 0,

            // Hide button to show the svg
            border: 0,

            cursor: "pointer",

            display: "flex",
            justifyContent: "center",
            alignItems: "center",

            "& svg": {
                // WxH
                height: "66%",
                aspectRatio: 1,

                color: theme.color.white.medium,
            },
        },
    },

    profileDiv: {
        // WxH
        width: "calc(100% - 3rem)",
        height: "100%",

        margin: "0 0.5rem",

        // flex
        display: "flex",
        flexDirection: "row",
        justifyContent: "flex-start",
        alignItems: "center",
        gap: "0.5rem",

        // cursor
        userSelect: "none",
        cursor: "pointer",

        // Profile picture
        "& img, svg": {
            height: "75%",
            aspectRatio: 1,
        },

        "& h3": {
            // font
            color: theme.color.white.light,
            fontSize: "1.25rem",

            // overflow
            textOverflow: "ellipsis",
            overflow: "hidden",
        },
    },

    collapsibleHeader: {
        width: "100%",

        margin: "0 0.5rem",

        cursor: "pointer",

        // flex
        display: "flex",
        flexDirection: "row",
        justifyContent: "flex-start",
        alignItems: "center",

        "& p": {
            backgroundColor: "transparent",

            // font
            color: theme.color.white.light,
            fontSize: "1rem",
            textAlign: "left",
            userSelect: "none",

            marginLeft: "0.5rem",
            marginRight: "0.5rem",
        },

        "& svg": {
            height: "1rem",
            aspectRatio: 1,
            marginLeft: "0.5rem",
            color: theme.color.white.light,

            transition: "transform linear 0.25s",
        },
    },

    rotate90: {
        transform: "rotate(90deg)",
    },

    collapsibleContent: {
        width: "100%",
        margin: "0 0.5rem",

        // flex
        display: "flex",
        flexDirection: "column",
        alignItems: "flex-start",

        overflow: "hidden",
        transition: "height 0.3s ease-in-out",

        "& span": {
            color: theme.color.white.light,
            fontSize: "0.85rem",

            margin: "0.5rem 1rem",

            cursor: "pointer",
            userSelect: "none",
        },
    },

    createDatabase: {
        width: "min(75%, 12rem)",

        backgroundColor: theme.color.medium.secondary,
        borderRadius: "0.5rem",

        margin: "auto auto 2rem auto",
        padding: "1rem 0.5rem",

        // font
        color: theme.color.white.light,
        fontSize: "1rem",
        textAlign: "center",

        outline: "none",
        border: "none",

        // cursor
        cursor: "pointer",
        userSelect: "none",
    },
})

class Collapsible {
    header
    headerText
    headerArrow

    content

    appendChild(id, name, onclick) {
        return lm.appendNewAttrs(this.content, "span", {
            id: id,
            innerText: name,
            onclick: onclick,
        }, theme.styles.font)
    }

    removeChild(id) {
        for (const child in this.content.childNodes) {
            if (child.id !== id) continue

            this.content.removeChild(child)
            return
        }
    }

    constructor(parent, name) {
        this.header = lm.appendNew(parent, "span", styles.collapsibleHeader)

        this.headerText = lm.appendNewAttrs(this.header, "p", {innerText: name}, theme.styles.font)
        this.headerArrow = lm.appendNewSvg(this.header, svgs.arrow)

        this.content = lm.appendNew(parent, "div", styles.collapsibleContent)
        this.content.style.height = "0px"

        this.header.addEventListener("click", function () {
            this.content.style.height = this.content.clientHeight !== 0 ?
                "0px" : this.content.scrollHeight + "px"

            this.headerArrow.classList.toggle(styles.rotate90)
        }.bind(this))
    }
}

class MenuView {
    div

    header
    profileDiv
    profilePicture
    profileName
    hamburger

    ownDatabases
    sharedDatabases
    sharedFiles

    toggleHide() {
        this.div.classList.toggle(styles.menuHide)
    }

    constructor() {
        // Main div
        this.div = lm.new("div", styles.menu)

        // Header
        this.header = lm.appendNew(this.div, "div", styles.menuHeader)

        // ProfileDiv
        this.profileDiv = lm.appendNew(this.header, "div", styles.profileDiv)
        this.profilePicture = lm.appendNewSvg(this.profileDiv, svgs.tempProfilePicture)
        this.profileName = lm.appendNew(this.profileDiv, "h3", theme.styles.font)
        this.profileName.innerText = "Name loading..."

        this.hamburgerContainer = lm.appendNew(this.header, "span")
        this.hamburger = lm.appendNewSvg(this.hamburgerContainer, svgs.hamburger)
        this.hamburgerContainer.onclick = function () {
            this.toggleHide()
        }.bind(this)

        // Collapsibles
        this.ownDatabases = new Collapsible(this.div, "Own databases")
        this.sharedDatabases = new Collapsible(this.div, "Shared databases")
        this.sharedFiles = new Collapsible(this.div, "Shared files")

        // Create database
        this.createDatabaseButton = lm.appendNewAttrs(this.div, "button", {innerText: "Create database"}, styles.createDatabase, theme.styles.font)
    }
}

module.exports = MenuView
