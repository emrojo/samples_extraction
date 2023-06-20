import React from 'react'
import { shallow, mount } from 'enzyme'

import '../test_helpers/test_init'
import { buildActivityState } from '../test_helpers/factories'

import Activity from 'activity'

describe('Activity', () => {
  it('renders Activity component', () => {
    const wrapper = shallow(<Activity {...buildActivityState(1, 0)} />)
    expect(wrapper.find('div')).toHaveLength(1)
  })

  it('renders only one AssetGroupEditor component', () => {
    const wrapper = mount(<Activity {...buildActivityState(2, 0)} />)
    expect(wrapper.find('AssetGroupEditor')).toHaveLength(1)
  })

  describe('when changing the printers', () => {
    const wrapper = mount(<Activity {...buildActivityState(2, 0)} />)

    it('changes the selected tube printer in the react state', () => {
      expect(wrapper.instance().state.selectedTubePrinter).toEqual(8)
      wrapper
        .find({ name: 'tube_printer_select' })
        .first()
        .simulate('change', { target: { value: 1 } })
      expect(wrapper.instance().state.selectedTubePrinter).toEqual(1)
    })

    it('changes the selected plate printer in the react state', () => {
      expect(wrapper.instance().state.selectedPlatePrinter).toEqual(14)
      wrapper
        .find({ name: 'plate_printer_select' })
        .first()
        .simulate('change', { target: { value: 2 } })
      expect(wrapper.instance().state.selectedPlatePrinter).toEqual(2)
    })
  })
})
