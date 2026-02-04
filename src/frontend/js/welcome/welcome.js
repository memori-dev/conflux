import jss from "jss";
import lm  from "lm";
import loginSignup from "./loginSignup.js";
import core        from "../coreStyle.js";

const classes = jss.createStyleSheet({
	container: {
		display: "flex",
		flexDirection: "column",
		gap: core.twoch,

		color: core.palette.white,
	},

	namesContainer: {
		display: "flex",
		flexDirection: "column",
		gap: core.twoch,

		overflow: "scroll",
		maxHeight: "50vh", // TODO needs work
		maxWidth: "22ch", // TODO clamp for smaller screens @ like 90vw
	},

	name: {
		background: "none",
		border: "none",
		
		color: core.palette.white,
		fontSize: core.twoch,
		textAlign: "left",

		cursor: "pointer",
	}
}).attach().classes;

function accBtn(name) {
	let btn = lm.new("button", [classes.name], {innerText: name});
	btn.addEventListener("click", function() { loginSignup.show(1, "login", name); });
	return btn;
}

async function welcome() {
	const center = lm.new("div", [core.classes.centerAbs, core.classes.hidden], {});
	const container = lm.appendNew(center, "div", [classes.container], {});

	lm.appendNew(container, "h1", [core.classes.divHeading], {innerText: "welcome ~/"});

	const namesContainer = lm.appendNew(container, "div", [classes.namesContainer], {});

	const signup = lm.appendNew(container, "button", [core.classes.solidBtn], {innerText: "new account"});
	signup.addEventListener("click", function() { loginSignup.show(1, "signup", null); });

	// TODO error handling
	// load user names
	const res = await fetch("usernames", { method: "get" });
	// TODO better res handling
	const names = await res.json(); // TODO assert is array of strings
	names.forEach(function(e) {
		namesContainer.appendChild(accBtn(e));
	});

	return center;
};

window.onload = async function() {
	const main = lm.appendNew(document.body, "main", [], {});
	
	main.appendChild(loginSignup.container);

	const welcomeContainer = await welcome();
	main.appendChild(welcomeContainer);
	core.fadeIn(welcomeContainer, 750);	
};
