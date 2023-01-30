const bar = {
    sizeLandscape: "min(calc(4rem + 1vmax), 96px)",
    fontSizeLandscape: `calc(${this.sizeLandscape} * 0.5)`,

    sizePortrait: "6rem",
    fontSizePortrait: `calc(${this.sizePortrait} * 0.5)`,
}

module.exports = {
    bar,
}
