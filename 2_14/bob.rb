require './encryptor'

Kb = 'Bob Trend Key'

def bob
  bob = TCPServer.new 2001
  puts 'Bob is here. Wait Alice'
  
  alice = bob.accept
  msg = alice.receive MY_EOF
  puts "Receive msg from Alice '#{msg}'"
  rb = rand N
  puts "Generated rb=#{rb}"
  msg_bob = fill(rb.to_s) + fill(I.to_s) + fill(A) + fill(B)
  msg += e(msg_bob,Kb)

  puts "Send msg to Trend"
  trend = TCPSocket.new 'localhost',2000
  trend.puts msg
  trend.puts OK

  puts 'Wait Trend response'
  msg_key = trend.receive MY_EOF
  alice_part_e = msg_key[0..3*STEP-1]
  bob_part_e = msg_key[3*STEP..5*STEP - 1]

  bob_part = e(bob_part_e,Kb)
  rb_walky = bob_part[0..STEP-1]
  session_key = bob_part[STEP..2*STEP-1]

  rb_walky = unfill(rb_walky)
  session_key = unfill(session_key)

  if rb_walky.to_i != rb.to_i
    puts "#{rb_walky} != #{rb} FAIL"
    return false
  end

  puts "Send to alice #{alice_part_e}"
  alice.puts alice_part_e
  alice.puts OK
  
  puts "Session Key #{session_key}"
  trend.close
end

bob