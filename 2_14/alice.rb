require "./encryptor"

Ka = 'AliceTrendKey'

def alice
  bob = TCPSocket.new 'localhost',2001
  puts 'Alice is here. Sending msg to Bob'

  ra = rand N
  id = fill(I.to_s) + fill(A) + fill(B)
  msg_encr = fill(ra.to_s) + id
  msg = id + e(msg_encr,Ka)
  puts "Send to Bob '#{msg}'"
  bob.puts msg
  bob.puts OK

  puts 'Wait for response from Bob'
  session_msg_e = bob.receive MY_EOF
  puts "From Bob #{session_msg_e}"
  i = session_msg_e[0..STEP]
  session_key_e = session_msg_e[STEP..3*STEP-1]
  session_msg = e(session_key_e,Ka)
  ra_walky = unfill(session_msg[0..STEP-1])
  session_key = session_msg[STEP..2*STEP-1]

  unless (i.to_i == I.to_i && ra_walky.to_i == ra.to_i)
    puts "#{i} != #{I} && #{ra_walky} != #{ra}"
    raise 'HELL'
  end

  puts "Session key #{session_key} ra=#{ra} i=#{i}"
  bob.close
end

alice