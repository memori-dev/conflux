class Persistence {
    storageKey
    value

    persist() {
        localStorage.setItem(this.storageKey, JSON.stringify(this.value))
    }

    constructor(dbName, key, defaultValue) {
        this.storageKey = dbName + "_" + key

        // Build value
        let storedValue = localStorage.getItem(this.storageKey)
        this.value = storedValue !== null ? JSON.parse(storedValue) : defaultValue
    }
}

class DisplayModel {
    // [key (pulled from keyForHeader)]
    // The order of the array represents the order of the headers
    order

    // {
    //    key (pulled from keyForHeader): width (string representing px, doesn't include px in the string)
    // }
    widths

    // TODO overridable min values based on key
    //  return {min, max} named minMax in the read
    slider = {
        min: "120",
        max: "720",
    }

    constructor(dbName) {
        this.order = new Persistence(dbName, "order", [])
        this.widths = new Persistence(dbName, "width", {})
    }
}

module.exports = {
    DisplayModel,
}
