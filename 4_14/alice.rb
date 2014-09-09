# coding : utf-8
require 'socket'
require './RSA.rb'
require 'json'

MSG = 'Няя Bob,^_^'
KEY_SIZE = 100
RANGE = 2**KEY_SIZE - 1

MY_EOF = /^\+OK/
class TCPSocket
  def receive(regexp)
    resp = ""
    while !(str = self.gets)[regexp]
      resp << str
    end
    resp.chop
  end
end

alice_open_key = RSA.new
alice_open_key.generate!(KEY_SIZE)
bob = TCPSocket.new 'localhost',2000
puts "Alice is here!"

p alice_open_key
bob.puts alice_open_key.open_key.to_json
bob.puts "+OK"
bob_key_pem = JSON.parse(bob.receive(MY_EOF))
bob_open_key = RSA.new bob_key_pem
puts "Bob key is '#{bob_key_pem}'"

ra = rand(RANGE)
puts "RA= #{ra}"

ra_encrypted = bob_open_key.public_encrypt(ra).to_s
ra_part1 = ra_encrypted[0,ra_encrypted.length/2]
ra_part2 = ra_encrypted[ra_encrypted.length/2,ra_encrypted.length]

bob.puts ra_part1
bob.puts '+OK'
rb_part1 = bob.receive MY_EOF

bob.puts ra_part2
bob.puts '+OK'
rb_part2 = bob.receive MY_EOF

rb_encrypted = rb_part1+rb_part2
rb = alice_open_key.private_decrypt(rb_encrypted).to_i
puts "RB= #{rb}"

session_key = rb ^ ra
puts session_key

msg_encrypted = ""
puts MSG
MSG.each_byte do |b|
  puts (b ^ (session_key & 255))
  msg_encrypted << (b ^ (session_key & 255)).chr
  session_key >>=8
end

puts "Send: #{msg_encrypted}"
bob.puts msg_encrypted
bob.puts '+OK'

bob.close