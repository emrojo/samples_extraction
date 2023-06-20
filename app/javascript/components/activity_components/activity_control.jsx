const ActivityControl = (props) => {
  if (props.activityRunning) {
    return (
      <small>
        <span className="spinner">
          <span className="glyphicon glyphicon-refresh fast-right-spinner"></span>
        </span>
      </small>
    )
  } else {
    return null
  }
}

export default ActivityControl
