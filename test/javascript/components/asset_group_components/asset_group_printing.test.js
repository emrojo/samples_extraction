import React from 'react'
import { shallow, mount } from 'enzyme'
import { Response } from 'miragejs'

import '../../test_helpers/test_init'

import { buildAssetGroupData, tubePrinterOptions, platePrinterOptions } from '../../test_helpers/factories'

import AssetGroupPrinting from 'asset_group_components/asset_group_printing'
import { startMirage } from '../../test_helpers/_mirage_'

describe('AssetGroupPrinting', () => {
  let mirageServer

  beforeEach(() => {
    mirageServer = startMirage()
  })

  afterEach(() => {
    mirageServer.shutdown()
  })

  const props = (assetCount = 3, overrides = {}) => ({
    assetGroup: buildAssetGroupData(1, assetCount),
    platePrinter: platePrinterOptions(),
    tubePrinter: tubePrinterOptions(),
    onMessage: () => {},
    ...overrides,
  })

  it('renders a form', () => {
    const wrapper = shallow(<AssetGroupPrinting {...props()} />)
    expect(wrapper.find('FormFor')).toHaveLength(1)
  })

  it('renders printer selectors', () => {
    const wrapper = shallow(<AssetGroupPrinting {...props()} />)
    expect(wrapper.find('PrintersSelection')).toHaveLength(1)
  })

  it('is hidden when we have no assets', () => {
    const wrapper = shallow(<AssetGroupPrinting {...props(0)} />)
    expect(wrapper.find('FormFor')).toHaveLength(0)
  })

  it('changes the selected tube printer in the react state', () => {
    const wrapper = mount(<AssetGroupPrinting {...props()} />)
    expect(wrapper.instance().state.Tube).toEqual('printer 2')
    wrapper
      .find({ name: 'tube_printer_select' })
      .first()
      .simulate('change', { target: { value: 1 } })
    expect(wrapper.instance().state.Tube).toEqual('printer 1')
  })

  it('changes the selected plate printer in the react state', () => {
    const wrapper = mount(<AssetGroupPrinting {...props()} />)
    expect(wrapper.instance().state.Plate).toEqual('printer 14')
    wrapper
      .find({ name: 'plate_printer_select' })
      .first()
      .simulate('change', { target: { value: 2 } })
    expect(wrapper.instance().state.Plate).toEqual('printer 3')
  })

  it('reports successful requests', (done) => {
    const onMessage = jest.fn(({ type, msg }) => {
      expect(type).toEqual('success')
      expect(msg).toEqual('Printed')
      done()
    })

    const wrapper = mount(<AssetGroupPrinting {...props(2, { onMessage })} />)
    expect(wrapper.instance().state.Plate).toEqual('printer 14')
    wrapper
      .find({ name: 'plate_printer_select' })
      .first()
      .simulate('change', { target: { value: 2 } })

    wrapper.find('form').simulate('submit')
  })

  it('reports failed requests', (done) => {
    const onMessage = jest.fn(({ type, msg }) => {
      console.log({ type, msg })
      expect(type).toEqual('danger')
      expect(msg).toEqual('Broken')
      done()
    })

    mirageServer.post('asset_groups/:id/print', (_schema, _request) => {
      return new Response(400, {}, { success: false, message: 'Broken' })
    })

    const wrapper = mount(<AssetGroupPrinting {...props(2, { onMessage })} />)
    expect(wrapper.instance().state.Plate).toEqual('printer 14')
    wrapper
      .find({ name: 'plate_printer_select' })
      .first()
      .simulate('change', { target: { value: 2 } })

    wrapper.find('form').simulate('submit')
  })
})
