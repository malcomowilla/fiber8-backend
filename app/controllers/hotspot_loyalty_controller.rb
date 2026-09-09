# app/controllers/hotspot_loyalty_controller.rb
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
  def index
    scope = HotspotLoyaltyPoint.where(account_id: @account.id)
    scope = scope.where('balance >= ?', params[:min_points].to_i) if params[:min_points].present?
    scope = scope.where('phone ILIKE :q OR name ILIKE :q', q: "%#{params[:q]}%") if params[:q].present?

    members = scope.order(balance: :desc)

    render json: {
      total_buyers: HotspotLoyaltyPoint.where(account_id: @account.id).count,
      members_10plus: HotspotLoyaltyPoint.where(account_id: @account.id).where('balance >= 10').count,
      points_held: scope.sum(:balance),
      spend_from_members: scope.sum(:total_spent_amount),
      purchases: scope.sum(:purchase_count),
      members: members.map { |m| summary(m) }
    }
  end

  # GET /api/hotspot_loyalty_customers/:id
  def show
    member = HotspotLoyaltyPoint.find_by(id: params[:id], account_id: @account.id)
    return render json: { error: 'Not found' }, status: :not_found unless member

    activities = member.hotspot_loyalty_activities.order(created_at: :desc).limit(50)

    render json: summary(member).merge(
      activity: activities.map { |a|
        { kind: a.kind, points: a.points, balance_after: a.balance_after,
          amount: a.amount, created_at: a.created_at }
      }
    )
  end

  private

  def summary(m)
    {
      id: m.id,
      phone: m.phone,
      name: m.name,
      balance: m.balance,
      total_spent: m.total_spent_amount,
      purchase_count: m.purchase_count,
      average_buy: m.purchase_count.positive? ? (m.total_spent_amount / m.purchase_count).round(2) : 0,
      last_package: m.last_package,
      last_purchase_at: m.last_purchase_at,
      first_seen_at: m.first_seen_at
    }
  end
end