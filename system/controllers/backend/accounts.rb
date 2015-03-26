class Backend < AppController
  get '/accounts' do
    @accounts = AccountPlan.new($settings).load
    slim :accounts_plan, layout: :layout_backend, locals: {title: t.accounts.plan.title}
  end
end
