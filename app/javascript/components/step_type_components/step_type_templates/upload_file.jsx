import React, { Component } from 'react'

import FineUploaderTraditional from 'fine-uploader-wrappers'
import Gallery from 'react-fine-uploader'

// ...or load this specific CSS file using a <link> tag in your document
import 'react-fine-uploader/gallery/gallery.css'

import { uploaderOptions } from '../../lib/uploader_utils'

class UploadFile extends Component {
  render() {
    return <Gallery uploader={new FineUploaderTraditional(uploaderOptions(this.props))} />
  }
}

export default UploadFile
