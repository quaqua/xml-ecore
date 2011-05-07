class TestEvent < Ecore::Node
  string    :title
  time      :starts_at, :index => true
  time      :ends_at, :index => true
  integer   :status, :index => true
end

def test_event_fixtures
  now = Time.now
  TestEvent.create(nil, :name => 'test_status0', :starts_at => now-3600, :ends_at => now, :status => 0)
  TestEvent.create(nil, :name => 'test_status1', :starts_at => now, :ends_at => now+3600, :status => 1)
  TestEvent.create(nil, :name => 'test_status2', :starts_at => now+3600, :ends_at => now+3600*2, :status => 2)
  now
end
