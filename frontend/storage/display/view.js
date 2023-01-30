const dragula = require("dragula");
const {lm} = require("lm");

const svgs = {
    settingsHeight: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
    <path d="M8  10v.01" />
    <path d="M12 10v.01" />
    <path d="M16 10v.01" />
    <path d="M8  14v.01" />
    <path d="M12 14v.01" />
    <path d="M16 14v.01" />
    </svg>`,

    dragAndDrop: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
    <line x1="4" y1="8" x2="20" y2="8" />
    <line x1="4" y1="16" x2="20" y2="16" />
    </svg>`,
}

const hideGhostImg = (function () {
    const elem = lm.new("img")
    elem.style.width = "0"
    elem.style.height = "0"

    return elem
})()

class DisplayView {
    // main container
    mainContainer
    mainContainerClass = "displayContainer"
    mainContainerMinHeight = 25
    mainContainerMaxHeight = 75

    headerContainer
    headerContainerDrake

    headers = new Map()
    headerClass = "displayHeader"

    // TODO
    // removeHeader(key) {}

    // key: string key for identifying the header, additionally serves as the display name
    // TODO if put in out of order, this will likely mess up
    // TODO also insert in the order
    // index: current index of the header in the container, if -1 set to end
    // minMax: slider {min, max}
    // width: slider value
    createHeader(key, minMax, width) {
        // container div
        const header = lm.appendNew(this.headerContainer, "div", this.headerClass)
        header.key = key
        // TODO check if key already exists
        this.headers.set(key, header)

        // dragAndDrop svg
        lm.appendNewSvg(header, svgs.dragAndDrop)

        // name
        const name = lm.appendNew(header, "p")
        name.innerText = key

        // slider
        const slider = lm.appendNew(header, "input")
        slider.type = "range"
        Object.assign(slider, minMax)
        slider.value = width

        // TODO hide
        //  svg w onclick to toggleColumnVisibility
        //  grey out option and highlight the svg
        //  persist

        return {
            header,
            slider,
        }
    }

    reorderHeaders(order) {
        for (let orderIndex = 0; orderIndex < order.length; orderIndex++) {
            const node = this.headerContainer.childNodes[orderIndex]

            // Correct order
            if (node.key === order[orderIndex]) continue

            // Incorrect order
            let currentIndex = Array.prototype.findIndex.call(this.headerContainer.childNodes, function (header) {
                return header.key === order[orderIndex]
            })
            // TODO throw on -1

            const isBefore = currentIndex < orderIndex
            // Insert after if the value isBefore
            if (isBefore) currentIndex++

            // Header
            this.headerContainer.insertBefore(
                this.headerContainer.childNodes[currentIndex],
                this.headerContainer.childNodes[orderIndex],
            )

            // Decrement the orderIndex as the column is inserted before
            if (!isBefore) orderIndex--
        }
    }

    constructor() {
        // Settings container
        this.mainContainer = lm.appendNew(document.body, "div", this.mainContainerClass)
        this.mainContainer.style.visibility = "hidden"

        // TODO css positioning to keep it ~10% from left, right, bottom
        // Settings height handle
        const heightHandleContainer = lm.appendNew(this.mainContainer, "div", "heightHandle")
        heightHandleContainer.draggable = true
        // TODO make only the svg draggable?
        lm.appendNewSvg(heightHandleContainer, svgs.settingsHeight)

        // Hide the ghost image
        heightHandleContainer.ondragstart = function (event) {
            event.dataTransfer.setDragImage(hideGhostImg, 0, 0);
        }

        // Resize on drag
        heightHandleContainer.ondrag = function (event) {
            console.log(-event.offsetY, window.innerHeight, -event.offsetY * 100 / window.innerHeight)
            let maxHeight = this.mainContainerMinHeight + (-event.offsetY * 100 / window.innerHeight)
            maxHeight = Math.max(maxHeight, this.mainContainerMinHeight)
            maxHeight = Math.min(maxHeight, this.mainContainerMaxHeight)
            this.mainContainer.style.maxHeight = maxHeight + "%"
        }.bind(this)

        // Settings headers
        this.headerContainer = lm.appendNew(this.mainContainer, "div")

        // Dragula
        this.headerContainerDrake = dragula([this.headerContainer], {
            direction: "vertical",
            // Only move on the svg
            moves: function (el, source, handle) {
                return handle.tagName === "svg"
            },
        })
    }
}

module.exports = {
    DisplayView,
}
