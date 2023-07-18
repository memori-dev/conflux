const path = require("path");

module.exports = {
    // mode: "production",
    mode: "development",
    entry: {
        profile: './frontend/profile/main.ts',
        // pageTwo: './frontend/pageTwo/index.js',
        // pageThree: './frontend/pageThree/index.js',
    },
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                use: "ts-loader",
                exclude: [
                    /node_modules/,
                ]
            },
        ],
    },
    resolve: {
        // extensions: [".tsx", ".ts", ".js"],
        extensions: [".ts", ".js"],
    },
    output: {
        filename: '[name].js',
        // path: __dirname + '/dist',
        path: path.resolve(__dirname, "frontend", "dist"),
    },
};
