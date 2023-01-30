const {lm} = require("lm");

let styles = lm.createStyleSheet({
    blur: {
        // No initial blur
        opacity: 0,
        visibility: "hidden",

        backgroundColor: "#000000",
        transition: "opacity 0.33s linear",
    },
    blurFullScreen: {
        // Position
        position: "fixed",
        top: 0,
        left: 0,

        // WxH
        width: "100vw",
        height: "100vh",
    },
    blurShow: {
        opacity: 0.6,
        visibility: "visible",
    },
})

class Blur {
    elem

    toggleVisibility() {
        this.elem.classList.toggle(styles.blurShow)
    }

    render() {
        this.elem.classList.add(styles.blurShow)
    }

    hide() {
        this.elem.classList.remove(styles.blurShow)
    }

    fullScreen(zIndex) {
        this.elem.classList.toggle(styles.blurFullScreen)
        this.elem.style.zIndex = zIndex
    }

    constructor(parent, ...classes) {
        this.elem = lm.new("div", styles.blur, ...classes)
        if (!!parent) lm.append(parent, this.elem)
    }
}

module.exports = {
    Blur
}
