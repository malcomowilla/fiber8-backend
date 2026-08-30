class AccessPoint < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :nas_router, optional: true

  # Known router brands and their default IPs (to warn ISP)
  DEFAULT_IPS = {
    'Huawei'   => ['192.168.100.1', '192.168.1.1'],
    'Tenda'    => ['192.168.0.1', '192.168.1.1'],
    'TP-Link'  => ['192.168.0.1', '192.168.1.1'],
    'D-Link'   => ['192.168.0.1', '192.168.1.1'],
    'Mikrotik' => ['192.168.88.1'],
    'Ubiquiti' => ['192.168.1.20'],
    'ZTE'      => ['192.168.1.1', '192.168.100.1'],
  }.freeze

  SETUP_STEPS = %w[pending ip_assigned binding_created bypassed verified].freeze
  SETUP_STATUS = %w[pending ip_assigned binding_created bypassed verified].freeze

  validates :name, presence: true
  validates :ip, presence: true
  validates :setup_status, inclusion: { in: SETUP_STATUS }

  scope :reachable, -> { where(reachable: true) }
  scope :unreachable, -> { where(reachable: false) }
  scope :pending_setup, -> { where(setup_status: 'pending') }
  scope :fully_setup, -> { where(setup_status: 'verified') }

  # Check if IP is a known default (warn admin)
  def using_default_ip?
    return false if brand.blank?
    defaults = DEFAULT_IPS[brand] || []
    defaults.include?(ip)
  end

  def default_ip_warning
    return nil unless using_default_ip?
    "⚠️ This IP (#{ip}) is a known default for #{brand} routers. Please assign a custom IP from your MikroTik network (e.g. 10.5.50.x)"
  end

  def setup_complete?
    setup_status == 'verified'
  end

  def setup_progress_percent
    index = SETUP_STEPS.index(setup_status) || 0
    ((index + 1).to_f / SETUP_STEPS.length * 100).round
  end

  def status_badge
    reachable? ? 'online' : 'offline'
  end
end
