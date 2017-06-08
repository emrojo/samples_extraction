# frozen_string_literal: true
if Rails.env.debug?
  Peek.into Peek::Views::Mysql2
  Peek.into Peek::Views::GC
  Peek.into Peek::Views::PerformanceBar
end
