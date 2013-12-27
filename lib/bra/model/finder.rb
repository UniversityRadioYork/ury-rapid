module Bra
  module Model
    # An object that traverses a model tree to find a node given its URL
    class Finder
      # Initialises a Finder.
      #
      # @param url [String] A partial URL that follows this model object's URL
      #   to form the URL of the resource to locate.  Can be nil, in which case
      #   this object is returned.
      def initialize(root, url)
        @root = root
        @url  = url

        reset
      end

      # Finds the model object at a URL, given a model root.
      #
      # @param (see #initialize)
      #
      # @yieldparam (see #run)
      #
      # @return (see #run)
      def self.find(*args, &block)
        new(*args).run(&block)
      end

      # Attempts to find a child resource with the given partial URL
      #
      # If the resource is found, it will be yielded to the attached block;
      # otherwise, an exception will be raised.
      #
      # @yieldparam resource [ModelObject] The resource found.
      # @yieldparam args [Array] The splat from above.
      #
      # @return [Object]  The return value of the block.
      def run
        # We're traversing down the URL by repeatedly splitting it into its
        # head (part before the next /) and tail (part after).  While we still
        # have a tail, then the URL still needs walking down.
        reset
        descend until hit_end_of_url?
        yield @resource
      end

      private

      def descend
        descend_url
        get_next_resource
        fail_if_no_resource
      end

      def get_next_resource
        @resource = @resource.get_child(@next_id)
      end

      def fail_if_no_resource
        missing_resource if @resource.nil?
      end

      def missing_resource
        fail(Bra::Common::Exceptions::MissingResource, @url)
      end

      def hit_end_of_url?
        @tail.nil? || @tail.empty?
      end

      def descend_url
        @head, @tail = @tail.split('/', 2)
        @next_id = head_to_id
      end

      def reset
        @head, @tail = nil, @url.chomp('/')
        @resource = @root
      end

      def head_to_id
        head_to_integer || head_to_symbol
      end

      def head_to_integer
        Integer(@head)
      rescue ArgumentError
        nil
      end

      def head_to_symbol
        @head.to_sym
      end
    end
  end
end
