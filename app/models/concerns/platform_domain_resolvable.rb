# app/models/concerns/platform_domain_resolvable.rb
module PlatformDomainResolvable
  KNOWN_PLATFORM_DOMAINS = ["aitechs.co.ke", "owitech.co.ke"].freeze
  DEFAULT_PLATFORM_DOMAIN = "aitechs.co.ke"

  # full_domain is the whole host the request came in on, e.g.
  # "twintech.owitech.co.ke" or "fiber8.aitechs.co.ke"
  def self.resolve(full_domain)
    return DEFAULT_PLATFORM_DOMAIN if full_domain.blank?

    base = full_domain.to_s.split(".").last(3).join(".")
    KNOWN_PLATFORM_DOMAINS.include?(base) ? base : DEFAULT_PLATFORM_DOMAIN
  end
end


