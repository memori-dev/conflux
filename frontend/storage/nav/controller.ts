import {NavView} from "./view"
import {MenuController} from "./menu/controller"

export class NavController {
    // TODO set name
    view: NavView

    menuController

    constructor() {
        this.view = new NavView()

        this.menuController = new MenuController()
        this.menuController.view.toggleHide()
    }
}
