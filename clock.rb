# Clockwork
require_relative 'workers/skroutz_worker'

include Clockwork

every(1.hour, 'Queueing interval job') do
  r = SkroutzWorker.new
  r.perform
end
