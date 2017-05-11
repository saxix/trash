"use strict";
var webpack = require("webpack");
var fs = require("fs");
var StringReplacePlugin = require("string-replace-webpack-plugin");
const rel = require("path").resolve.bind(null, __dirname);
var dateFormat = require('dateformat');
var now = new Date();

const VERSION = require("./package.json").version;
const INFOS = "@version 1\n@date 2".replace(/1/, VERSION).replace(/2/, dateFormat(now, "dddd, mmmm dS yyyy HH:MM:ss"));

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
                test: /(index\.js)$/,
                loader: StringReplacePlugin.replace({
                    replacements: [
                        {
                            pattern: /%VERSION%/ig,
                            replacement: function (match, p1, offset, string) {
                                return VERSION;
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
            VERSION: JSON.stringify(VERSION)
        }),
        new webpack.optimize.UglifyJsPlugin({
            include: /\.min\.js$/,
            compress: {warnings: false},
            comments: false,
            minimize: true
        }),
        new webpack.BannerPlugin({
            banner: fs.readFileSync("./LICENSE", "utf8").replace(/^--$/mg, INFOS),
            raw: false, entryOnly: true
        })
    ],
    devtool: "hidden-source-map",
    externals: {},
    watch: false,
    watchOptions: {
        aggregateTimeout: 300,
        ignored: ["/node_modules/", "docs", "dist", "test"],
        poll: 1000
    }
};
