

module MessageTemplate
  def self.interpolate(template, variables)
    variables.each do |key, value|
      template = template&.gsub("{{#{key}}}", value.to_s)
    end
    template
  end
end