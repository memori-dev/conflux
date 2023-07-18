import {createTheme, globalStyle} from '@vanilla-extract/css';

export const [_, theme] = createTheme({
    font: {
        fontFamily: `'Montserrat SemiBold', Helvetica, sans-serif`,
    },

    color: {
        dark: {
            absolute: "#000000",
            primary: "#0D0D0D",
            secondary: "#0E0B26",
        },
        medium: {
            primary: "#161040",
            secondary: "#251659",
            tertiary: "#3B0273",
        },
        light: {
            primary: "#816797",
            secondary: "#F582A7",
        },
        white: {
            absolute: "#FFFFFF",
            light: "#E6E6E6",
            medium: "#C4C4C4",
            dark: "#A0A0A0",
        },
        gray: {
            light: "#898989",
            medium: "#6C6C6C",
            dark: "#3F3F3F",
        }
    },
})

globalStyle("html, body", {
    // Full page
    width: "100vw",
    minHeight: "100vh",
    margin: 0,

    backgroundColor: theme.color.dark.primary,

    // Hide overflow
    msOverflowStyle: "none", // Internet Explorer 10+
    scrollbarWidth: "none", // Firefox
    overscrollBehaviorY: "none",
})

globalStyle("html::-webkit-scrollbar, body::-webkit-scrollbar", {
    display: "none", // Safari and Chrome
})
