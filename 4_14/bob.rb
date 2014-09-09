# coding : utf-8
require 'socket'
require './RSA.rb'
require 'json'

KEY_SIZE = 100
RANGE = 2**KEY_SIZE - 1
MY_EOF = /^\+OK/

bob_open_key = RSA.new
bob_open_key.generate!(KEY_SIZE)

class TCPSocket
  def receive(regexp)
    resp = ""
    while !(str = self.gets)[regexp]
      resp << str
    end
    resp.chop
  end
end

bob = TCPServer.new 2000
puts "Bob is here!"
p bob_open_key

alice = bob.accept
puts alice

alice_key_pem = JSON.parse(alice.receive(MY_EOF))
alice_open_key = RSA.new alice_key_pem
p "Alice open_key '#{alice_key_pem}'", alice_open_key.open_key

alice.puts bob_open_key.open_key.to_json
alice.puts "+OK"

rb = rand(RANGE)
puts "RB= #{rb}"
rb_encrypted = alice_open_key.public_encrypt(rb).to_s
rb_part1 = rb_encrypted[0,rb_encrypted.length/2]
rb_part2 = rb_encrypted[rb_encrypted.length/2,rb_encrypted.length]

ra_part1 = alice.receive MY_EOF
alice.puts rb_part1
alice.puts '+OK'

ra_part2 = alice.receive MY_EOF
alice.puts rb_part2
alice.puts '+OK'

ra_encrypted = ra_part1+ra_part2
ra = bob_open_key.private_decrypt(ra_encrypted).to_i
puts "RA= #{ra}"

session_key = rb ^ ra
puts session_key

msg_encrypted = alice.receive MY_EOF
puts msg_encrypted
ALICE_MSG = ""
msg_encrypted.each_byte do |b|
  puts b
  ALICE_MSG << (b ^ (session_key & 255)).chr
  session_key >>=8
end
puts "Alice: #{ALICE_MSG}"

alice.close