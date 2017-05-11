"use strict";
var webpack = require("webpack");
var fs = require("fs");
var StringReplacePlugin = require("string-replace-webpack-plugin");
const rel = require("path").resolve.bind(null, __dirname);

module.exports = {
    context: rel("src"),
    entry: {
        "owlette.min": "./index.js",
        "owlette": "./index.js"
    },
    output: {
        path: rel("dist"),
        filename: "[name].js",
        library: "owlette",
        libraryTarget: "umd"
    },
    module: {
        loaders: [
            {
                test: /(client\.js|LICENSE)$/,
                loader: StringReplacePlugin.replace({
                    replacements: [
                        {
                            pattern: /%VERSION%/ig,
                            replacement: function (match, p1, offset, string) {
                                return require("./package.json").version;
                            }
                        }
                    ]
                })
            }
        ]
    },
    plugins: [
        new StringReplacePlugin(),

        new webpack.LoaderOptionsPlugin({
            minimize: true
        }),
        new webpack.DefinePlugin({
            VERSION: JSON.stringify(require("./package.json").version)
        }),
        new webpack.optimize.UglifyJsPlugin({
            include: /\.min\.js$/,
            compress: {warnings: false},
            comments: false,
            minimize: true
        }),
        new webpack.BannerPlugin({
            banner: fs.readFileSync("./LICENSE", "utf8"),
            raw: false, entryOnly: true
        })
    ],
    devtool: "hidden-source-map",
    externals: {
    },
    watch: false,
    watchOptions: {
        aggregateTimeout: 300,
        ignored: ["/node_modules/", "docs", "dist", "test"],
        poll: 1000
    }
};
