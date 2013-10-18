require 'spec_helper'

describe Grape::Util::HashStack do

  describe '#get' do
    it 'finds the first available key' do
      subject[:abc] = 123
      subject.push(abc: 345)
      subject.get(:abc).should == 345
    end

    it 'is nil if the key has not been set' do
      subject[:abc].should be_nil
    end
  end

  describe '#set' do
    it 'sets a value on the highest frame' do
      subject.push
      subject.set(:abc, 123)
      subject.stack.last[:abc].should == 123
    end
  end

  describe '#imbue' do
    it 'pushes a new value onto the end of an array' do
      subject[:abc] = []
      subject.imbue(:abc, [123])
      subject.imbue(:abc, [456])
      subject[:abc].should == [123, 456]
    end

    it 'merges a hash that is passed' do
      subject[:abc] = { foo: 'bar' }
      subject.imbue(:abc, { baz: 'wich' })
      subject[:abc].should == { foo: 'bar', baz: 'wich' }
    end

    it 'sets the value if not a hash or array' do
      subject.imbue(:abc, 123)
      subject[:abc].should == 123
    end

    it 'is able to imbue an array without explicit setting' do
      subject.imbue(:arr, [1])
      subject.imbue(:arr, [2])
      subject[:arr].should == [1, 2]
    end

    it 'is able to imbue a hash without explicit setting' do
      subject.imbue(:hash, foo: 'bar')
      subject.imbue(:hash, baz: 'wich')
      subject[:hash].should == { foo: 'bar', baz: 'wich' }
    end
  end

  describe '#push' do
    it 'returns a HashStack' do
      subject.push(Grape::Util::HashStack.new).should be_kind_of(Grape::Util::HashStack)
    end

    it 'places the passed value on the top of the stack' do
      subject.push(abc: 123)
      subject.stack.should == [{}, { abc: 123 }]
    end

    it 'pushes an empty hash by default' do
      subject[:abc] = 123
      subject.push
      subject.stack.should == [{ abc: 123 }, {}]
    end
  end

  describe '#pop' do
    it 'removes and return the top frame' do
      subject.push(abc: 123)
      subject.pop.should == { abc: 123 }
      subject.stack.size.should == 1
    end
  end

  describe '#peek' do
    it 'returns the top frame without removing it' do
      subject.push(abc: 123)
      subject.peek.should == { abc: 123 }
      subject.stack.size.should == 2
    end
  end

  describe '#prepend' do
    it 'returns a HashStack' do
      subject.prepend(Grape::Util::HashStack.new).should be_kind_of(Grape::Util::HashStack)
    end

    it "prepends a HashStack's stack onto its own stack" do
      other = Grape::Util::HashStack.new.push(abc: 123)
      subject.prepend(other).stack.should == [{}, { abc: 123 }, {}]
    end
  end

  describe '#concat' do
    it 'returns a HashStack' do
      subject.concat(Grape::Util::HashStack.new).should be_kind_of(Grape::Util::HashStack)
    end

    it "appends a HashStack's stack onto its own stack" do
      other = Grape::Util::HashStack.new.push(abc: 123)
      subject.concat(other).stack.should == [{}, {}, { abc: 123 }]
    end
  end

  describe '#update' do
    it 'merges! into the top frame' do
      subject.update(abc: 123)
      subject.stack.should == [{ abc: 123 }]
    end

    it 'returns a HashStack' do
      subject.update(abc: 123).should be_kind_of(Grape::Util::HashStack)
    end
  end

  describe '#clone' do
    it 'performs a deep copy' do
      subject[:abc] = 123
      subject.push def: 234
      clone = subject.clone
      clone[:def] = 345
      subject[:def].should == 234
    end
  end
end
