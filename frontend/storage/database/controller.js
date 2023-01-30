const {DbModel} = require("./model");
const {DbTable} = require("./table");
const {DisplayController} = require("../display/controller");

class DbController {
    // View
    model

    // View
    tableView
    displayController

    clear() {

    }

    async loadFiles(query) {
        const files = await this.model.read(query)

        // Build headerKeys set
        let headerKeys = new Set()
        files.forEach(function(file) {
            for (const key of Object.keys(file)) headerKeys.add(key)
        })
        headerKeys = Array.from(headerKeys)

        // TODO delete additional headers?

        // Create displayController headers
        for (const key of headerKeys) {
            const {slider} = this.displayController.createHeader(key)
            slider.addEventListener("input", function() {
                this.tableView.resizeColumns(this.displayController.model.widths.value)
            }.bind(this))
        }

        // Reorder displayController headers
        this.displayController.view.reorderHeaders(this.displayController.model.order.value)

        // Create table headers
        for (const key of headerKeys) this.tableView.newHeaderCell(key)

        // Reorder
        this.tableView.reorderColumns(this.displayController.model.order.value)

        // Resize
        this.tableView.resizeColumns(this.displayController.model.widths.value)

        // Create rows in table
        for (const file of files) this.tableView.createRow(file)
    }

    constructor(dbName) {
        // Model
        this.model = new DbModel()

        // View
        this.tableView = new DbTable()
        this.displayController = new DisplayController(dbName)

        // Reorder on drop
        this.displayController.view.headerContainerDrake.on("drop", function () {
            this.tableView.reorderColumns(this.displayController.model.order.value)
        }.bind(this))
    }
}

module.exports = {
    DbController,
}
