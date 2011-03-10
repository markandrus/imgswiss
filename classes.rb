#!/usr/bin/env ruby
# classes.rb => Transform(s) Classes

# Transforms; usage:
#   ts = Transforms.new
#   ts.add(assignment)
#   ts.to_proc.call(state)
class Transforms
    def initialize
        @transforms = []
    end
    def add(&transform)
        @transforms << transform
    end
    def to_proc
        lambda { |state| @transforms.inject(state) { |state, fn| fn.call(state) } }
    end
end

# Transform; usage:
# NOTE: Args need to be `push`ed on in order.
class Transform
    def initialize(name, args)
        @transform = $transforms[name]
        @args = args
    end
    def to_proc
        # NOTE: I probably need to be smarter about this--Are the updated
        #       images getting freed (Image.destroy!-ed) on update?
        # lambda { |state| state.update(@transform.call(state, @args.map { |arg| state[arg] } )) }
        lambda { |state| state.update(@transform.call(state, @args)) }
    end
end

