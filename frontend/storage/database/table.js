const {lm} = require("lm");

class DbTable {
    table
    tableClassName = "db"

    headerRow

    body

    get headerRowKeys() {
        return this.headerRow.childNodes.map(function (header) {
            return header.key
        })
    }

    newHeaderCell(key) {
        // Build cell
        const cell = lm.appendNew(this.headerRow, "th")
        cell.key = key
        cell.innerText = key

        return cell
    }

    // TODO crud row
    createRow(data) {
        const row = this.body.insertRow()

        this.headerRow.childNodes.forEach(function (header) {
            const cell = row.insertCell()
            if (data.hasOwnProperty(header.innerText)) cell.innerText = data[header.key]
        })
    }

    // order [key]
    // TODO ensure no extra & no missing keys
    reorderColumns(order) {
        for (let orderIndex = 0; orderIndex < order.length; orderIndex++) {
            const node = this.headerRow.childNodes[orderIndex]

            // Correct order
            if (node.key === order[orderIndex]) continue

            // Incorrect order
            let currentIndex = Array.prototype.findIndex.call(this.headerRow.childNodes, function(header) {
                return header.key === order[orderIndex]
            })
            // TODO throw on -1

            const isBefore = currentIndex < orderIndex
            // Insert after if the value isBefore
            if (isBefore) currentIndex++

            // Header
            this.headerRow.insertBefore(
                this.headerRow.childNodes[currentIndex],
                this.headerRow.childNodes[orderIndex],
            )

            // Rows
            for (let i = 0; i < this.body.childNodes.length; i++) {
                this.body.childNodes[i].insertBefore(
                    this.body.childNodes[i].childNodes[currentIndex],
                    this.body.childNodes[i].childNodes[orderIndex],
                )
            }

            // Decrement the orderIndex as the column is inserted before
            if (!isBefore) orderIndex--
        }

    }

    // widths: key => string of width in px (the string does not include 'px')
    resizeColumns(widths) {
        const out = [];
        for (const node of this.headerRow.childNodes) {
            out.push(`minmax(${widths[node.key]}px, auto)`)
        }

        this.table.style.gridTemplateColumns = out.join(" ")
    }

    constructor() {
        // Table
        this.table = lm.new("table", this.tableClassName)

        // Header
        const header = this.table.createTHead()
        this.headerRow = header.insertRow()

        // Body
        this.body = this.table.createTBody()
    }
}

module.exports = {
    DbTable
}
