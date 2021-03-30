const path = require('path') // resolve path
const fs = require("fs");
const HtmlWebpackPlugin = require('html-webpack-plugin') // create file.html
const MiniCssExtractPlugin = require('mini-css-extract-plugin') // extract css to files
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin') // minify css
const TerserPlugin = require('terser-webpack-plugin') // minify js
const tailwindcss = require('tailwindcss')
const autoprefixer = require('autoprefixer') // help tailwindcss to work
const ImageminPlugin = require('imagemin-webpack-plugin').default // minimize images
const imageminMozjpeg = require('imagemin-mozjpeg') // minimize images
const ip = require('internal-ip')

const infoColor = (_message) =>
{
    return `\u001b[1m\u001b[34m${_message}\u001b[39m\u001b[22m`
}

const localhost = 'app.xu.local';

module.exports = {
	mode: 'development',
	devtool: 'eval-cheap-source-map',
	devServer: {
		contentBase: path.join(__dirname, "../dist"),
		allowedHosts: [localhost, "localhost"],
		public: localhost,
		port: 443,
		https: {
			key: fs.readFileSync("https/key"),
			cert: fs.readFileSync("https/crt")
		},
		historyApiFallback: true,
		watchOptions: {
		ignored: /node_modules/
    },
	after: function(app, server, compiler)
            {
                const port = server.options.port
                const https = server.options.https ? 's' : ''
                const localIp = ip.v4.sync()
                const domain1 = `http${https}://${localIp}:${port}`
                const domain2 = `http${https}://${localhost}`
                
                console.log(`Project is running at:\n  - ${infoColor(domain1)}\n  - ${infoColor(domain2)}`)
            }
	},

	resolve: {
		extensions: ['.js', '.jsx', '.ts', '.tsx'], // import without .ts or .tsx etc....
		alias: {
			"@": path.resolve(__dirname, "../src/") // for IDE only, the main alias is in .babelrc
		}
	},
	entry: {
		index: path.join(__dirname, '../src/index.tsx')
	},

	output: {
		publicPath: '',
		path: path.resolve(__dirname, '../dist'),
		filename: '[name].[hash].bundle.js' // for production use [contenthash], for developement use [hash]
	},
	plugins: [
		new MiniCssExtractPlugin({ filename: '[name].[contenthash].css', chunkFilename: '[id].[contenthash].css' }),
		new HtmlWebpackPlugin({
			template: path.join(__dirname, '../index.html')
		}),
		new ImageminPlugin({
			// minimize images
			pngquant: { quality: [0.5, 0.5] },
			plugins: [imageminMozjpeg({ quality: 50 })]
		})
	],

	optimization: {
		minimizer: [new TerserPlugin(), new OptimizeCssAssetsPlugin({})],

		moduleIds: 'deterministic',
		runtimeChunk: 'single',
		splitChunks: {
			cacheGroups: {
				vendor: {
					test: /[\\/]node_modules[\\/]/,
					name: 'vendors',
					chunks: 'all'
				}
			}
		}
	},

	module: {
		rules: [
			{
				test: /\.(css|scss|sass)$/,
				use: [
					MiniCssExtractPlugin.loader,
					'css-loader',
					'sass-loader',
					{
						loader: 'postcss-loader', // postcss loader needed for tailwindcss
						options: {
							postcssOptions: {
								ident: 'postcss',
								plugins: [tailwindcss, autoprefixer]
							}
						}
					}
				]
			},
			{
				test: /\.(png|svg|jpg|gif)$/i,
				use: ['file-loader']
			},
			{
				test: /\.html$/,
				use: [{ loader: 'html-loader' }]
			},
			{
				test: /\.(js|jsx|ts|tsx)$/,
				exclude: /(node_modules|bower_components|prod)/,
				use: {
					loader: 'babel-loader',
					options: {
						presets: ['@babel/preset-env', '@babel/preset-react', '@babel/preset-typescript']
					}
				}
			}
		]
	}
}
