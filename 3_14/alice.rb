# Woo-Lam
require "./encryptor"
require "openssl"

HOST = { trend: 'localhost', bob: 'localhost' }
PORT = { trend: 2000, bob: 2001 }

def alice
  alice_open_key = OpenSSL::PKey::RSA.generate KEY_SIZE

  trend = TCPSocket.new HOST[:trend],PORT[:trend]

  trend.puts alice_open_key.to_pem
  trend.puts OK

  trend_pem = trend.receive
  trend_open_key = OpenSSL::PKey::RSA.new trend_pem

  trend.puts [A,B].compress
  trend.puts OK

  #######################################################
  # 3 STEP - check TREND sign and send [a,e(ra)] to BOB #
  #######################################################
  msg_encr = trend.receive
  msg = msg_encr.check_sign(trend_open_key).uncompress
  if B != msg[0] || msg[1].nil?
    raise 'Hell'
  end
  
  bob_pem = msg[1]
  bob_open_key = OpenSSL::PKey::RSA.new bob_pem

  ra = rand(N)
  puts ra
  msg = [A, bob_open_key.public_encrypt(ra.to_s)].compress

  bob = TCPSocket.new HOST[:bob], PORT[:bob]
  bob.puts msg
  bob.puts OK

  #######################################################
  # 7 STEP - Alice check Trend sign and self ra         #
  # and send to Bob e_k(rb)                             #
  #######################################################
  msg = bob.receive.decrypt(alice_open_key).uncompress
  sign = msg[0].check_sign(trend_open_key).uncompress
  if (ra != sign[0].to_i || sign[1].nil? || A != sign[2] || B != sign[3])
    p sign
    raise 'Hell'
  end
  
  session_key = sign[1]
  rb = msg[1].to_i
  
  bob.puts rb.to_s.sym_encrypt(session_key)
  bob.puts OK

  #####################################
  puts session_key
  puts "LET'S CHAT"
  trend.close
  bob.close

end

alice