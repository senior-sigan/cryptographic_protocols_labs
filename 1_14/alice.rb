# coding : utf-8
require "socket"
require "openssl"

MSG = "Няя Bob,^_^"

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

alice_open_key = OpenSSL::PKey::RSA.generate 1024
bob = TCPSocket.new 'localhost',2000
puts "Alice is here!"

bob.puts alice_open_key.to_pem
bob.puts "+OK"
bob_key_pem = bob.receive(MY_EOF)
bob_open_key = OpenSSL::PKey::RSA.new(bob_key_pem)
puts "Bob key is '#{bob_key_pem}'"

ra = srand
puts "RA= #{ra}"

ra_encrypted = bob_open_key.public_encrypt ra.to_s
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