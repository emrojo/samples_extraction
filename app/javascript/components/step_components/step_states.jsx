const C = {
  STEP_STATE_RUNNING: 'running',
  STEP_STATE_IN_PROGRESS: 'in_progress',
  STEP_STATE_CONTINUING: 'continuing',
  STEP_STATE_REMAKING: 'remaking',
  STEP_STATE_CANCELLING: 'cancelling',
  STEP_STATE_FAILED: 'failed',
  STEP_STATE_PENDING: 'pending',
  STEP_STATE_STOPPED: 'stopped',
  STEP_STATE_CANCELLED: 'cancelled',
  STEP_STATE_COMPLETED: 'complete',

  STEP_EVENT_FAIL: 'fail',
  STEP_EVENT_RUN: 'run',
  STEP_EVENT_CONTINUE: 'continue',
  STEP_EVENT_STOP: 'stop',
  STEP_EVENT_REMAKE: 'remake',
  STEP_EVENT_CANCEL: 'cancel',
}

export default C
