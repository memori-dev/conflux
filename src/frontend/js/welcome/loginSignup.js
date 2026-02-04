import jss from "jss";
import lm  from "lm";
import core  from "../coreStyle.js";
import toast from "../toast.js";

const classes = jss.createStyleSheet({
	form: {
		margin: core.twoch,
		display: "flex",
		flexDirection: "column",
		gap: core.twoch,
		backgroundColor: core.palette.lightBlack,
		borderRadius: core.twoch,
		padding: core.twoch,
	},

	inputText: {
		background: "none",
		border: "none",
		borderBottom: "#fff solid 0.25ch",
		color: core.palette.white,
		fontSize: core.twoch,
	},
}).attach().classes;

const fadeSpeed = 750;

// container
const container = lm.new("div", [core.classes.dimmer, core.classes.hidden], {});
const center = lm.appendNew(container, "div", [core.classes.centerAbs], {});

// form
const form = lm.appendNew(center, "form", [classes.form], { method: "POST" });
const heading = lm.appendNew(form, "h1", [core.classes.divHeading], {})
// TODO replace with appendInput
const name = lm.appendNew(form, "input", [classes.inputText], {
	type: "text",
	name: "name",
	placeholder: "name"
});
// TODO button to show password
const pass = lm.appendNew(form, "input", [classes.inputText], {
	type: "password",
	name: "pass",
	placeholder: "password"
});
// TODO confirm password & validation
const submit = lm.appendNew(form, "input", [core.classes.solidBtn], {
	type: "submit",
	value: "submit"
});

// hide form on click outside
container.addEventListener("click", function(e) {
	if (!form.contains(e.target)) core.fadeOut(container, fadeSpeed);
});

// https://dev.to/amjadmh73/submit-html-forms-to-json-apis-easily-137l
// TODO validate name & pass
form.addEventListener("submit", async function(e) {
	e.preventDefault();
	const res = await fetch(form.action, {
		method: form.method,
		headers:{ "content-type": "application/json" },
		"body": JSON.stringify({
			[name.name]: name.value,
			[pass.name]: pass.value,
		}),
	});

	if (res.ok) {
		submit.disabled = true;
		toast.success("logging in");

		// TODO redirect?
		window.setTimeout(function() { window.location.reload(); }, 500);
	}
	else {
		// TODO better error handling
		toast.error(`failed: ${res.statusText.toLowerCase()}`);
	}
});

// hide form on esc
function keydownHandler(e) {
	if (e.key == "Escape") core.fadeOut(container, fadeSpeed);
}

export default {
	container: container,
	form:      form,
	heading:   heading,
	name:      name,
	pass:      pass,

	show: function(z, endpoint, name) {
		this.container.style["z-index"] = z;

		this.name.value = name;
		this.heading.innerText = endpoint;
		this.form.action = endpoint;

		core.fadeIn(container, fadeSpeed);
		document.body.addEventListener("keydown", keydownHandler);

		switch (endpoint) {
			case "login":
				this.pass.focus();
				break;
			case "signup":
				this.name.focus();
				break;
			default:
				throw new Error(`home.js: unknown endpoint ${endpoint}`);
		}
	},

	hide: function() {
		document.body.removeEventListener("keydown", keydownHandler);
		core.fadeOut(container, fadeSpeed);
	}
};
