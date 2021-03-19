const CompressionPlugin = require('compression-webpack-plugin')

module.exports = {
  chainWebpack(config) {
    config.plugins.delete('prefetch')

    // and this line
    config.plugin('CompressionPlugin').use(CompressionPlugin)
  },
  // lintOnSave: false,

  configureWebpack: {
    devtool: 'source-map',
    optimization: {
      splitChunks: {
        minSize: 100000,
        maxSize: 500000
      }
    }
  }
}
