import {style} from '@vanilla-extract/css';
import {lm} from "@memori-dev/lm";

interface BlurStyle {
    blur: string
    blurFullScreen: string
    render: string
}

const defaultStyleSheet: BlurStyle = {
    blur: style({
        // No initial blur
        opacity: 0,
        visibility: "hidden",

        backgroundColor: "#000000",
        transition: "opacity 0.33s linear",
    }),
    blurFullScreen: style({
        // Position
        position: "fixed",
        top: 0,
        left: 0,

        // WxH
        width: "100vw",
        height: "100vh",
    }),
    render: style({
        opacity: 0.6,
        visibility: "visible",
    }),
}

export class Blur {
    elem: HTMLElement
    style: BlurStyle

    toggleVisibility() {
        this.elem.classList.toggle(this.style.blur)
    }

    render() {
        this.elem.classList.add(this.style.render)
    }

    hide() {
        this.elem.classList.remove(this.style.render)
    }

    fullScreen(zIndex: number) {
        this.elem.classList.toggle(this.style.blurFullScreen)
        this.elem.style.zIndex = zIndex.toString()
    }

    constructor(parent: HTMLElement, stylesheet?: BlurStyle, ...classes: string[]) {
        this.style = stylesheet ?? defaultStyleSheet
        // this.elem = lm.new("div", this.style.blur, ...classes)
        this.elem = new lm("div", this.style.blur, ...classes)
        if (!!parent) lm.append(parent, this.elem)
    }
}
