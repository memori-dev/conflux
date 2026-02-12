import lm  from "@memori-dev/lm";
import jss from 'jss'
import preset from 'jss-preset-default'
jss.setup(preset());

// TODO fonts

const palette = {
	white:      "#EAEAEA",
	lightBlack: "#171212",
	black:      "#0A0A0A",

	lightPurple: "#893168",
	purple:      "#4A1942",
	darkPurple:  "#2E1C2B",
};

const twoch = "2ch";

const classes = jss.createStyleSheet({
	'@global': {
		// disables visibly highlighting text
		"::selection": {
			textShadow: "none",
		},

		// TODO add light highlighting of field when focused for accessibility
		"textarea:focus": {
			outline: "none",
		},
		"input:focus": {
			outline: "none",
		},
	},

	// utils
	divHeading: {
		textAlign: "center",
		color: palette.white,
		margin: 0,
		borderBottom: `solid ${palette.purple} 0.1ch`,
	},

	centerAbs: {
		position: "absolute",
		top: "50%",
		left: "50%",
		transform: "translate(-50%, -50%)",
	},

	inputText: {
		background: "none",
		border: "none",
		borderBottom: "#fff solid 0.25ch",
		color: palette.white,
		fontSize: twoch,
	},

	solidBtn: {
		background: palette.darkPurple,
		border: "none",
		borderRadius: twoch,

		color: palette.white,
		fontSize: "1.75ch",
		padding: ".5ch 2ch",

		cursor: "pointer",
	},

	hidden: {
		display: "none",
		opacity: 0,
	},

	dimmer: {
		position: "absolute",
		width: "100vw",
		height: "100vh",
		background: "rgb(0 0 0 / 80%)",
	},
}).attach().classes;

// TODO this needs cleaning up
// https://css-tricks.com/transitioning-to-auto-height/
// `height: auto` does not transition on firefox
const transitionHeight = lm.new("style", [], {});
transitionHeight.textContent = `.transitionHeight {
	display: block;
	overflow: hidden;
	height: 0;

	transition: height 750ms ease-in-out;
	transition-behavior: allow-discrete;

	@starting-style {
		height: 0;
	}
}`
document.head.appendChild(transitionHeight);
classes.transitionHeight = "transitionHeight";

export default {
	palette: palette,
	twoch:   twoch,
	classes: classes,

	isHidden: function(e) {
		return e.classList.contains(classes.hidden);
	},

	hide: function(e) {
		if (!this.isHidden(e)) e.classList.add(classes.hidden);
	},

	show: function(e) {
		if (this.isHidden(e)) e.classList.remove(classes.hidden);
	},

	// TODO function to invert classes.hidden

	fadeIn: function(e, ms) {
		e.style.transition = `opacity ${ms}ms`;

		// https://stackoverflow.com/a/64001548
		e.style.display = "block";
		document.body.offsetHeight;
		e.style.opacity = 1;
	},
	fadeOut: function(e, ms) {
		e.style.transition = `opacity ${ms}ms`;

		e.style.opacity = 0;
		
		const closuredNow = performance.now();
		e.lastFadeOutCalled = closuredNow;
		window.setTimeout(function() {
			if (e.style.opacity === "0" && e.lastFadeOutCalled === closuredNow) e.style.display = "none";
		}, ms);
	},

	isCollapsed: function(e) {
		return e.style.height === "";
	},

	collapse: function(e) {
		e.style.height = "";
	},

	expand: function(e, height) {
		e.style.height = height;
	},

	transitionHeight(e, height) {
		e.style.height = this.isCollapsed(e) ? height : "";
	},
}
