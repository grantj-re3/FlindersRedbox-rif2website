#--
# Copyright (c) 2013, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 

# Load standard library files
require 'logger'
require 'net/https'
require 'net/http'

##############################################################################
# This class allows the reading of http/https web pages.
# * Assumes that $LOG defines a Logger object.
#--
# InWebPage.initialize() code is derived from the sample:
#   /usr/share/doc/ruby-1.8.7.352/sample/openssl/wget.rb
# which I *suspect* is covered by the Ruby license:
#   http://www.ruby-lang.org/en/about/license.txt
class InWebPage
  # Valid protocol schemes.
  VALID_SCHEMES = %w(http https)

  # Create a new InWebPage object from the supplied URL.
  # * Argument _url_str_: The URL string of the web page to be fetched
  # Assumes that the hash Config[] has been defined with keys:
  # * <em>:http_get_header</em> -- An HTTP GET-request header.
  #   ModSecurity or other web server rules may have minimum requirements for
  #   the HTTP GET-request header (eg. may need to specify 'User-Agent'). The
  #   header must be a hash as required by Net::HTTP get2()
  def initialize(url_str)
    $LOG.info "Getting URL '#{url_str}'"
    uri = URI.parse(url_str)
    unless VALID_SCHEMES.include?(uri.scheme)
      $LOG.fatal "URL protocol is not one of #{VALID_SCHEMES.join(',')}"
      exit 1
    end
    if proxy = ENV['HTTP_PROXY']
      prx_uri = URI.parse(proxy)
      prx_host = prx_uri.host
      prx_port = prx_uri.port
    end

    h = Net::HTTP.new(uri.host, uri.port, prx_host, prx_port)
    h.set_debug_output($stderr) if $DEBUG
    h.use_ssl = uri.scheme == "https"
    h.verify_mode = OpenSSL::SSL::VERIFY_NONE  # OpenSSL::SSL::VERIFY_PEER

    @body = ''
    begin
      @get_resp = h.get2(uri.request_uri, Config[:http_get_header]){|resp| @body += resp.body}
    rescue Exception => ex
      $LOG.fatal "Unable to get web page. Error: #{ex}"
      exit 1
    end

    if http_redirect?
      $LOG.debug "#{@get_resp.class} is a kind of HTTPRedirection"
      $LOG.debug "Redirect location = #{redirect_location}"
    elsif http_success?
      $LOG.debug "#{@get_resp.class} is a kind of HTTPSuccess"
    else
      $LOG.debug "#{@get_resp.class} is neither HTTPSuccess nor HTTPRedirection!!!"
    end

  end  # def initialize

  # Returns the body of the web page as a string.
  def to_s
    @body
  end

  # Returns true if the object is a kind of Net::HTTPSuccess.
  def http_success?
    @get_resp.kind_of?(Net::HTTPSuccess)
  end

  # Returns true if the object is a kind of Net::HTTPRedirection.
  def http_redirect?
    @get_resp.kind_of?(Net::HTTPRedirection)
  end

  # Returns the URL of the redirect-location if the object is an
  # http_redirect, else returns nil.
  #
  # Only gives accurate location if redirect is 1 level deep!
  def redirect_location
    http_redirect? ? @get_resp.header['location'] : nil
  end

end  # class InWebPage

