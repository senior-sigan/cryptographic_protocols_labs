class Integer
  def qe2(deg, mod) # involution in the degree by modul
    raise 'Hell' if deg.nil? || mod.nil? || deg < 0

    s = 1
    t = self
    until deg.zero?
      s = s*t % mod unless (deg & 1).zero?
      deg >>= 1
      t = t**2 % mod
    end
    s
  end

  # Algorithm Evklida for finding GCD - Greater common div
  def gcd(y)
    x = self.magnitude
    y = y.magnitude
    raise 'Hell' if (x + y).zero?
    g = y

    while (x > 0)
      g = x
      y, x = x, y % x
      y = g
    end
    g
  end

  # Extention evklid: GCD(a,b) = d => a*x+b*y=d
  # @return [d,x,y]
  def ext_evklid(b)
    if b < 0
      raise 'HELL! b must be more than zero!'
    end

    a = self
    if b.zero?
      {d: a, x: 1, y: 0}
    else
      x1, x2, y1, y2 = 0, 1, 1, 0
      while b > 0
        q = a / b
        r = a - q * b
        x = x2 - q * x1
        y = y2 - q * y1

        a, b = b, r
        x2, x1 = x1, x
        y2, y1 = y1, y
      end
      {d: a, x: x2, y: y2}
    end
  end

  def reverse(mod)
    x = self.ext_evklid(mod)[:x]
    if x < 0
      (mod + x) 
    else
      x
    end
  end

  # primality test.
  # params:: r count of rounds
  # return:: false if composite and true if propability prime
  def rabin_miller?(r)
    if self < 2 || self.even? || r < 1 
      false
    else
      t = self - 1
      s = 0
      while t.even?
        t /= 2
        s = s.next
      end  

      r.times do 
        a = rand(2..self-2)
        x = a.qe2(t, self)
        next if x.eql?(1) || x.eql?(self-1)
        loops = (s - 1).times do
          x = x.qe2(2, self)
          return false if x.eql?(1)
          break if x.eql?(self - 1)
        end
        return false if loops.eql?(s - 1)
      end
      true
    end
  end
end

class RSA
  ROUNDS = 200

  def initialize(open_key = {})
    if open_key.has_key?('e') && open_key.has_key?('n')
      @e = open_key['e']
      @n = open_key['n']
    end
  end

  def generate!(size)
    raise 'Too little size' if size < 1

    size /= 2
    a, b = 2 ** size, 2 ** (size + 1)
    @p = prime(a..b)
    @q = prime(a..b)
    @n = @p * @q 
    fi = (@p - 1) * (@q - 1)

    begin
      @e = rand 2..fi
    end until @e.gcd(fi).eql?(1)
    @d = @e.reverse(fi)
    nil
  end

  def open_key
    {e: @e, n: @n}
  end

  def close_key
    {d: @d, n: @n}
  end

  def maskirate(msg)
    begin
      @k = rand 2..(@n - 1)
    end until @k.gcd(@n).eql?(1)
    
    (msg * @k.qe2(@e, @n)) % @n
  end

  def demaskirate(signed)
    (signed * @k.reverse(@n)) % @n
  end

  def sign(msg)
    raise 'No params to sign' if @d.nil? || @n.nil?

    if msg = msg.to_i
      if msg > 0 && msg < (@n - 1)
        msg.qe2(@d, @n)
      else
        raise "Number must be in [0,#{@n-1}]"
      end
    else
      raise 'Only Number acceptable'
    end
  end

  def check_sign(msg)
    raise 'No params to sign' if @e.nil? || @n.nil?

    if msg = msg.to_i
      if msg > 0 && msg < (@n - 1)
        msg.qe2(@e, @n)
      else
        raise "Number must be in [0,#{@n-1}]"
      end
    else
      raise 'Only Number acceptable'
    end
  end

  def public_encrypt(plain)
    raise 'No params to encrypt' if @e.nil? || @n.nil?

    if plain = plain.to_i
      if plain > 0 && plain < (@n - 1)
        plain.qe2(@e, @n)
      else
        raise "Number must be in [0,#{@n-1}]"
      end
    else
      raise 'Only Number acceptable'
    end
  end

  def private_decrypt(cyphr)
    raise 'No params to decrypt' if @d.nil? || @n.nil?

    if cyphr = cyphr.to_i
      if cyphr > 0 && cyphr < (@n - 1)
        cyphr.qe2(@d, @n)
      else
        raise "Number must be in [0,#{@n-1}]"
      end
    else
      raise 'Only Number acceptable'
    end
  end

  def prime(range)
    begin  
      p = rand(range)
    end until p.rabin_miller?(ROUNDS)
    p 
  end
  
end


class TestRsa
  def self.encrypt(count)
    suc = 0
    fail = 0
    count.times do 
      begin
        k = RSA.new
        k.generate!(100)
        k2 = RSA.new k.open_key

        m = rand(2**99)
        c = k2.public_encrypt(m)

        mm = k.private_decrypt(c)
        
        unless mm.eql?(m)
          fail = fail + 1
          p "ERROR"
          p k,{m: m, c: c, mm: mm}
        end
        suc = suc + 1
        p "Success",k,{m: m, c: c}
      rescue Exception => msg
        p msg, k, k2
      end
    end

    #p {success: suc, fail: fail}
  end

  def self.sign(count)
    count.times do |i|
      begin
        puts "\n#{'#'*80}TEST #{i}"
        k = RSA.new
        k.generate!(100)
        p k

        m = rand(2**99)
        t = k.maskirate(m)
        masked_s = k.sign(t)
        s = k.demaskirate(masked_s)
        mm = k.check_sign(s)

        if m.eql?(mm)
          p 'SUCCESS'
        else
          p 'FAIL'
        end
        out = {m: m, t: t, masked_s: masked_s, s: s, mm: mm}
        p out
      rescue Exception => e
        p e
        out = {m: m, t: t, masked_s: masked_s, s: s, mm: mm}
        p out
      end
    end
  end
end

#TestRsa.encrypt(10)
TestRsa.sign(10)