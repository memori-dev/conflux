const {theme} = require("../theme");
const {lm} = require("lm")

const svgs = {
    pointer: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    <path d="M20.978 13.21a1 1 0 0 0-.396-1.024l-14-10a.999.999 0 0 0-1.575.931l2 17a1 1 0 0 0 1.767.516l3.612-4.416 3.377 5.46 1.701-1.052-3.357-5.428 6.089-1.218a.995.995 0 0 0 .782-.769z" fill="currentColor"/>
</svg>`,

    renamer: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    <path d="M8.707 19.707 18 10.414 13.586 6l-9.293 9.293a1.003 1.003 0 0 0-.263.464L3 21l5.242-1.03c.176-.044.337-.135.465-.263zM21 7.414a2 2 0 0 0 0-2.828L19.414 3a2 2 0 0 0-2.828 0L15 4.586 19.414 9 21 7.414z" fill="currentColor"/>
</svg>`,

    download: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    <path d="m12 16 4-5h-3V4h-2v7H8z" fill="currentColor"/>
    <path d="M20 18H4v-7H2v7c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2v-7h-2v7z" fill="currentColor"/>
</svg>`,

    delete: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
    <path d="M112 112l20 320c.95 18.49 14.4 32 32 32h184c17.67 0 30.87-13.51 32-32l20-320" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
    <path stroke="currentColor" stroke-linecap="round" stroke-miterlimit="10" stroke-width="32" d="M80 112h352"/>
    <path d="M192 112V72h0a23.93 23.93 0 0124-24h80a23.93 23.93 0 0124 24h0v40M256 176v224M184 176l8 224M328 176l-8 224" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
</svg>`,

    refresh: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    <path d="M10 11H7.101l.001-.009a4.956 4.956 0 0 1 .752-1.787 5.054 5.054 0 0 1 2.2-1.811c.302-.128.617-.226.938-.291a5.078 5.078 0 0 1 2.018 0 4.978 4.978 0 0 1 2.525 1.361l1.416-1.412a7.036 7.036 0 0 0-2.224-1.501 6.921 6.921 0 0 0-1.315-.408 7.079 7.079 0 0 0-2.819 0 6.94 6.94 0 0 0-1.316.409 7.04 7.04 0 0 0-3.08 2.534 6.978 6.978 0 0 0-1.054 2.505c-.028.135-.043.273-.063.41H2l4 4 4-4zm4 2h2.899l-.001.008a4.976 4.976 0 0 1-2.103 3.138 4.943 4.943 0 0 1-1.787.752 5.073 5.073 0 0 1-2.017 0 4.956 4.956 0 0 1-1.787-.752 5.072 5.072 0 0 1-.74-.61L7.05 16.95a7.032 7.032 0 0 0 2.225 1.5c.424.18.867.317 1.315.408a7.07 7.07 0 0 0 2.818 0 7.031 7.031 0 0 0 4.395-2.945 6.974 6.974 0 0 0 1.053-2.503c.027-.135.043-.273.063-.41H22l-4-4-4 4z" fill="currentColor"/>
</svg>`,
}

const styles = lm.createStyleSheet({
    toolbar: {
        // Flex
        display: "flex",
        flexDirection: "column",
        flexWrap: "wrap",
        justifyContent: "flex-start",
        alignItems: "center",

        // W
        width: `bar.sizeLandscape`,
        gap: `calc(${bar.sizeLandscape} * 0.5)`,
        "@media all and (max-width: 640px)": {
            width: bar.sizePortrait,
            gap: `calc(${bar.sizePortrait} * 0.5)`,
        },

        // H
        height: "100%",

        // Padding
        boxSizing: "border-box",
        padding: "1.5rem 1rem",

        backgroundColor: theme.color.dark.absolute,

        "& svg": {
            width: "50%",
            aspectRatio: 1,

            color: theme.color.white.medium,
        }
    }
})

// TODO selector, pair w select all, download, upload, delete
const tools = {
    pointer: lm.newSvg(svgs.pointer),

    // TODO pencil svg
    // TODO unavailable if name is hidden
    // TODO pencil svg on hover over name
    renamer: lm.newSvg(svgs.renamer),

    // Download (highlight when files are selected)
    download: lm.newSvg(svgs.download),

    // Delete (hightlight when files are selected)
    delete: lm.newSvg(svgs.delete),

    refresh: lm.newSvg(svgs.refresh),
}

const toolbar = (function () {
    let toolbar = lm.new("div", styles.toolbar)

    Object.keys(tools).forEach(function (key) {
        toolbar[key] = tools[key]
        toolbar.appendChild(tools[key])
    })

    return toolbar
})()

module.exports = {
    toolbar,
}
