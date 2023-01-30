const {DisplayModel} = require("./model");
const {DisplayView} = require("./view");

// TODO constrain to screen option
//  will need to handle resizes https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event
//  minmax down to min
//  remove overflow and highlight hidden in red

// TODO resize to fit row widths
//  update on (create / delete / update) row, no read since create covers that
//  smart option to ignore outliers

// TODO reset option

// TODO toggle visibility

class DisplayController {
    model
    view

    // TODO
    //  persist widths
    //  persist order
    //  remove from view (disconnect observers?)
    // removeHeader(key) {}

    // TODO multiple headers & then reorder at the end
    createHeader(key) {
        // Add to order if it does not exist
        if (!this.model.order.value.includes(key)) {
            this.model.order.value.push(key)
            this.model.order.persist()
        }

        // Set width if it does not exist
        if (!this.model.widths.value.hasOwnProperty(key)) {
            this.model.widths.value[key] = this.model.slider.min
            this.model.widths.persist()
        }

        // Pull data from model
        const width = this.model.widths.value[key]

        // Add header to view
        const {slider} = this.view.createHeader(key, this.model.slider, width)

        // Update model
        slider.addEventListener("input", function() {
            this.model.widths.value[key] = slider.value
        }.bind(this))

        // Persist values only on mouseup
         slider.onmouseup = function () {
             this.model.widths.persist()
         }.bind(this)

        return {
            width,
            slider,
        }
    }

    constructor(dbName) {
        // Model
        this.model = new DisplayModel(dbName)

        // View
        this.view = new DisplayView()

        // Update & persist order
        this.view.headerContainerDrake.on("drop", function() {
            this.model.order.value = Array.prototype.map.call(this.view.headerContainer.childNodes, function(header) {
                return header.key
            })
            this.model.order.persist()
        }.bind(this))
    }
}

module.exports = {
    DisplayController,
}
