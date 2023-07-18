import {MenuModel} from "./model"
import {MenuView} from "./view"
import {lm} from "lm"

export class MenuController {
    model: MenuModel
    view: MenuView

    constructor() {
        this.model = new MenuModel()
        this.view = new MenuView()

        this.view.createDatabaseButton.onclick = async function (this: MenuController) {
            const db = await this.model.databaseCreate()
            this.view.ownDatabases.appendChild(
                db.Id,
                db.Name,
                function () {
                    // TODO load database
                    debugger
                },
            )
        }.bind(this)

        this.model.profileRead().then(function (this: MenuController) {
            this.view.profileName.innerText = this.model.profileData.Name

            const profilePicture = lm.new("img")
            profilePicture.src = "data:image/png;base64," + atob(this.model.profileData.ImageB64)
            this.view.profilePicture.replaceWith(profilePicture)
        }.bind(this))

        this.model.databaseRead().then(function (this: MenuController) {
            for (let i = 0; i < this.model.ownDatabases.length; i++) {
                this.view.ownDatabases.appendChild(
                    this.model.ownDatabases[i].Id,
                    this.model.ownDatabases[i].Name,
                    function () {
                        // TODO handle this
                    },
                )
            }
        }.bind(this))
    }
}
