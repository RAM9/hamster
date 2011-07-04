class ProcessWatch
  attr_accessor :watch_string,
    :delay,
    :num_cycles,
    :command,
    :callback,
    :callback_message

  def initialize(options)
    self.command          = options[:command]              || nil
    self.callback         = options[:callback]             || 
                             lambda { p 'default callback does nothing'}
    self.callback_message = (options[:callback_message]    || 
                             "Callback Triggered").strip
    self.watch_string     = (options[:watch]               || 
                             "this poem is a pomme").strip
    self.delay            = options[:delay]                || 60
    self.num_cycles       = options[:num_cycles]           || 3
  end

  class << self 
    
    def find(watch_string,ps_args = "")
      cmd = %%ps -x#{ps_args} |grep '#{watch_string}' |grep -v grep | grep -v 'watch #{watch_string}' | awk '{print $1}'%
      pids = %x{#{cmd}}.split()
    end
  end

  public
  def cycle
    self.num_cycles.times do 
      _check
      sleep self.delay
    end
  end
  private
  def _trigger_callback
      _fork
    ensure
      self.callback.call
      puts self.callback_message
    end
  def _check
    if self.class.find(self.watch_string).empty?
      _trigger_callback
    end
  end
  def _fork
    Daemonize.call_as_daemon(lambda {
      p ENV['PWD']
      Dir.chdir(ENV['PWD'])
      ::Process.exec(self.command)
    },"hamster.daemon.log",self.command)
  end
end

