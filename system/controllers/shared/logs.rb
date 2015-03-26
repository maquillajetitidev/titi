module Logs
  def get_and_render_logs
    if params.empty?
      render_logs ActionsLog.new.get_today
    else
      # search
      render_logs ActionsLog.new.get_with_hash params
    end
  end

  def get_and_render_logins username
    begin
      log_data = ActionsLog.new.get_logins(username)
    rescue SecurityError => e
      flash.now[:error] = e.message
      log_data = []
    end
    slim :logins, layout: session[:layout], locals: {logs: log_data, title: "Reporte de asistencias", sec_nav: :nav_administration}


  end

  def render_logs log_data
    slim :logs, layout: session[:layout], locals: {logs: log_data, title: t.logs.title}
  end

end


class Backend < AppController
  include Logs
  get '/logs' do get_and_render_logs end
end

class Sales < AppController
  include Logs
  get '/logs' do get_and_render_logs end
end

