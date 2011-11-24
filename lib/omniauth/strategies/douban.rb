require 'omniauth-oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    class Douban < OmniAuth::Strategies::OAuth
      option :name, 'douban'
      option :sign_in, true
      def initialize(*args)
        super
        # taken from https://github.com/intridea/omniauth/blob/0-3-stable/oa-oauth/lib/omniauth/strategies/oauth/douban.rb#L15-21
        options.client_options = {
          :access_token_path => '/service/auth/access_token',
          :authorize_path => '/service/auth/authorize',
          :realm => 'OmniAuth',
          :request_token_path => '/service/auth/request_token',
          :site => 'http://www.douban.com'
        }
      end

      def consumer
        consumer = ::OAuth::Consumer.new(options.consumer_key, options.consumer_secret, options.client_options)
        consumer
      end

      uid { access_token.params[:douban_user_id] }

      # adapted from https://github.com/intridea/omniauth/blob/0-3-stable/oa-oauth/lib/omniauth/strategies/oauth/douban.rb#L38-53
      info do
        {
          :nickname => raw_info['db:uid']['$t'],
          :name => raw_info['title']['$t'],
          :location => raw_info['location'] ? raw_info['location']['$t'] : nil,
          :image => raw_info['link'].find{|l| l['@rel'] == 'icon'}['@href'],
          :description => raw_info['content']['$t'],
          :urls => {
            'Douban' => raw_info['link'].find{|l| l['@rel'] == 'alternate'}['@href']
          }
        }
      end

      extra do
        { :raw_info => raw_info }
      end

      #taken from https://github.com/intridea/omniauth/blob/0-3-stable/oa-oauth/lib/omniauth/strategies/oauth/tsina.rb#L52-67
      # def request_phase
      #   request_token = consumer.get_request_token(:oauth_callback => callback_url)
      #   session['oauth'] ||= {}
      #   session['oauth'][name.to_s] = {'callback_confirmed' => true, 'request_token' => request_token.token, 'request_secret' => request_token.secret}
      # 
      #   if request_token.callback_confirmed?
      #     redirect request_token.authorize_url(options[:authorize_params])
      #   else
      #     redirect request_token.authorize_url(options[:authorize_params].merge(:oauth_callback => callback_url))
      #   end
      # 
      # rescue ::Timeout::Error => e
      #   fail!(:timeout, e)
      # rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
      #   fail!(:service_unavailable, e)
      # end

      def raw_info
        @raw_info ||= MultiJson.decode(access_token.get('http://api.douban.com/people/%40me?alt=json').body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end