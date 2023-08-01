import React from 'react'
import ReactDOM from 'react-dom'
import { Label, TextField } from 'react-rails-form-helpers'

class ActivityDescription extends React.Component {
  renderCompletedAt() {
    if (this.props.activity.completed_at) {
      return <div className="form-group">This activity was finished at {this.props.activity.completed_at}</div>
    }
  }
  render() {
    return (
      <React.Fragment>
        {this.renderCompletedAt()}
        <div className="form-inline activity-desc">
          <div className="form-group">
            <label htmlFor="activity_type">Activity Type</label>
            <input
              type="text"
              className="form-control"
              name="activity_type"
              defaultValue={this.props.activity.activity_type_name}
              readOnly="readonly"
            />
          </div>
          <div className="form-group">
            <label htmlFor="instrument">Instrument</label>
            <input
              type="text"
              className="form-control"
              name="instrument"
              defaultValue={this.props.activity.instrument_name}
              readOnly="readonly"
            />
          </div>

          <div className="form-group">
            <label htmlFor="kit">Kit</label>
            <input
              type="text"
              className="form-control"
              name="kit"
              defaultValue={this.props.activity.kit_name}
              readOnly="readonly"
            />
          </div>
        </div>
      </React.Fragment>
    )
  }
}

export default ActivityDescription
