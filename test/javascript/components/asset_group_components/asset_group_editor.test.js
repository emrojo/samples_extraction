import React, { Fragment } from 'react'
import ReactDOM from 'react-dom'
import { shallow, mount } from 'enzyme'

import '../../test_helpers/test_init'

import { buildAssetGroupData } from '../../test_helpers/factories'

import AssetGroupEditor from 'asset_group_components/asset_group_editor'

describe('AssetGroupEditor', () => {
  const stateAssetGroup = {
    assetGroup: buildAssetGroupData(1, 3),
    activityRunning: false,
    isShown: false,
    uuidsPendingRemoval: [],
    dataAssetDisplay: {},
    onCollapseFacts: null,
    collapsedFacts: {},
    onRemoveAssetFromAssetGroup: null,
    onRemoveAllAssetsFromAssetGroup: null,
    onErrorMessage: null,
    onChangeAssetGroup: null,
    onAddBarcodesToAssetGroup: null,
  }

  it('renders AssetGroupEditor component', () => {
    const wrapper = shallow(<AssetGroupEditor {...stateAssetGroup} />)
    expect(wrapper.find('BarcodeReader')).toHaveLength(1)
  })

  it('renders <AssetGroup />', () => {
    const wrapper = mount(<AssetGroupEditor {...stateAssetGroup} />)
    expect(wrapper.find('AssetGroup')).toHaveLength(1)
  })

  it('renders <BarcodeReader />', () => {
    const wrapper = mount(<AssetGroupEditor {...stateAssetGroup} />)
    expect(wrapper.find('BarcodeReader')).toHaveLength(1)
  })
})
