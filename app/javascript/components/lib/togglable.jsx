const Togglable = (description, valueToCheck, onToggle, render) => {
  if (typeof valueToCheck === 'undefined') {
    return (
      <div className="form-group">
        <label onClick={onToggle} className="control-label">
          {description} <small className="btn-link">(Show)</small>
        </label>
      </div>
    )
  }

  return (
    <div className="form-group">
      <label onClick={onToggle} className="control-label">
        {description} <small className="btn-link">(Hide)</small>
      </label>
      {render()}
    </div>
  )
}

export default Togglable
