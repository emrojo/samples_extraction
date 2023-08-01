# Error/Status message as a result of the execution of a step
class StepMessage < ApplicationRecord
  belongs_to :step
end
