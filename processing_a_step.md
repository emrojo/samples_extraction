# Process diagram for step processing

This diagram is an attempt to map out the step process to aid performance
optimizations. It is _not_ and exhaustive map of all calls in the process.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant C As StepsController
    participant A As Activity
    participant S As Step
    participant SE As StepExecution
    participant SBTI As Steps::BackgroundTasks::Inference
    participant SBTR As Steps::BackgroundTasks::Runner
    participant ISE As InferenceEngines::Runner::StepExecution
    C->>A: create_step

    alt background_step
      A->>S: create!
      S-->>A: instance
      A->>+S: run
      S->>S: create_job
      S-)S: perform_job
      S->>S: process
      alt has_operations
        S--)S:remake_me
      else
        S->>SE: plan
        SE-->>S: updates
        S->>S: apply_changes
      end

      alt has step action
        S->>ISE:plan
        ISE->>ISE:generate_plan
        ISE->>ExternalScript:Execute
        ExternalScript-->>ISE:plan

        ISE-->>S:updates
        S->>S: apply_changes
      end



      deactivate S
    else cwm
      A->>SBTI: create!
      SBTI-->>A: instance
      A->>+SBTI: run
      deactivate SBTI
    else runner
      A->>SBTR: create!
      SBTR-->>A: instance
      A->>+SBTR: run
      deactivate SBTR
    end

```
