# src/git/config.cr
module Git
  struct ConfigItem
    getter name  : String
    getter value : String

    def initialize(@name : String, @value : String)
    end

    def ==(other : ConfigItem) : Bool
      @name == other.name && @value == other.value
    end

    def to_s(io : IO) : Nil
      io << @name << '=' << @value
    end
  end
end
