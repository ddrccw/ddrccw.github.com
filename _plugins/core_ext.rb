#!/usr/bin/env ruby19
# encoding: utf-8

class String
  def slugize
    temp = self.downcase.gsub(/[\s\.]/, '-')
    result = temp.gsub(/[^\w\d\-\+\,]/, '')
    result = result.empty?? temp : result  
  end
end
 