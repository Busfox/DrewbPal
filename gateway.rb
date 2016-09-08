require 'dotenv'
require 'sinatra'
require 'shopify_api'
require 'httparty'
require 'pry'

class DrewbPal < Sinatra::Base

	def fields
		params = request.params.select {|k,v| k.start_with? 'x_'}
	end

	def sign(fields)
		message = fields.sort.join
		OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), 'iU44RWxeik', message)
	end

	post '/pay' do
		puts fields
		request_signature = fields['x_signature']
		calculated_signature = sign(fields.reject{|k,v| k == 'x_signature'})
		puts calculated_signature
		puts request_signature
		puts SecureRandom.hex
		if calculated_signature == request_signature
			puts 'Signature ok'
			payload = {
				'x_account_id' 			=> fields['x_account_id'],
				'x_reference' 			=> fields['x_reference'],
				'x_currency' 			=> fields['x_currency'],
				'x_test' 				=> fields['x_test'],
				'x_amount' 				=> fields['x_amount'],
				'x_gateway_reference' 	=> SecureRandom.hex,
				'x_timestamp' 			=> Time.now.utc.iso8601,
				'x_result' 				=> 'completed'
			}
			payload['x_signature'] = sign(payload)
			response = HTTParty.post(fields['x_url_callback'], body: payload)
			redirect_url = fields['x_url_complete'] + '?' + payload.to_query
			puts response.code
			if response.code == 200
				redirect redirect_url
			else
				redirect fields['x_url_cancel']
			end
		else
			puts 'Signature not ok'
		end
	end



end

DrewbPal.run!