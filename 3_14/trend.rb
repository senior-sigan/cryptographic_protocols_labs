# Woo-Lam
require "./encryptor"
require "openssl"

def trend
  trend_open_key = OpenSSL::PKey::RSA.generate KEY_SIZE

  trend = TCPServer.new 2000

  ###############################
  # 0 STEP - exchange open keys #
  ###############################
  alice = trend.accept
  alice_pem = alice.receive
  alice_open_key = OpenSSL::PKey::RSA.new alice_pem

  bob = trend.accept
  bob_pem = bob.receive
  bob_open_key = OpenSSL::PKey::RSA.new bob_pem

  bob.puts trend_open_key.to_pem
  bob.puts OK

  alice.puts trend_open_key.to_pem
  alice.puts OK

  ############################################
  # 1 STEP - Alice send to Trend 'Alice,Bob' #
  ############################################
  msg_alice = alice.receive
  puts msg_alice.uncompress

  msg = [B,bob_open_key.to_pem].compress.sign(trend_open_key)
  alice.puts msg
  alice.puts OK

  #####################################################
  # 5 STEP - Send to Bob [s_t(ka),e_b(s_t(ra,k,a,b))] #
  #####################################################

  msg_bob = bob.receive.uncompress
  if A != msg_bob[0] || B != msg_bob[1] || msg_bob[2].nil?
    raise 'Hell'
  end
  ra = msg_bob[2].decrypt(trend_open_key).to_i
  
  session_key = rand(N)
  puts session_key
  
  data = [ra.to_s, session_key.to_s, A, B].compress
  msg = [
    alice_open_key.to_pem.sign(trend_open_key),
    data.sign(trend_open_key).encrypt(bob_open_key)
  ].compress
  bob.puts msg
  bob.puts OK

  alice.close
  trend.close
end

trend