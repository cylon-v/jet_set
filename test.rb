class Test
  def initialize
    @method = 0
  end

  def calc
    @method = 1
    puts @method
  end
end

Test.define_method '@method=' do |value|
  @method = value + 5
end
test = Test.new
test.calc
