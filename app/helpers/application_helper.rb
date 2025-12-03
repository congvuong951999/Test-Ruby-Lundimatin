# frozen_string_literal: true

module ApplicationHelper
  # Get initials from name (first 2 letters)
  def get_initials(name)
    return '??' if name.blank?
    
    parts = name.split
    if parts.length >= 2
      "#{parts[0][0]}#{parts[1][0]}".upcase
    else
      name[0..1].upcase
    end
  end
end
