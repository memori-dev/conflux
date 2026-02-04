import lm from "lm";
import jss from "jss";
import core from "./coreStyle.js";

const classes = jss.createStyleSheet({
	container: {
		position: "absolute",
		top: core.twoch,
		right: core.twoch,
		// TODO will likely need work
		minWidth: "12ch",
		maxWidth: "24ch",
		maxHeight: "48ch",
		overflowY: "scroll",

		display: "flex",
		flexDirection: "column",
		alignItems: "end",
		gap: core.twoch,
	},

	toast: {
		borderRadius: "0.33ch",
		gap: "1ch",
		padding: "1ch",
		// max z index
		zIndex: 2147483647,
		color: "#fff",
		cursor: "pointer",
	},

	text: { margin: 0 },

	error: { background: "#E84855" },

	success: { background: "#1B998B" },
}).attach().classes;

let fadeSpeed = 250;
let ttl = 5000;
const container = lm.appendNew(document.body, "div", [classes.container], {});

export default {
	new: function(heading, msg, color) {
		const toast = lm.prependNew(container, "div", [classes.toast, core.classes.hidden, color], {});
		lm.appendNew(toast, "p", [classes.text], { innerText: msg });

		var closeOnce = (function() {
			let executed = false;
			
			return function close() {
				if (executed) return;
				executed = true;
				
				toast.removeEventListener("click", close)
				core.fadeOut(toast, fadeSpeed);
				window.setTimeout(function() {
					toast.remove()
				}, fadeSpeed);
			};
		})();

		core.fadeIn(toast, fadeSpeed);

		// close on click
		toast.addEventListener("click", closeOnce);
		// close after ttl
		window.setTimeout(closeOnce, ttl);
	},

	error: function(msg) {
		this.new("error", msg, classes.error);
	},

	success: function(msg) {
		this.new("success", msg, classes.success);
	},

	// TODO clear
};
