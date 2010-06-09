$:.unshift File.dirname(__FILE__)

require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'
require 'timeout'

begin
  require 'xml_simple'
rescue LoadError
  require 'rubygems'
  require 'active_support'
  begin
  require 'xml_simple'
  rescue LoadError
    require 'xmlsimple'
  end
end


# A very simple REST client, best explained by example:
#
#   # Retrieve a Kitten and print its name and colour
#   kitten = Restr.get('http://example.com/kittens/1.xml')
#   puts kitten['name']
#   puts kitten['colour']
#
#   # Create a Kitten
#   kitten = Restr.post('http://example.com/kittens.xml', 
#     :name => 'batman', :colour => 'black')
#
#   # Update a Kitten
#   kitten = Restr.put('http://example.com/kittens/1.xml', 
#     :age => '6 months')
#
#   # Delete a Kitten :(
#   kitten = Restr.delete('http://example.com/kittens/1.xml')
#
#   # Retrieve a list of Kittens
#   kittens = Restr.get('http://example.com/kittens.xml')
#
# When the response to a Restr request has content type 'text/xml', the
# response body will be parsed from XML into a nested Hash (using XmlSimple 
# -- see http://xml-simple.rubyforge.org/). Otherwise the response is  
# returned untouched, as a String.
#
#
# === Authentication
# 
# If the remote REST resource requires authentication (Restr only supports
# HTTP Basic authentication, for now):
#
#   Restr.get('http://example.com/kittens/1.xml, {}, 
#     {:username => 'foo', :password => 'bar'})
#
# === Logging
# 
# A standard Ruby Logger can be attached to the Restr client like so:
#
#   logger = Logger.new('restr.log')
#   logger.level = Logger::DEBUG
#   Restr.logger = logger
#
# Restr will now log its activity to the given Logger.
# The default_logger can be overridden by supplying a :logger option to
# a client call:
#
#   kitten_logger = Logger.new('kitten.log'}
#   Restr.get('http://example.com/kittens/1.xml, {}, 
#     {:logger => kitten_logger)
class Restr
  
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 5
    TINY  = 2

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
  
  
  @@logger = nil
  @@request_timeout = 180
  
  cattr_accessor :request_timeout
  
  def self.logger=(logger)
    @@logger = logger.dup
    # ActiveSupport's BufferedLogger doesn't seem to support progname= :(
    @@logger.progname = self.name if @@logger.respond_to?(:progname)
  end
  
  def self.logger
    @@logger
  end
  
  def self.method_missing(method, *args)
    self.do(method, args[0], args[1] || {}, args[2])
  end
  
  def self.do(method, url, params = {}, options = {})
    #puts "METHOD:  #{method.inspect}"
    #puts "URL:     #{url.inspect}"
    #puts "PARAMS:  #{params.inspect}"
    #puts "OPTIONS: #{options.inspect}"
    
    uri = URI.parse(url)
    
    params = {} unless params
    options = {} unless options
    
    logger = options[:logger] || self.logger
      
    method_mod = method.to_s.downcase.capitalize
    unless Net::HTTP.const_defined?(method_mod)
      raise InvalidRequestMethod, 
        "Callback method #{method.inspect} is not a valid HTTP request method."
    end
    
    if method_mod == 'Get'
      q = params.collect{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join("&")
      if uri.query
        uri.query += "&#{q}"
      else
        uri.query = q
      end
    end
    
    req = Net::HTTP.const_get(method_mod).new(uri.request_uri)
    
    
    if options[:username] || options['username']
      req.basic_auth options[:username] || options['username'], options[:password] || options['password']
    end
    
    if params.kind_of?(Hash) && method_mod != 'Get' && method_mod != 'get'
      req.set_form_data(params, '&')
    end
    
    logger.debug("Sending #{method.inspect} request to #{url.inspect} "+
        (method.to_s == 'get' ? "params" : "data")+" #{params.inspect}"+
        (options.blank? ? "" : " with options #{options.inspect}}")+".") if logger
 
    client = Net::HTTP.new(uri.host, uri.port)
    client.use_ssl = (uri.scheme == 'https')
    
    timeout = Restr.request_timeout
    client.read_timeout = timeout
    
	req.add_field("Cookie", @cookie) if @cookie		# @techarch : added  the cookie header

    begin
      res = client.start do |http|
        http.request(req)
      end
    rescue Timeout::Error
      res = TimeoutError, "Request timed out after #{timeout} seconds."
    end
    
	@cookie = res.response['Set-Cookie']	# @techarch : save the cookie so we can send it back later (in the next request)
	
    case res
    when Net::HTTPSuccess
      if res.content_type =~ /[\/+]xml$/
        logger.debug("Got XML response: \n#{res.body}") if logger
        return XmlSimple.xml_in(res.body,
          'forcearray'   => false,
          'keeproot'     => false
        )
      else
        logger.debug("Got #{res.content_type.inspect} response: \n#{res.body}") if logger
        return res.body
      end
    when TimeoutError
      logger.debug(res) if logger
      return XmlSimple.xml_in(res,
          'forcearray'   => false,
          'keeproot'     => false
        )
    else
      $LAST_ERROR_BODY = res.body # FIXME: this is dumb... need a better way of reporting errors
      $LAST_ERROR_RESPONSE = res # this is currently unused within Restr, but may be useful for debugging 
      logger.error("Got error response '#{res.message}(#{res.code})': #{res.body.blank? ? '(blank response body)' : res.body}") if logger
      res.error!
    end
  end
  
  class InvalidRequestMethod < Exception
  end
end
