import jss from "jss";
import lm  from "@memori-dev/lm";
import fileStoreTable  from "./fileStoreTable.js";
import createFileStore from "./createFileStore.js";
import core            from "../coreStyle.js";
import toast           from "../toast.js";

const classes = jss.createStyleSheet({
	container: {
		display: "flex",
		alignItems: "center",
		justifyContent: "start",
		gap: core.twoch,
		flexDirection: "column",
		height: "90vh",
		padding: "5vh",
	},

	fileStoreContainer: {
		display: "flex",
		flexDirection: "column",
		gap: core.twoch,
		maxWidth: "90%",
		overflowY: "scroll",
		padding: "0 " + core.twoch,
	},
}).attach().classes;

window.onload = async function() {
	const container = lm.appendNew(document.body, "div", [classes.container], {});

	const heading = lm.appendNew(container, "h1", [core.classes.divHeading], { innerText: "filestores" });
	const fileStoreContainer = lm.appendNew(container, "div", [classes.fileStoreContainer], {});

	const fileStore = createFileStore(1, function(id, name) {
		fileStoreContainer.appendChild(fileStoreTable.newTable(id, name));
	});
	document.body.appendChild(fileStore.modal);
	container.appendChild(fileStore.btn);

	// load fileStores
	// TODO transition in
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
