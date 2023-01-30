const NavView = require("./view")
const MenuController = require("./menu/controller")

class NavController {
    // TODO set name
    view

    menuController

    constructor() {
        this.view = new NavView()

        this.menuController = new MenuController()
        this.menuController.view.toggleHide()
    }
}

module.exports = NavController
