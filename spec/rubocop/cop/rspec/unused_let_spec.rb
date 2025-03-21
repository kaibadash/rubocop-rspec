# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::UnusedLet do
  it 'flags unused let' do
    expect_offense(<<~RUBY)
      describe Foo do
        let(:foo) { bar }
        ^^^^^^^^^ Unused `let` definition.

        it 'does not use foo' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'ignores let when used in example' do
    expect_no_offenses(<<~RUBY)
      describe Foo do
        let(:foo) { bar }

        it 'uses foo' do
          foo
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'ignores let when used in before hook' do
    expect_no_offenses(<<~RUBY)
      describe Foo do
        let(:foo) { bar }

        before do
          foo
        end

        it 'does something' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'ignores let when used in after hook' do
    expect_no_offenses(<<~RUBY)
      describe Foo do
        let(:foo) { bar }

        after do
          foo
        end

        it 'does something' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'ignores let when used by another let' do
    expect_no_offenses(<<~RUBY)
      describe Foo do
        let(:foo) { bar }
        let(:baz) { foo }

        it 'uses baz' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'complains when let is used and not referenced within nested group' do
    expect_offense(<<~RUBY)
      describe Foo do
        context 'when something special happens' do
          let(:foo) { bar }
          ^^^^^^^^^ Unused `let` definition.

          it 'does not use foo' do
            expect(baz).to eq(qux)
          end
        end
      end
    RUBY
  end

  it 'complains when let is used and not referenced in shared example group' do
    expect_offense(<<~RUBY)
      shared_context 'foo' do
        let(:bar) { baz }
        ^^^^^^^^^ Unused `let` definition.

        it 'does not use bar' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'flags unused helpers defined as strings' do
    expect_offense(<<~RUBY)
      describe Foo do
        let('bar') { baz }
        ^^^^^^^^^^ Unused `let` definition.
      end
    RUBY
  end

  it 'ignores used helpers defined as strings' do
    expect_no_offenses(<<~RUBY)
      describe Foo do
        let('bar') { baz }
        it { expect(bar).to be_near }
      end
    RUBY
  end

  it 'flags blockpass' do
    expect_offense(<<~RUBY)
      shared_context Foo do |&block|
        let(:bar, &block)
        ^^^^^^^^^^^^^^^^^ Unused `let` definition.
      end
    RUBY
  end

  it 'does not complain when there is only one unused let' do
    expect_offense(<<~RUBY)
      describe Foo do
        let(:foo) { bar }
        ^^^^^^^^^ Unused `let` definition.
      end
    RUBY
  end

  it 'autocorrects removing unused let' do
    expect_offense(<<~RUBY)
      describe Foo do
        let(:foo) { bar }
        ^^^^^^^^^ Unused `let` definition.

        it 'does not use foo' do
          expect(baz).to eq(qux)
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      describe Foo do
      #{'  '}

        it 'does not use foo' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end
end
