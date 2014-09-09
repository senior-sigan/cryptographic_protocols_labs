#TREND 
require './encryptor.rb'

Ka = 'AliceTrendKey'
Kb = 'Bob Trend Key'

def trend
  trend = TCPServer.new 2000
  puts 'Trend is here!!'

  bob = trend.accept
  msg = bob.receive MY_EOF

  msg = parse msg

  unless msg.nil?
    session_key = rand N
    puts "Generated session key #{session_key}"
    bob.puts response(
      msg[:ra],
      msg[:rb],
      fill(session_key.to_s))
    bob.puts OK
    true
  else
    false
  end
end

def parse msg
  i = msg[0..STEP-1]
  a = msg[STEP..2*STEP - 1]
  b = msg[2*STEP..3*STEP - 1]
  encr_alice = msg[3*STEP..7*STEP - 1]
  encr_bob = msg[7*STEP..11*STEP - 1]

  # puts i
  # puts a
  # puts b
  # puts encr_alice
  # puts encr_bob

  alice_msg = short_parse(encr_alice, Ka)
  bob_msg = short_parse(encr_bob, Kb)

  if good?({i: i,a: a,b: b},alice_msg,bob_msg)
    ra = alice_msg[:r]
    rb = bob_msg[:r]
    {
      ra: ra,
      rb: rb
    }
  else
    nil
  end

end

def short_parse encr_msg, key
  msg = e(encr_msg,key)
  if msg.length == 4*STEP
    {
      r: msg[0..STEP - 1],
      i: msg[STEP..2*STEP - 1],
      a: msg[2*STEP..3*STEP - 1],
      b: msg[3*STEP..4*STEP - 1]
    }
  else
    raise 'HELL'
  end
end

def response(ra, rb, key)
  msg = fill(I.to_s)
  msg << e(ra + key, Ka)
  msg << e(rb + key, Kb)
  msg
end

def good?(o, a, b)
  o[:i] == a[:i] && o[:i] == b[:i] &&
  o[:a] == a[:a] && o[:a] == b[:a] &&
  o[:b] == a[:b] && o[:b] == b[:b]
end

trend