import {DbController} from "./database/controller"
import NavController from "./nav/controller"
import {toolbar} from "./toolbar"
import {bar} from "./bar"
import {lm} from "lm"

const svgs = {
    upload: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    <path d="M11 15h2V9h3l-4-5-4 5h3z" fill="currentColor"/>
    <path d="M20 18H4v-7H2v7c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2v-7h-2v7z" fill="currentColor"/>
</svg>`,

    display: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
    <circle cx="12" cy="12" r="2"/>
    <path d="M22 12c-2.667 4.667 -6 7 -10 7s-7.333 -2.333 -10 -7c2.667 -4.667 6 -7 10 -7s7.333 2.333 10 7"/>
</svg>`,
}


const styles = lm.createStyleSheet({
    main: {
        // Position
        position: "fixed",
        top: bar.sizeLandscape,
        left: 0,

        width: "100vw",
        height: "calc(100vh - #{bar.$sizeLandscape})",

        "@media all and (max-width: 640px)": {
            top: bar.sizePortrait,
            height: `calc(100vh - ${bar.sizePortrait})`,
        },

        // Flex
        display: "flex",
        flexDirection: "row",
        alignItems: "flex-start",
        justifyContent: "flex-start",
    },
})

// TODO Preview
// TODO auto tags based on extension, eg. png, jpg, etc have an image auto tag

// Nav
const navController = new NavController()
lm.append(document.body, navController.view.nav)
lm.append(document.body, navController.menuController.view.div)
// TODO
// navController.menuController

// Main
const main = lm.appendNew(document.body, "main", styles.main)

// Table
// TODO
const dbController = new DbController("My Db")
// dbController.loadFiles()

// Hide the settingsContainer
dbController.displayController.view.mainContainer.style.visibility = "hidden"

// Upload
const upload = lm.appendNewInput(toolbar, "file", "upload")
upload.input.style.display = "none"
const uploadSvg = lm.appendNewSvg(upload.label, svgs.upload)
// TODO upload
// elem.onchange = async function () {
//     let res = await Storage.upload.fetch(this.files[0])
//     if (!responseIsValid(Storage.upload.endpoint, res)) notyf.error("Failed to upload file: " + res.statusText)
// }

// Toggler
// TODO accessibility
const togglerIsActiveClass = "togglerActive"
const displayToggler = lm.appendNewSvg(toolbar, svgs.display)
// TODO onclick outside of settingsdiv, untoggle
displayToggler.onclick = function (this: ) {
    // View
    const isVisible = this.view.mainContainer.style.visibility === "visible"

    // Toggle settings div visibility
    this.view.mainContainer.style.visibility = isVisible ? "hidden" : "visible"

    // Reset the container height
    if (!isVisible) this.view.mainContainer.style.maxHeight = this.view.mainContainerMinHeight + "%"

    // Toggle the togglerIsActiveClass
    displayToggler.classList.toggle(togglerIsActiveClass)
}.bind(dbController.displayController)

lm.append(main, toolbar);
lm.append(main, dbController.tableView.table);
