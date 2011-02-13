class NilClass
  def to_param
    "all"
  end
end

class Symbol
  alias to_param to_s
end

class String
  alias to_param dup
end

class Ohm::Model
  alias to_param id
end

def url(*args)
  "/" + args.map(&:to_param).join("/")
end
