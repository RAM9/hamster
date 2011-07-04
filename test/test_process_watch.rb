require 'helper'
class TestProcessWatch < Test::Unit::TestCase
  def test_find_running_daemon
    cmd = %%./bin/test_daemon ID=1%
    Process.detach(d_pid = fork {
      Process.exec cmd
    })
    assert {
      ProcessWatch.find('test_daemon ID=1').size == 1
    }
    %x{kill -9 #{d_pid}}
  end
  def test_pid_of_new_process_is_sibling
    cmd = %%ruby ./bin/hamster --watch 'test_daemon ID=1' --command "./bin/test_daemon ID=1" --callback_message o_o__poot --delay 4 --num_cycles 45 %
    Process.detach(h_pid = fork { 
      Process.exec cmd 
    })
    sleep 3 # let it start
    pid = ProcessWatch.find('test_daemon ID=1').first

    assert {
      lookup_parent_pid_via_ps('ruby ./bin/test_daemon ID=1') ==  lookup_parent_pid_via_ps('o_o__poot')
    }
    # clean up hamster and the test_daemon
    %x{kill -9 #{pid}}
    %x{kill -9 #{h_pid}}
  end
  def test_running_already_exit_without_action
    cmd = %%./bin/test_daemon ID=1%
    Process.detach(d_pid = fork { 
      Process.exec cmd
    })
    cmd = %%ruby ./bin/hamster --watch 'test_daemon ID=1' --command "./bin/test_daemon ID=1" --callback_message poot --delay 1 --num_cycles 2 %
    Process.detach(h_pid = fork { 
      %x{#{cmd}}
    })
    pid, status = Process.waitpid2(h_pid)
    assert {
      status.exitstatus == 0 
    }
    %x{kill -9 #{d_pid}}
  end

  def test_watches_self
    callback_called = false
    pw = ProcessWatch.new(:watch => "nothing", :delay => 1, :cycle => 1,
                          :callback => lambda {callback_called = true})
    pw.cycle
    assert { 
      callback_called
    }
  end
  def test_watches_but_not_the_watch_string_exits
    cmd = %%./bin/hamster --watch hamster --callback "puts 'toop'" --callback_message poot --delay 1 --num_cycles 2 %
    out = %x{#{cmd}}
    assert {
        out =~ /poot/ && out =~ /toop/
    }
  end
  def test_runs_test_daemon_command_if_not_present
    cmd = %%ruby ./bin/hamster --watch 'test_daemon ID=1' --command "./bin/test_daemon ID=1" --callback_message poot --delay 1 --num_cycles 2 %
    Process.detach(pid = fork { 
      Process.exec cmd
    })
    sleep 3 # let it start
    assert {
      ProcessWatch.find('test_daemon ID=1').size == 1
    }
    %x{kill -9 #{ProcessWatch.find('test_daemon ID=1').first}}
  end

  def test_daemon_keeps_running
    cmd = %%ruby ./bin/hamster --watch 'test_daemon ID=1' --command "./bin/test_daemon ID=1" --callback_message poot --delay 5 --num_cycles 10 %
    Process.detach(pid = fork { 
      Process.exec cmd
    })
    sleep 3 # let it start
    %x{kill -9 #{pid}}
    #child should live on if hampster is killed
    sleep 3 # wait..for it
    assert {
      ProcessWatch.find('test_daemon ID=1').size == 1
    }
    %x{kill -9 #{ProcessWatch.find('test_daemon ID=1').first}}
  end

  def lookup_parent_pid_via_ps(match)
    ProcessWatch.find(match,"f").first
  end
end


