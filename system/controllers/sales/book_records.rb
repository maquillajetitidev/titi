class Sales < AppController
  get '/books' do
    show_day Date.today
  end

  get '/books/add' do
    slim :book_records_add, layout: :layout_sales, locals: {sec_nav: :nav_books}
  end
  post '/books/add' do
    record =  BookRecord.new.update_from_hash(params)
    begin
      record.save
    rescue => detail
      flash[:error] = detail.message
    end
    redirect to("/books")
  end


  helpers do
    def my_date
      begin
        the_date = "#{params[:year].to_i}/01/01" unless params[:year].nil?
        the_date = "#{params[:year].to_i}/#{params[:month].to_i}" unless params[:month].nil?
        the_date = "#{params[:year].to_i}/#{params[:month].to_i}/#{params[:day].to_i}" unless params[:day].nil?
        date = Date.parse the_date
      rescue => detail
        flash.now[:error] = detail.message == "invalid date" ? "Fecha invalida" : detail.message
        date = Date.today
      end
      date
    end

    def show_day date
      @broad = {machine: (date).strftime("%Y/%m"), human: "Ver por mes"}
      @prev = {machine: (date.prev_day).strftime("%Y/%m/%d"), human: R18n.l(date.prev_day, :full)}
      @curr = R18n.l date, :full
      @next = {machine: (date.next_day).strftime("%Y/%m/%d"), human: R18n.l(date.next_day, :full)}
      @narrow = nil
      @title = "Movimientos de caja de #{R18n.l date, :full}"
      view_records current_location[:name], date.to_s, {days:1}
    end
  end

  get "/books/:year" do
    date = my_date

    @broad = nil
    @prev = {machine: (date.prev_year).strftime("%Y"), human: (date.prev_year).strftime("%Y")}
    @curr = date.strftime("%Y")
    @next = {machine: (date.next_year).strftime("%Y"), human: (date.next_year).strftime("%Y")}
    @narrow = {machine: (date).strftime("%Y/%m"), human: "Ver por mes"}

    @title = "Movimientos de caja de #{params[:year].to_i}"
    view_records current_location[:name], date.to_s, {years:1}
  end
  get "/books/:year/:month" do
    date = my_date

    @broad = {machine: (date).strftime("%Y"), human: "Ver por año"}
    @prev = {machine: (date.prev_month).strftime("%Y/%m"), human: R18n::Locales::Es.new.month_names[date.prev_month.month-1]}
    @curr = R18n::Locales::Es.new.month_names[date.month-1]
    @next = {machine: (date.next_month).strftime("%Y/%m"), human: R18n::Locales::Es.new.month_names[date.next_month.month-1]}
    @narrow = {machine: (date).strftime("%Y/%m/%d"), human: "Ver por dia"}

    @title = "Movimientos de caja de #{R18n::Locales::Es.new.month_names[date.month-1]} de #{params[:year].to_i}"
    view_records current_location[:name], date.to_s, {months:1}
  end
  get "/books/:year/:month/:day" do
    show_day my_date
  end

  def view_records location, start_date, interval
    @start_date = Date.parse start_date
    @records = BookRecord.new.from_date_with_interval(location, @start_date.iso8601, interval).all
    
    start = @records.select { |record| record.type == "Caja inicial" }.first
    @starting_cash = start.nil? ? 0 : start[:amount]

    @sales_total = 0
    @records.select { |record| record.type == "Venta mostrador" }.each { |record| @sales_total += record.amount }

    @commissions = 0
    @records.select { |record| record.type == "Comisiones" }.each{ |record| @commissions += record.amount}

    @withdrawals = 0
    @records.select { |record| record.type == "Recaudacion" }.each{ |record| @withdrawals += record.amount}

    @expenses = 0
    @records.select { |record| record.type == "Otros gastos" }.each { |record| @expenses += record.amount }

    @downpayments = 0
    @records.select { |record| record.type == "Pago a proveedor" }.each { |record| @downpayments += record.amount }

    surplus = 0
    @records.select { |record| record.type == "Sobrante de caja" }.each{ |record| surplus += record.amount}
    deficit = 0
    @records.select { |record| record.type == "Faltante de caja" }.each{ |record| deficit += record.amount}
    @diferences =  surplus + deficit

    @finish_cash = 0
    @records.reject { |record| record.type == "Caja inicial" }.each{ |record| @finish_cash += record.amount}
    @finish_cash += @starting_cash

    slim :book_records, layout: :layout_sales, locals: {sec_nav: :nav_books}
  end

end