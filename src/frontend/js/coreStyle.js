import jss from 'jss'
import preset from 'jss-preset-default'
jss.setup(preset());

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

	solidBtn: {
		background: palette.darkPurple,
		border: "none",
		borderRadius: twoch,

		color: palette.white,
		fontSize: "1.75ch",
		padding: ".5ch",

		cursor: "pointer",
	},

	hidden: {
		display: "none",
		opacity: 0,
	},

	dimmer: {
		position: "absolute",
		width: "100%",
		height: "100%",
		background: "rgb(0 0 0 / 25%)",
	},
}).attach().classes;

const FadeState = Object.freeze({
	in:  Symbol("in"),
	out: Symbol("out"),
});

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

	fadeIn: function(e, ms) {
		e.style.transition = `opacity ${ms}ms`;
		e.fadeState = FadeState.in;

		// https://stackoverflow.com/a/64001548
		e.style.display = "block";
		document.body.offsetHeight;
		e.style.opacity = "1";
	},

	fadeOut: function(e, ms) {
		e.style.transition = `opacity ${ms}ms`;
		e.fadeState = FadeState.out;

		e.style.opacity = 0;
		window.setTimeout(function() {
			if (e.fadeState === FadeState.out) e.style.display = "none";
		}, ms);
	},
}
