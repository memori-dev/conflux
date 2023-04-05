export const bar = {
    sizeLandscape: "min(calc(4rem + 1vmax), 96px)",
    get fontSizeLandscape() {
        return `calc(${bar.sizeLandscape} * 0.5)`
    },

    sizePortrait: "6rem",
    get fontSizePortrait() {
        return `calc(${bar.sizePortrait} * 0.5)`
    },
}
