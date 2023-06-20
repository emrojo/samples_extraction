import React, { Fragment } from 'react'
import ReactDOM from 'react-dom'
import { shallow, mount } from 'enzyme'

import '../../test_helpers/test_init'

import { buildAssetGroupData } from '../../test_helpers/factories'

import AssetGroup from 'asset_group_components/asset_group'

const NUM_ASSETS = 3

describe('AssetGroup', () => {
  const stateAssetGroup = {
    assetGroup: buildAssetGroupData(1, NUM_ASSETS),
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

  it('renders the assets from the group', () => {
    const wrapper = shallow(<AssetGroup {...stateAssetGroup} />)
    expect(wrapper.find('AssetDisplay')).toHaveLength(NUM_ASSETS)
  })
})
