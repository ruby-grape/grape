class EmbeddedExampleWithMany
  def name
    "abc"
  end

  def embedded
    [ EmbeddedExample.new, EmbeddedExample.new ]
  end
end