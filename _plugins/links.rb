#!/usr/bin/env ruby19
# encoding: utf-8

module Jekyll
  class Links < Liquid::Tag
    safe = true
    
    def render(context)
      result = ""
			
			context.registers[:site].config['Links'].each do |k, v|
        result << %(<a href="#{v['url']}"><strong>#{v['title']}</strong></a><br />)
      end

      result
    end
  end
end
 
Liquid::Template.register_tag('links', Jekyll::Links)
