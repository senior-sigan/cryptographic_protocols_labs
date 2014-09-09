require 'socket'

A = 'Alice'
B = 'Bob'
T = 'Trend'
I = 1

STEP = 20
N = 1000000 # max size of random numbers

def e(text, key) # func encrypt == func decrypt
  cypher_bytes = []
  text_bytes = text.unpack 'U*' # UTF8
  key_bytes = key.unpack 'U*'
  key_len = key_bytes.length

  0.upto(text_bytes.length - 1) do |i|
    cypher_bytes.push text_bytes[i] ^ key_bytes[i % key_len]
  end

  cypher_bytes.pack 'U*'
end

MY_EOF = /^\+OK/
OK = "+OK"
class TCPSocket
  def receive(regexp)
    resp = ""
    while !(str = self.gets)[regexp]
      resp << str
    end
    resp.chop
  end
end

def fill str
  str_pack = str.unpack('U*')
  offset = STEP - str_pack.length
  str_pack += [0] * offset if offset >= 0
  str_pack.pack('U*')
end

def unfill str
  str_pack = str.unpack 'U*'
  res = []
  str_pack.each do |byte|
    res << byte unless byte.zero?
  end
  res.pack('U*')
end