# Woo-Lam
require "./encryptor"
require "openssl"

def bob
  bob_open_key = OpenSSL::PKey::RSA.generate KEY_SIZE

  trend = TCPSocket.new 'localhost',2000

  trend.puts bob_open_key.to_pem
  trend.puts OK

  trend_pem = trend.receive
  trend_open_key = OpenSSL::PKey::RSA.new trend_pem

  bob = TCPServer.new 2001
  alice = bob.accept
  msg = alice.receive.uncompress

  if A != msg[0] || msg[1].nil?
  	raise 'Hell'
  	puts msg
  end

  ra = msg[1].decrypt(bob_open_key).to_i
  puts ra

  ######################################
  # 4 STEP - Send to Trend [A,B,e(ra)] #
  ######################################

  msg = [A, B, ra.to_s.encrypt(trend_open_key)].compress
  trend.puts msg
  trend.puts OK

  ###########################################
  # 6 STEP - Check Trend sign               #
  # and send to Alice e_a(s_t(ra,k,a,b),rb) #
  ###########################################

  msg = trend.receive.uncompress
  
  alice_pem = msg[0].check_sign(trend_open_key)
  alice_open_key = OpenSSL::PKey::RSA.new alice_pem
  
  data_signed = msg[1].decrypt(bob_open_key)
  data = data_signed.check_sign(trend_open_key).uncompress
  if (ra != data[0].to_i || data[1].nil? || A != data[2] || B != data[3])
  	p data
  	raise 'Hell'
  end
  session_key = data[1]

  rb = rand(N)
  msg = [data_signed, rb.to_s].compress.encrypt(alice_open_key)
  alice.puts msg
  alice.puts OK

  #####################
  # 8 - STEP Check rb #
  #####################

  msg = alice.receive.sym_decrypt(session_key)
  if rb != msg.to_i
  	p rb
  	raise 'Hell'
  end

  #######################################
  puts session_key
  puts "LET'S CHAT"
  trend.close
  alice.close

end

bob