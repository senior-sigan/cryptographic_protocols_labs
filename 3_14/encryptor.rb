require "socket"

A = 'Alice'
B = 'Bob'
N = 1000000 # max size of random numbers
KEY_SIZE = 1024 # bits == 128 bytes - 11 bytes for magic
BLOCK_SIZE = KEY_SIZE / 8
BLOCK_SIZE_PADDING = BLOCK_SIZE - 11
SPLITTER = [0,1,0,1]

MY_EOF = /^\+OK/
OK = "+OK"

class TCPSocket
  def receive(regexp = MY_EOF)
    resp = ""
    while !(str = self.gets)[regexp]
      resp << str
    end
    resp.chop
  end
end

class String
  def sign(pub_key, size = BLOCK_SIZE_PADDING)
    self.unpack('C*').each_slice(size).map do |part|
      pub_key.private_encrypt part.pack('C*')
    end.join
  end

  def check_sign(pub_key, size = BLOCK_SIZE)
    self.unpack('C*').each_slice(size).map do |part|
      pub_key.public_decrypt part.pack('C*')
    end.join
  end

  def encrypt(pub_key, size = BLOCK_SIZE_PADDING)
    self.unpack('C*').each_slice(size).map do |part|
      pub_key.public_encrypt part.pack('C*')
    end.join
  end  

  def decrypt(pub_key, size = BLOCK_SIZE)
    self.unpack('C*').each_slice(size).map do |part|
      pub_key.private_decrypt part.pack('C*')
    end.join
  end

  def uncompress(splitter = SPLITTER)
    self.split splitter.pack('C*')
  end

  def sym_encrypt(key)
    size = key.bytesize
    key = key.unpack('C*')
    self.unpack('C*').each_slice(size).map do |part|
      part.each_index do |i|
        part[i] ^= key[i]
      end.pack('C*')
    end.join
  end

  def sym_decrypt(key)
    self.sym_encrypt(key)
  end

end

class Array
  def compress(splitter = SPLITTER)
    self.map do |word|
      word.unpack('C*') + SPLITTER
    end.flatten.pack('C*')
  end
end