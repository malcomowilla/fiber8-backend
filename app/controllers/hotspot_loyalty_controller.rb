class HotspotLoyaltyController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /api/hotspot_loyalty_customers?min_points=10&q=0712
  #
  # Roster is built from actual completed purchases (HotspotMpesaRevenue +
  # HotspotVoucher), NOT from HotspotLoyaltyPoint — a customer who bought a
  # voucher while the points programme was off (or before it existed) is
  # still a real customer and must show up here, just with balance: 0.
  def index
    base = HotspotMpesaRevenue
             .joins(:hotspot_voucher)
             .where(account_id: @account.id, status: 'Completed')
             .where.not(hotspot_vouchers: { phone: [nil, ''] })

    grouped = base
      .select(
        "hotspot_vouchers.phone AS phone",
        "MAX(hotspot_mpesa_revenues.name) AS name",
        "COUNT(hotspot_mpesa_revenues.id) AS purchase_count",
        "SUM(hotspot_mpesa_revenues.amount) AS total_spent",
        "MAX(hotspot_mpesa_revenues.created_at) AS last_purchase_at",
        "MIN(hotspot_mpesa_revenues.created_at) AS first_seen_at",
        "(ARRAY_AGG(hotspot_vouchers.package ORDER BY hotspot_mpesa_revenues.created_at DESC))[1] AS last_package"
      )
      .group("hotspot_vouchers.phone")

    if params[:q].present?
      grouped = grouped.having(
        "hotspot_vouchers.phone ILIKE :q OR MAX(hotspot_mpesa_revenues.name) ILIKE :q",
        q: "%#{params[:q]}%"
      )
    end

    rows = grouped.to_a

    points_by_phone = HotspotLoyaltyPoint
                         .where(account_id: @account.id, phone: rows.map(&:phone))
                         .index_by(&:phone)

    members = rows.map do |r|
      point = points_by_phone[r.phone]
      {
        id: r.phone,                      # phone doubles as the row id — see #show
        phone: r.phone,
        name: point&.name.presence || r.name,
        balance: point&.balance || 0,
        total_spent: r.total_spent.to_f,
        purchase_count: r.purchase_count.to_i,
        average_buy: r.purchase_count.to_i.positive? ? (r.total_spent.to_f / r.purchase_count.to_i).round(2) : 0,
        last_package: r.last_package,
        last_purchase_at: r.last_purchase_at,
        first_seen_at: r.first_seen_at
      }
    end

    if params[:min_points].present?
      min = params[:min_points].to_i
      members = members.select { |m| m[:balance] >= min }
    end

    members.sort_by! { |m| -m[:balance] }

    render json: {
      total_buyers: rows.size,
      members_10plus: members.count { |m| m[:balance] >= 10 },
      points_held: points_by_phone.values.sum(&:balance),
      spend_from_members: rows.sum { |r| r.total_spent.to_f },
      purchases: rows.sum { |r| r.purchase_count.to_i },
      members: members
    }
  end

  # GET /api/hotspot_loyalty_customers/:id  — :id is the phone number
  def show
    phone = params[:id]

    revenues = HotspotMpesaRevenue
                 .joins(:hotspot_voucher)
                 .where(account_id: @account.id, status: 'Completed', hotspot_vouchers: { phone: phone })
                 .order(created_at: :desc)

    return render json: { error: 'Not found' }, status: :not_found if revenues.none?

    point = HotspotLoyaltyPoint.find_by(account_id: @account.id, phone: phone)
    total_spent = revenues.sum(:amount).to_f
    purchase_count = revenues.count
    last = revenues.first

    activity = point ? point.hotspot_loyalty_activities.order(created_at: :desc).limit(50) : []

    payments = revenues.limit(50).map do |r|
      {
        package: r.hotspot_voucher&.package,
        amount: r.amount,
        created_at: r.created_at,
        status: r.status,
        payment_method: r.payment_method
      }
    end

    render json: {
      id: phone,
      phone: phone,
      name: point&.name.presence || last&.name,
      balance: point&.balance || 0,
      total_spent: total_spent,
      purchase_count: purchase_count,
      average_buy: purchase_count.positive? ? (total_spent / purchase_count).round(2) : 0,
      last_package: last&.hotspot_voucher&.package,
      last_purchase_at: last&.created_at,
      first_seen_at: revenues.minimum(:created_at),
      activity: activity.map { |a|
        { kind: a.kind, points: a.points, balance_after: a.balance_after, amount: a.amount, created_at: a.created_at }
      },
      payments: payments
    }
  end
end