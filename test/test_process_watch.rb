require 'helper'
class TestProcessWatch < Test::Unit::TestCase
  def test_watches_self
    callback_called = false
    pw = ProcessWatch.new(:watch => "nothing", :delay => 1, :cycle => 1,
                          :callback => lambda {callback_called = true})
    pw.cycle
    assert { 
      callback_called
    }
  end
  def test_watches_but_not_the_watch_string
    cmd = %%./bin/hamster --watch hamster --callback "puts 'toop'" --callback_message poot --delay 1 --num_cycles 2 %
    out = %x{#{cmd}}
    assert {
        out =~ /poot/ && out =~ /toop/
    }
  end
  def test_runs_test_daemon_command_if_not_present
    cmd = %%ruby ./bin/hamster --watch 'test_daemon ID=1' --command "./bin/test_daemon ID=1" --callback_message poot --delay 1 --num_cycles 2 %
    Process.detach(pid = fork { 
      %x{#{cmd}}
    })
    ProcessWatch.find('test_daemon ID=1')
    assert {
      ProcessWatch.find('test_daemon ID=1').size == 1
    }

  end
  def test_daemon_keeps_running
    cmd = %%ruby ./bin/hamster --watch 'test_daemon ID=1' --command "./bin/test_daemon ID=1" --callback_message poot --delay 1 --num_cycles 2 %
    Process.detach(pid = fork { 
      %x{#{cmd}}
    })
    %x{kill -9 #{pid}}
    #child should live on
    assert {
      ProcessWatch.find('test_daemon ID=1').size == 1
    }
  end
end

