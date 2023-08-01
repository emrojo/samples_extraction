const getCsrfToken = () => {
  const csrfMeta = $('meta[name="csrf-token"]')
  if (csrfMeta.length == 1) {
    return csrfMeta.attr('content')
  }
  return null
}

const uploaderOptions = (props) => {
  return {
    options: {
      validation: {
        sizeLimit: 12000000,
      },
      chunking: {
        enabled: false,
      },
      deleteFile: {
        enabled: true,
        endpoint: '/asset_groups/' + props.assetGroup.id + '/upload',
      },
      request: {
        endpoint: '/asset_groups/' + props.assetGroup.id + '/upload',
        customHeaders: { 'X-CSRF-Token': getCsrfToken() },
      },
      retry: {
        enableAuto: true,
      },
      callbacks: {
        onError: function (id, name, errorReason, xhrOrXdr) {
          props.onErrorMessage({ type: 'danger', msg: errorReason })
        },
      },
    },
  }
}

export { getCsrfToken, uploaderOptions }
