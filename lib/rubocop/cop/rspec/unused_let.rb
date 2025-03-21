# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for `let` definitions that are not used.
      #
      # @example
      #   # bad
      #   let(:unused_let) { bar }
      #   it do
      #     expect(baz).to eq(qux)
      #   end
      #
      #   # good(unused_let is removed)
      #   it do
      #     expect(baz).to eq(qux)
      #   end
      class UnusedLet < Base
        MSG = 'Unused `let` definition.'

        # @!method example_or_shared_group_or_including?(node)
        def_node_matcher :example_or_shared_group_or_including?, <<~PATTERN
          (block {
            (send #rspec? {#SharedGroups.all #ExampleGroups.all} ...)
            (send nil? #Includes.all ...)
          } ...)
        PATTERN

        # @!method let_definition(node)
        def_node_matcher :let_definition, <<~PATTERN
          {
            (block $(send nil? :let {(sym $_) (str $_)}) ...)
            $(send nil? :let {(sym $_) (str $_)} block_pass)
          }
        PATTERN

        # @!method method_called?(node)
        def_node_search :method_called?, '(send nil? %)'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_or_shared_group_or_including?(node)

          unused_let(node) do |let|
            add_offense(let) do |corrector|
              corrector.remove(let.parent)
            end
          end
        end

        extend AutoCorrector

        private

        def unused_let(node)
          child_let(node) do |method_send, method_name|
            yield(method_send) unless method_called?(node, method_name.to_sym)
          end
        end

        def child_let(node, &block)
          RuboCop::RSpec::ExampleGroup.new(node).lets.each do |let|
            let_definition(let, &block)
          end
        end
      end
    end
  end
end
