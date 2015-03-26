class Backend < AppController

  route :get, ['/', '/administration'] do
    protected! # needed by cucumber
    if current_user.level > 2
      nav = :nav_administration
      title = t.administration.title
    else
      redirect to ("/production")
    end
    slim :admin, layout: session[:layout], locals: {sec_nav: nav, title: title}
  end

end
