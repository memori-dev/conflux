import jss from "jss";
import lm  from "@memori-dev/lm";
import fileStoreTable  from "./fileStoreTable.js";
import createFileStore from "./createFileStore.js";
import core            from "../coreStyle.js";
import toast           from "../toast.js";

const classes = jss.createStyleSheet({
	container: {
		display: "flex",
		flexDirection: "column",
		alignItems: "center",
		gap: core.twoch,
	},

	fileStoreContainer: {
		display: "flex",
		flexDirection: "column",
		gap: core.twoch,		
	},
}).attach().classes;

window.onload = async function() {
	const fileStore = createFileStore(1);

	document.body.appendChild(fileStore.modal);
	const center = lm.appendNew(document.body, "div", [core.classes.centerAbs], {});
	const container = lm.appendNew(center, "div", [classes.container], {});

	const heading = lm.appendNew(container, "h1", [core.classes.divHeading], { innerText: "filestores" });
	const fileStoreContainer = lm.appendNew(container, "div", [classes.fileStoreContainer], {});
	container.appendChild(fileStore.btn);

	// load fileStores
	// TODO fade in
	const res = fetch(`/fileStore`, { method: "GET" })
		.then(function(res) {
			return res.json();
		})
		.then(function(data) {
			data.forEach(function(v) {
				fileStoreContainer.appendChild(fileStoreTable.newTable(v.id, v.name));
			});
		})
		.catch(function(err) {
			toast.error("failed to load fileStores");
		});
};
