class Fixnum
  def days
    self * 24 * 60 * 60
  end

  def years
    days * 365
  end

end


module ApplicationHelper
  def prev_year_months
    date = Date.today
    months = {}
    13.times do
      months[date.strftime('%y%m')] = ""
      date = date.prev_month
    end
    Hash[months.sort]
  end
end


