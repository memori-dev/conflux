import jss from "jss";
import lm  from "@memori-dev/lm";
import core from "../coreStyle.js";

// TODO file modal that shows all file info. Just create one element and copy over all of the properties of the clicked row before displaying

// TODO uploads
//	<form method=post action=/file enctype="multipart/form-data">
//		<input name=file type=file required/>
//		<button type=submit>Submit</button>

const angleBracketSvg = `
	<svg width="${core.twoch}" height="${core.twoch}" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
		<polyline
			points="30,20 70,50 30,80"
			fill="none"
			stroke="${core.palette.white}"
			stroke-width="8"
			stroke-linecap="round"
			stroke-linejoin="round"
		/>
	</svg>
`;

const classes = jss.createStyleSheet({
	heading: {
		display: "flex",
		alignItems: "center",
		justifyContent: "space-between",
		background: "rgb(255 255 255 / 5%)",
		borderRadius: `${core.twoch} ${core.twoch} 0 0`,
		transition: `border-radius 250ms ease-out`,
		padding: "0 " + core.twoch,
		cursor: "pointer",
	},

	// TODO fix hardcoding
	angleBracket: {
		transition: "transform 750ms",
	},

	angleBracketRotate: {
		transform: "rotate(90deg)",
	},

	fullRadius: {
		borderRadius: core.twoch,
	},

	name: {
		color: core.palette.white,
		fontWeight: "bolder",
	},

	table: {
		color: core.palette.white,
		background: "rgb(255 255 255 / 10%)",
		overflowY: "scroll",
	},

	// TODO make non global
	"@global": {
		td: {
			padding: "0.5ch 1ch",
		},
		th: {
			padding: "0.5ch 1ch",
		},
	}
}).attach().classes;

// TODO filtering files
// TODO option to show/hide columns
// TODO fileStore info (id, owner, ts, file count, total size) and server side caching layer for file count and total size
// TODO column header clickable to change sorting (refresh on sort)
// TODO accessed history?
// TODO checkbox to persist a file through reloads?
function fileStoreTable(id, name) {
	const container = lm.new("div", [], {});

	// TODO make heading a button to allow for tabbing
	const heading = lm.appendNew(container, "div", [classes.heading, classes.fullRadius], { fsId: id });
	const fsName = lm.appendNew(heading, "p", [classes.name], { innerText: name });
	const angleSvg = lm.appendNewSvg(heading, angleBracketSvg, [classes.angleBracket]);

	// TODO sticky header row
	// TODO scrollable
	const table = lm.appendNew(container, "table", [classes.table, core.classes.transitionHeight], {});
	const row = lm.appendNew(table, "tr", [], {});
	lm.appendNew(row, "th", [], {innerText: "id"});
	lm.appendNew(row, "th", [], {innerText: "parent"});
	lm.appendNew(row, "th", [], {innerText: "ts"});
	lm.appendNew(row, "th", [], {innerText: "name"});
	lm.appendNew(row, "th", [], {innerText: "created"});
	lm.appendNew(row, "th", [], {innerText: "size"});
	lm.appendNew(row, "th", [], {innerText: "blake3"});
	lm.appendNew(row, "th", [], {innerText: "complete"});
	lm.appendNew(row, "th", [], {innerText: "trash"});

	heading.addEventListener("click", function() {
		// TODO fix hardcoding
		if (!core.isCollapsed(table)) {
			angleSvg.classList.remove(classes.angleBracketRotate);
			// TODO clean up transition OR include a footer to avoid the transition entirely
			window.setTimeout(function() {
				if (core.isCollapsed(table)) heading.classList.add(classes.fullRadius);
			}, 750)
		}
		else {
			heading.classList.remove(classes.fullRadius);
			angleSvg.classList.add(classes.angleBracketRotate);
		}

		// TODO needs calculation w row height * max rows allowed
		core.transitionHeight(table, "4ch");
	})

	return container;
}

function newFileRow(file) {
	// TODO every element's innerText should be click to copy
	const row = lm.new("tr", [], {});
	lm.appendNew(row, "td", [], {innerText: file.id});
	lm.appendNew(row, "th", [], {innerText: file.parent});
	lm.appendNew(row, "td", [], {innerText: file.ts});
	lm.appendNew(row, "td", [], {innerText: file.name});
	lm.appendNew(row, "td", [], {innerText: file.created});
	// TODO this should be in kb,mb,gb,... to keep short
	lm.appendNew(row, "td", [], {innerText: file.size});
	// TODO just last 8, but hover show full?
	lm.appendNew(row, "td", [], {innerText: file.blake3});
	lm.appendNew(row, "td", [], {innerText: file.complete});
	lm.appendNew(row, "td", [], {innerText: file.trash});	

	return row;
}

export default {
	newTable: fileStoreTable,
	newRow: newFileRow,
};
