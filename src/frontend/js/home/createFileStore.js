import jss from "jss";
import lm  from "@memori-dev/lm";
import core  from "../coreStyle.js";
import toast from "../toast.js";

const classes = jss.createStyleSheet({
	center: {
		display: "flex",
		alignItems: "center",
		gap: core.twoch,
	},
}).attach().classes;

const btn = lm.new("button", [core.classes.solidBtn], { innerText: "new", style: "padding: 1ch 2ch;" });

const modal = lm.new("div", [core.classes.dimmer, core.classes.hidden], {});
const center = lm.appendNew(modal, "div", [core.classes.centerAbs, classes.center], {});

// TODO replace with appendInput
const name = lm.appendNew(center, "input", [core.classes.inputText], {
	type: "text",
	name: "name",
	placeholder: "name"
});
const submit = lm.appendNew(center, "input", [core.classes.solidBtn], {
	type: "submit",
	value: "submit"
});

submit.addEventListener("click", async function() {
	submit.disabled = true;
	const res = await fetch(`/fileStore?${name.name}=${name.value}`, { method: "POST" });

	if (res.ok) {
		toast.success("created fileStore");
		// hide modal
		// TODO add new filestore in the page
	}
	else {
		// TODO better error handling
		toast.error(`failed: ${res.statusText.toLowerCase()}`);
	}
});

const fadeSpeed = 750;

// hide form on esc and submit on enter
function keydownHandler(e) {
	if (e.key == "Escape") core.fadeOut(modal, fadeSpeed);
	if (e.key == "Enter") submit.click();
}

// TODO click outside of center calls hideModal
function showModal(z) {
	modal.style["z-index"] = z;
	
	core.fadeIn(modal, fadeSpeed);
	document.body.addEventListener("keydown", keydownHandler);
	name.focus();
}

function hideModal() {
	document.body.removeEventListener("keydown", keydownHandler);
	core.fadeOut(modal, fadeSpeed);
}

export default function(z) {
	btn.addEventListener("click", function() { showModal(z) });

	return {
		btn: btn,
		modal: modal,

		show: showModal,
		hide: hideModal,
	};
};
