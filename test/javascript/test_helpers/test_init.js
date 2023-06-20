import React, { Fragment } from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import Adapter from 'enzyme-adapter-react-16'
import { configure } from 'enzyme'

const CSRF_TOKEN = '1234'

const testInit = () => {
  global.$ = global.jQuery = $
  global.React = React

  configure({ adapter: new Adapter() })
  mockWebSockets()
  mockCsrfToken(CSRF_TOKEN)
}

const mockCsrfToken = (token) => {
  const csrfMeta = $('meta[name="csrf-token"]')
  if (csrfMeta.length == 0) {
    let meta = document.createElement('meta')
    meta.setAttribute('name', 'csrf-token')
    meta.innerHTML = token
    document.head.appendChild(meta)
  }
}

const mockWebSockets = () => {
  global.App = {
    cable: {
      subscriptions: {
        create: jest.fn(),
      },
    },
  }
}

testInit()
