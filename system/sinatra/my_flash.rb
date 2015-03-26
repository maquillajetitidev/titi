module Sinatra
  module Flash
    module Style

      def styled_flash
        return "" if flash(:flash).empty?
        messages = []
        error_level = flash.keys.first.to_s.partition("_").first
        flash.keys.each do |key|
          the_flash = flash[key]
          if the_flash.respond_to? :each
            if the_flash.first.respond_to? :each
              the_flash.each do |field, msgs|
                msg = ""
                if msgs.respond_to? :each
                  msgs.each { |m| msg += "<dd>#{m}</dd>" }
                  messages << "<dt>#{field}:</dt> #{msg}"
                else
                  messages << "<dd>#{field}</dd>"
                end
              end
            else
              the_flash.each do |msgs|
                messages << "<dd>#{msgs}</dd>"
              end
            end
          else
            messages << "#{the_flash}<br>"
          end
        end
        audio_msg = error_level != "notice" ? "<audio src=\"/media/#{error_level}.mp3\" autoplay>Actualiza tu navegador.</audio>\n" : ""
        "<div class='flash flash_#{error_level} bounceInDown'>\n" + audio_msg + messages.join + "</div>"
      end

    end
  end
end
