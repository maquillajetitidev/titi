module ApplicationHelper
  def current?(path='/')
    (request.path==path || request.path==path+'/') ? "current" : nil
  end
  def inside?(path='/')
    (request.path==path || request.path==path+'/' || "#{request.path}".include?("#{path}") ) ? "current" : nil
  end
  def current_path
    URI.parse(current_url).path
  end
end
